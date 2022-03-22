using Pkg
include("../App/src/App.jl")
using .App.Mcpc3dsApp
Pkg.test("Mcpc3dsApp")
@show "test finished"

phasefile = abspath(joinpath(@__DIR__, "data", "small", "Phase.nii"))
magfile = abspath(joinpath(@__DIR__, "data", "small", "Mag.nii"))

function test_mcpc3ds(args)
    file = tempname()
    args = [args..., "-o", file]
    mcpc3ds_main(args)
end

args = ["-p", phasefile, "-m", magfile, "-t", "1:3"]
test_mcpc3ds(args)

args = ["-p", phasefile, "-m", magfile, "-t", "1:3", "-N"]
test_mcpc3ds(args)

args = ["-p", phasefile, "-m", magfile, "-t", "1:3", "--write-phase-offsets"]
test_mcpc3ds(args)
