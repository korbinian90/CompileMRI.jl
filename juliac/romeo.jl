# Entry point for the statically compiled romeo, built with juliac (see build.jl).
using MriResearchTools, ROMEO

# romeo never calls BLAS, FFTW, SuiteSparse or the big number libraries. Their
# packages load 65 MB of shared libraries when they initialise, so their
# initialisation is turned off for this program, as juliac does for Pkg.
@eval ROMEO.Statistics.LinearAlgebra __init__() = nothing
@eval MriResearchTools.FFTW __init__() = nothing
@eval Base.GMP __init__() = nothing
@eval Base.MPFR __init__() = nothing
for (uuid, name) in (("4536629a-c528-5b80-bd46-f80d51c5b363", "OpenBLAS_jll"),
                     ("8e850b90-86db-534c-a0d3-1478176c7d93", "libblastrampoline_jll"),
                     ("e66e0078-7015-5450-92f7-15fbd957f2ae", "CompilerSupportLibraries_jll"),
                     ("f5851436-0d7a-5f13-b9de-f02708fd171a", "FFTW_jll"),
                     ("bea87d4a-7f5b-5778-9afe-8cc45184846c", "SuiteSparse_jll"),
                     ("781609d7-10c4-51f6-84f2-b8444358ff6d", "GMP_jll"),
                     ("3a97d323-0669-5f0c-9066-3539efd106a3", "MPFR_jll"))
    m = Base.maybe_root_module(Base.PkgId(Base.UUID(uuid), name))
    m === nothing || @eval m __init__() = nothing
end

# App/Project.toml is the single source of truth for the mritools version, as
# for the PackageCompiler build. Read at compile time: the program has no
# Project.toml beside it when it runs.
const version = let
    toml = joinpath(@__DIR__, "..", "App", "Project.toml")
    m = match(r"^version\s*=\s*\"([^\"]+)\""m, read(toml, String))
    m === nothing && error("no version field in $toml")
    String(m.captures[1])
end

# Base.display_error cannot be compiled statically, so the common exceptions are
# printed by hand, in the catch block itself: the exception has no static type,
# so it cannot be passed to a function.
function (@main)(args::Vector{String})::Cint
    try
        return unwrapping_main(args; version)
    catch e
        msg = if e isa ErrorException || e isa ArgumentError || e isa DimensionMismatch
            m = e.msg
            m isa String ? m : "error"
        elseif e isa SystemError
            e.prefix * ": " * Libc.strerror(e.errnum)
        else
            "unexpected " * string(nameof(typeof(e)))
        end
        print(Core.stderr, "ERROR: ", msg, "\n")
        return 1
    end
end
