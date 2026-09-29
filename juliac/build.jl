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

using Pkg, TOML

const HERE = @__DIR__
const OUT = abspath(length(ARGS) >= 1 ? ARGS[1] : joinpath(HERE, "..", "build", "mritools"))

VERSION >= v"1.13.0-" || error("juliac needs Julia 1.13 or newer, this is $VERSION")

juliac = joinpath(DEPOT_PATH[1], "bin", Sys.iswindows() ? "juliac.bat" : "juliac")
if !isfile(juliac)
    @info "installing the juliac app"
    Pkg.Apps.add("JuliaC")
end

# The static build and the PackageCompiler App ship the same library versions
const APP = joinpath(HERE, "..", "App", "Project.toml")
let app = TOML.parsefile(APP)["compat"], static = TOML.parsefile(joinpath(HERE, "Project.toml"))["compat"]
    for (pkg, pin) in static
        pkg == "julia" && continue
        get(app, pkg, nothing) == pin || error("juliac/Project.toml pins $pkg $pin, App/Project.toml $(get(app, pkg, "nothing"))")
    end
end

Pkg.activate(HERE)
Pkg.instantiate()

rm(OUT; force=true, recursive=true)
run(`$juliac --output-exe mritools --trim=safe --experimental --bundle $OUT --project $HERE $(joinpath(HERE, "mritools.jl"))`)

# The bundle holds every runtime library of the Julia installation. mritools loads
# twelve of them, measured with LD_DEBUG=libs; the rest serve Pkg, the REPL and
# BLAS, whose initialisation mritools.jl turns off. Only the measured set is kept,
# and FFTW, which clearswi uses, from the artifacts. On Linux the executable and
# the libraries are then stripped of their debug information: Julia ships the
# libraries unstripped, and that is 34 of their 43 MB.
const RUNTIME_LIBRARIES = ["libjulia", "libjulia-internal", "libstdc++", "libgcc_s", "libunwind",
                           "libz", "libzstd", "libatomic", "libopenlibm", "libpcre2-8", "libgmp", "libmpfr"]
library_name(f) = first(split(f, "."; limit=2)) # libfftw3.so.3, libfftw3.3.dylib
# Windows has no lib directory: the libraries are beside the executable, and all kept.
libroot = joinpath(OUT, "lib")
for (root, _, files) in (isdir(libroot) ? walkdir(libroot) : ()), f in files
    endswith(f, ".dll") && continue
    (occursin(".so", f) || occursin(".dylib", f)) && library_name(f) in RUNTIME_LIBRARIES && continue
    rm(joinpath(root, f))
end
# Of the artifacts only FFTW's is used; the certificates are not. Its libraries are
# libfftw3.so.3, libfftw3.3.dylib or libfftw3-3.dll, and the same with libfftw3f.
artifacts = joinpath(OUT, "share", "julia", "artifacts")
for artifact in (isdir(artifacts) ? readdir(artifacts) : String[])
    dir = joinpath(artifacts, artifact)
    libdir = joinpath(dir, Sys.iswindows() ? "bin" : "lib")
    if isdir(libdir) && any(f -> startswith(f, "libfftw3"), readdir(libdir))
        # the libraries and their licence (FFTW is GPL), not headers or build files
        for f in readdir(dir)
            f in (basename(libdir), "share") || rm(joinpath(dir, f); recursive=true)
        end
        for f in readdir(libdir)
            isdir(joinpath(libdir, f)) && rm(joinpath(libdir, f); recursive=true)
        end
    else
        rm(dir; recursive=true)
    end
end
for f in readdir(joinpath(OUT, "share", "julia"))
    f == "artifacts" || rm(joinpath(OUT, "share", "julia", f); force=true, recursive=true)
end
# Linux only. On macOS the debug information is not linked into the binaries, and
# strip would remove the global symbols Julia looks up in the executable at
# startup ("Image file failed consistency check") and void the signature juliac
# gave it.
if Sys.islinux() && Sys.which("strip") !== nothing
    run(`strip $(joinpath(OUT, "bin", "mritools"))`)
    for dir in (joinpath(OUT, "lib"), artifacts), (root, _, files) in walkdir(dir), f in files
        path = joinpath(root, f)
        occursin(".so", f) && !islink(path) && (chmod(path, 0o755); run(`strip --strip-unneeded $path`))
    end
end

# One name per command: the executable dispatches on the name it is invoked by.
const COMMANDS = ["romeo", "clearswi", "romeo_mask", "mcpc3ds", "makehomogeneous"]
exe = Sys.iswindows() ? "mritools.exe" : "mritools"
for command in COMMANDS
    target = joinpath(OUT, "bin", Sys.iswindows() ? command * ".exe" : command)
    Sys.iswindows() ? cp(joinpath(OUT, "bin", exe), target) : symlink(exe, target)
end

# The same documents and Matlab wrappers as the PackageCompiler bundle
const ROOT = joinpath(HERE, "..")
cp(joinpath(ROOT, "matlab"), joinpath(OUT, "matlab"))
cp(joinpath(ROOT, "documentation", "README.md"), joinpath(OUT, "README.md"))
cp(joinpath(ROOT, "LICENSE"), joinpath(OUT, "LICENSE"))
Sys.isapple() && cp(joinpath(ROOT, "documentation", "README_macOS.txt"), joinpath(OUT, "README_macOS.txt"))

size_mb(dir) = round(sum(filesize(joinpath(r, f)) for (r, _, fs) in walkdir(dir) for f in fs if !islink(joinpath(r, f))) / 1e6; digits=1)
println("mritools built in $OUT: $(size_mb(OUT)) MB")
