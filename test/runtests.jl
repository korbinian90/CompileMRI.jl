using CompileMRI
using Test
using Pkg

try
    using RomeoApp
catch
    if !isdir(CompileMRI.pathof("RomeoApp"))
        CompileMRI.download_pkg("RomeoApp")
    else
        Pkg.develop("RomeoApp")
    end
    using RomeoApp
end

@testset "CompileMRI.jl" begin
    include("romeo_test.jl")
    include("compile_romeo_test.jl")
end
