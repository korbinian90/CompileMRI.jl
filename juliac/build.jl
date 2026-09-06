# Builds mritools as a statically compiled program with juliac.
#
#     julia juliac/build.jl [output directory]
#
# Needs Julia 1.13 or newer and the juliac app (`pkg> app add JuliaC`, which
# puts `juliac` into ~/.julia/bin). The result is a directory with bin/mritools,
# one link (or copy, on Windows) per command beside it, and the runtime
# libraries it loads, and nothing else: no sysimage, no LLVM, no compiler. Only the code that is reachable from the entry point is
# compiled, so a library that needs dynamic dispatch would fail the build
# rather than the program.

using Pkg

const HERE = @__DIR__
const OUT = abspath(length(ARGS) >= 1 ? ARGS[1] : joinpath(HERE, "..", "build", "mritools"))

VERSION >= v"1.13.0-" || error("juliac needs Julia 1.13 or newer, this is $VERSION")

juliac = joinpath(DEPOT_PATH[1], "bin", Sys.iswindows() ? "juliac.bat" : "juliac")
if !isfile(juliac)
    @info "installing the juliac app"
    Pkg.Apps.add("JuliaC")
end

Pkg.activate(HERE)
Pkg.instantiate()

rm(OUT; force=true, recursive=true)
run(`$juliac --output-exe mritools --trim=safe --experimental --bundle $OUT --project $HERE $(joinpath(HERE, "mritools.jl"))`)

# The bundle holds every runtime library of the Julia installation. mritools loads
# twelve of them, measured with LD_DEBUG=libs; the rest serve Pkg, the REPL,
# BLAS and FFTW, whose initialisation mritools.jl turns off. Only the measured set
# is kept. The executable and the libraries are then stripped of their debug
# information: Julia ships the libraries unstripped, and that is 34 of their
# 43 MB.
const RUNTIME_LIBRARIES = ["libjulia", "libjulia-internal", "libstdc++", "libgcc_s", "libunwind",
                           "libz", "libzstd", "libatomic", "libopenlibm", "libpcre2-8", "libgmp", "libmpfr"]
library_name(f) = first(split(f, ".so"; limit=2))
for (root, _, files) in walkdir(joinpath(OUT, "lib")), f in files
    endswith(f, ".dll") && continue # Windows keeps all of them beside the executable
    (occursin(".so", f) || occursin(".dylib", f)) && library_name(f) in RUNTIME_LIBRARIES && continue
    rm(joinpath(root, f))
end
rm(joinpath(OUT, "share"); force=true, recursive=true) # artifacts and certificates, unused
if !Sys.iswindows() && Sys.which("strip") !== nothing
    run(`strip $(joinpath(OUT, "bin", "mritools"))`)
    if Sys.islinux()
        for (root, _, files) in walkdir(joinpath(OUT, "lib")), f in files
            path = joinpath(root, f)
            occursin(".so", f) && !islink(path) && run(`strip --strip-unneeded $path`)
        end
    end
end

# One name per command: the executable dispatches on the name it is invoked by.
const COMMANDS = ["romeo"]
exe = Sys.iswindows() ? "mritools.exe" : "mritools"
for command in COMMANDS
    target = joinpath(OUT, "bin", Sys.iswindows() ? command * ".exe" : command)
    Sys.iswindows() ? cp(joinpath(OUT, "bin", exe), target) : symlink(exe, target)
end

size_mb(dir) = round(sum(filesize(joinpath(r, f)) for (r, _, fs) in walkdir(dir) for f in fs if !islink(joinpath(r, f))) / 1e6; digits=1)
println("mritools built in $OUT: $(size_mb(OUT)) MB")
