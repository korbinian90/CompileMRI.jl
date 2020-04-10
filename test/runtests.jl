using CompileMRI
using RomeoApp
using Test

@testset "CompileMRI.jl" begin
    include("romeo_test.jl")
    include("compile_romeo_test.jl")
end
