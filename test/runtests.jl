using CompileMRI
using Test

if !isdir(romeopath)
    download_pkg("RomeoApp")
end

@testset "CompileMRI.jl" begin
    include("romeo_test.jl")
    include("compile_romeo_test.jl")
end
