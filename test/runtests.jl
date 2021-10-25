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

@testset "Compile ROMEO" begin
    include("romeo_test.jl")
    include("compile_romeo_test.jl")
end

try
    using ClearswiApp
catch
    if !isdir(CompileMRI.pathof("ClearswiApp"))
        CompileMRI.download_pkg("ClearswiApp")
    else
        Pkg.develop("ClearswiApp")
    end
    using ClearswiApp
end

@testset "Compile CLEARSWI" begin
    include("clearswi_test.jl")
    include("compile_clearswi_test.jl")
end
