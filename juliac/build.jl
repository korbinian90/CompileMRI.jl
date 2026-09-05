# Builds romeo as a statically compiled program with juliac.
#
#     julia juliac/build.jl [output directory]
#
# Needs Julia 1.13 or newer and the juliac app (`pkg> app add JuliaC`, which
# puts `juliac` into ~/.julia/bin). The result is a directory with bin/romeo
# and the runtime libraries it loads, and nothing else: no sysimage, no LLVM,
# no compiler. Only the code that is reachable from the entry point is
# compiled, so a library that needs dynamic dispatch would fail the build
# rather than the program.

using Pkg

const HERE = @__DIR__
const OUT = abspath(length(ARGS) >= 1 ? ARGS[1] : joinpath(HERE, "..", "build", "romeo"))

VERSION >= v"1.13.0-" || error("juliac needs Julia 1.13 or newer, this is $VERSION")

juliac = joinpath(DEPOT_PATH[1], "bin", Sys.iswindows() ? "juliac.bat" : "juliac")
if !isfile(juliac)
    @info "installing the juliac app"
    Pkg.Apps.add("JuliaC")
end

Pkg.activate(HERE)
Pkg.instantiate()

rm(OUT; force=true, recursive=true)
run(`$juliac --output-exe romeo --trim=safe --experimental --bundle $OUT --project $HERE $(joinpath(HERE, "romeo.jl"))`)

# The bundle holds every runtime library of the Julia installation. romeo loads
# eleven of them, measured with LD_DEBUG=libs; the rest serve Pkg, the REPL,
# BLAS and FFTW, whose initialisation romeo.jl turns off. Only the measured set
# is kept, and the executable is stripped of its debug information, which is
# 60% of it.
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
    run(`strip $(joinpath(OUT, "bin", "romeo"))`)
end

size_mb(dir) = round(sum(filesize(joinpath(r, f)) for (r, _, fs) in walkdir(dir) for f in fs if !islink(joinpath(r, f))) / 1e6; digits=1)
println("romeo built in $OUT: $(size_mb(OUT)) MB")
