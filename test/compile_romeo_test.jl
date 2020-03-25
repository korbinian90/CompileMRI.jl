@testset "ROMEO compile tests" begin

path = tempname()
compile_romeo(path)

@test !isempty(readdir(path))

phasefile = joinpath(pwd(), "data", "small", "Phase.nii")
magfile = joinpath(pwd(), "data", "small", "Mag.nii")

function test_romeo(args)
    file = tempname()
    args = [args..., "-o", file]
    name = "RomeoApp" * (Sys.iswindows() ? ".exe" : "")
    romeofile = joinpath(path, "bin", name)
    @test isfile(romeofile)
    cmd = `$romeofile $args`
    @test success(run(cmd))
end

args = [phasefile, "-m", magfile]
test_romeo(args)
end
