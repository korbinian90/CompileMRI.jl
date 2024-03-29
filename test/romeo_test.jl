using Pkg, ROMEO, ArgParse
Pkg.test("ROMEO")
@show "test finished"
phasefile = abspath(joinpath(@__DIR__, "data", "small", "Phase.nii"))
magfile = abspath(joinpath(@__DIR__, "data", "small", "Mag.nii"))

function test_romeo(args)
    file = tempname()
    args = [args..., "-o", file]
    unwrapping_main(args)
end

args = ["-p", phasefile, "-B", "-t", "1:3"]
test_romeo(args)

args = ["-p", phasefile, "-m", magfile, "-t", "1:3"]
test_romeo(args)
