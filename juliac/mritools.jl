# Entry point for the statically compiled mritools, built with juliac (see
# build.jl). juliac compiles one entry point per executable, so all commands
# share this one and it dispatches on the name it was invoked by (bin/romeo is
# a link to bin/mritools) or, failing that, on the first argument
# (`mritools romeo ...`). One executable also means the code common to the
# commands, Base and the NIfTI I/O above all, is compiled once instead of once
# per command.
using MriResearchTools, ROMEO, CLEARSWI

# No command here calls BLAS, SuiteSparse or the big number libraries. Their
# packages load 60 MB of shared libraries when they initialise, so their
# initialisation is turned off for this program, as juliac does for Pkg. FFTW
# stays: clearswi unwraps with its cosine transform, and its libraries are 6 MB.
@eval ROMEO.Statistics.LinearAlgebra __init__() = nothing
@eval Base.GMP __init__() = nothing
@eval Base.MPFR __init__() = nothing
for (uuid, name) in (("4536629a-c528-5b80-bd46-f80d51c5b363", "OpenBLAS_jll"),
                     ("8e850b90-86db-534c-a0d3-1478176c7d93", "libblastrampoline_jll"),
                     ("e66e0078-7015-5450-92f7-15fbd957f2ae", "CompilerSupportLibraries_jll"),
                     ("bea87d4a-7f5b-5778-9afe-8cc45184846c", "SuiteSparse_jll"),
                     ("781609d7-10c4-51f6-84f2-b8444358ff6d", "GMP_jll"),
                     ("3a97d323-0669-5f0c-9066-3539efd106a3", "MPFR_jll"))
    m = Base.maybe_root_module(Base.PkgId(Base.UUID(uuid), name))
    m === nothing || @eval m __init__() = nothing
end

# FFTW.jl frees the plans that were finalized while it held its lock by calling
# a method on the abstract plan type, which a compiled program cannot follow.
# Those plans are left to the end of the process instead: a command makes a few
# dozen, and a plan holds only FFTW's tables, not the data.
@eval MriResearchTools.FFTW destroy_deferred() = nothing

# FFTW.jl opens its libraries on first use with a method that looks the library
# up by name and runs a callback stored in an untyped field. The runtime calls it
# when a ccall first needs the library, so nothing in the program calls it and a
# trimmed build leaves it out. Here it is with both spelled out, the library for
# each of the two and FFTW's own callback, and kept as an entry point.
@eval MriResearchTools.FFTW function dlopen(lib::FakeLazyLibrary)
    h = @atomic :monotonic lib.h
    h != C_NULL && return h
    @lock fftwlock begin
        h = @atomic :monotonic lib.h
        h != C_NULL && return h
        h = dlopen(lib.reallibrary === :libfftw3_no_init ? libfftw3_no_init : libfftw3f_no_init)
        fftw_init_check()
        @atomic :release lib.h = h
    end
    return h
end
Base.Experimental.entrypoint(MriResearchTools.FFTW.dlopen, (MriResearchTools.FFTW.FakeLazyLibrary,))

# The callback through which FFTW runs its threads on Julia's, without @sync,
# which collects the tasks untyped: the same tasks, waited for one by one.
@eval MriResearchTools.FFTW function spawnloop(f::Ptr{Cvoid}, fdata::Ptr{Cvoid}, elsize::Csize_t, num::Cint, callback_data::Ptr{Cvoid})
    tasks = Task[Threads.@spawn ccall(f, Ptr{Cvoid}, (Ptr{Cvoid},), fdata + elsize*i) for i = 0:num-1]
    foreach(wait, tasks)
end

# TGV QSM does not compile statically yet and is not part of this program, so
# the QSM step of clearswi is replaced by the error it would end in.
@eval CLEARSWI qsm_contrast(data, options, save) = error("clearswi --qsm is not available in this build: TGV QSM is not compiled in")

# App/Project.toml is the single source of truth for the mritools version, as
# for the PackageCompiler build. Read at compile time: the program has no
# Project.toml beside it when it runs.
const version = let
    toml = joinpath(@__DIR__, "..", "App", "Project.toml")
    m = match(r"^version\s*=\s*\"([^\"]+)\""m, read(toml, String))
    m === nothing && error("no version field in $toml")
    String(m.captures[1])
end

# The commands kept in this repository, shared with the PackageCompiler App
include(joinpath(@__DIR__, "..", "App", "src", "Common.jl"))
include(joinpath(@__DIR__, "..", "App", "src", "Mcpc3ds.jl"))
include(joinpath(@__DIR__, "..", "App", "src", "HomogeneityCorrection.jl"))
include(joinpath(@__DIR__, "..", "App", "src", "ROMEO_mask.jl"))

const COMMANDS = ("romeo", "clearswi", "romeo_mask", "mcpc3ds", "makehomogeneous")

function run_command(name::String, args::Vector{String})::Cint
    name == "romeo" && return unwrapping_main(args; version)
    if name == "clearswi"
        # Said before anything runs; see qsm_contrast above
        if "--qsm" in args
            print(Core.stderr, "clearswi: --qsm is not available in this build: TGV QSM is not compiled in. Use the PackageCompiler bundle for it.\n")
            return 2
        end
        return clearswi_main(args; version)
    end
    name == "romeo_mask" && return RomeoMasking.romeo_mask_main(args; version)
    name == "mcpc3ds" && return Mcpc3dsApp.mcpc3ds_main(args; version)
    name == "makehomogeneous" && return HomogeneityCorrection.makehomogeneous_main(args; version)
    return usage("unknown command \"" * name * "\"")
end

function usage(message::String)::Cint
    print(Core.stderr, "mritools ", version, message == "" ? "" : ": " * message, "\n",
          "usage: mritools <command> [arguments], or the command by its own name\n",
          "commands: ", join(COMMANDS, " "), "\n")
    return message == "" ? 0 : 2
end

# The executable's own file name without directory or .exe, written out so
# that nothing here depends on the path functions compiling statically.
function invoked_as()
    path = Base.PROGRAM_FILE
    start = 1
    for (i, c) in pairs(path)
        (c == '/' || c == '\\') && (start = nextind(path, i))
    end
    name = path[start:end]
    return endswith(name, ".exe") ? name[1:end-4] : name
end

# Base.display_error cannot be compiled statically, so the common exceptions are
# printed by hand, in the catch block itself: the exception has no static type,
# so it cannot be passed to a function.
function (@main)(args::Vector{String})::Cint
    try
        name = invoked_as()
        name in COMMANDS && return run_command(name, args)
        isempty(args) && return usage("")
        args[1] == "--version" && (print(Core.stdout, version, "\n"); return 0)
        args[1] == "--help" && return usage("")
        return run_command(args[1], args[2:end])
    catch e
        msg = if e isa ErrorException || e isa ArgumentError || e isa DimensionMismatch
            m = e.msg
            m isa String ? m : "error"
        elseif e isa SystemError
            e.prefix * ": " * Libc.strerror(e.errnum)
        elseif e isa MethodError
            # the function, which is enough to find the call in a bug report
            "unexpected MethodError in " * lstrip(string(nameof(typeof(e.f))), '#')
        else
            "unexpected " * string(nameof(typeof(e)))
        end
        print(Core.stderr, "ERROR: ", msg, "\n")
        return 1
    end
end
