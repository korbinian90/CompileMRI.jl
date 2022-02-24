using CompileMRI
using Test
using Pkg
#=
@testset "MCPC3DS" begin
    include("mcpc3ds_test.jl")
end

@testset "CLEARSWI" begin
    include("clearswi_test.jl")
end

@testset "ROMEO" begin
    include("romeo_test.jl")
end
=#
@testset "Compile Test" begin
    include("compile_test.jl")
end
