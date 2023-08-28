using CompileMRI
using Test
using Pkg

@testset "Functionality Test" begin
    Pkg.activate(joinpath(dirname(@__DIR__), "App"))
    Pkg.test()
end

@testset "Compile Test" begin
    # include("compile_test.jl")
end
