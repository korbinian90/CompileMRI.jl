using CompileMRI
using Test
using Aqua
using Pkg

@testset "Functionality Test" begin
    Pkg.activate(joinpath(dirname(@__DIR__), "App"))
    Pkg.test()
end

@testset "Compile Test" begin
    # include("compile_test.jl")
end

@testset "Aqua" begin
    Aqua.test_all(CompileMRI)
end
