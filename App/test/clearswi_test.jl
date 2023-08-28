using CLEARSWI, ArgParse
import Pkg
Pkg.test("CLEARSWI")

p = joinpath("..", "..", "test", "data", "small")
phasefile = joinpath(p, "Phase.nii")
magfile = joinpath(p, "Mag.nii") 

function test_clearswi(args)
    file = tempname()
    args = [args..., "-o", file]
    clearswi_main(args)
end

args = ["-p", phasefile, "-m", magfile, "-t", "1:3"]
test_clearswi(args)