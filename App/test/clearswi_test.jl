using CLEARSWI, ArgParse
import Pkg
Pkg.test("CLEARSWI")
@show "test finished"
phasefile = abspath(joinpath(@__DIR__, "data", "small", "Phase.nii"))
magfile = abspath(joinpath(@__DIR__, "data", "small", "Mag.nii"))

function test_clearswi(args)
    file = tempname()
    args = [args..., "-o", file]
    clearswi_main(args)
end

args = ["-p", phasefile, "-m", magfile, "-t", "1:3"]
test_clearswi(args)
@test false