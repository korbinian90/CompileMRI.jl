@testset "ROMEO function tests" begin

phasefile = joinpath("data", "small", "Phase.nii")
magfile = joinpath("data", "small", "Mag.nii")

function test_romeo(args)
    file = tempname()
    args = [args..., "-o", file]
    RomeoApp.unwrapping_main(args)
end

args = [phasefile, "-B"]
test_romeo(args)

args = [phasefile, "-m", magfile]
test_romeo(args)

end
