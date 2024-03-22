using Pkg
Pkg.activate(joinpath(@__DIR__))
cd(joinpath(@__DIR__))
include("../App/src/App.jl")
using .App.HomogeneityCorrection

magfile = abspath(joinpath(@__DIR__, "data", "small", "Mag.nii"))

function test_makehomogenous(args)
    file = tempname()
    args = [args..., "-o", file]
    makehomogeneous_main(args)
end

args = ["-m", magfile, "-s", "3"]
test_makehomogenous(args)

args = ["-m", magfile, "-s", "3.5"]
test_makehomogenous(args)

args = ["-m", magfile, "-n", "4"]
test_makehomogenous(args)

args = ["-m", magfile, "-d", "Float64"]
test_makehomogenous(args)

args = ["-m", magfile, "-d", "Int32"]
test_makehomogenous(args)
