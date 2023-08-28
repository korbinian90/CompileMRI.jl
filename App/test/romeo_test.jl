using ROMEO, ArgParse
import Pkg
Pkg.test("ROMEO")

p = joinpath("..", "..", "test", "data", "small")
phasefile = joinpath(p, "Phase.nii")
magfile = joinpath(p, "Mag.nii")

function test_romeo(args)
    file = tempname()
    args = [args..., "-o", file]
    unwrapping_main(args)
end

args = [phasefile, "-B", "-t", "1:3"]
test_romeo(args)

args = [phasefile, "-m", magfile, "-t", "1:3"]
test_romeo(args)
