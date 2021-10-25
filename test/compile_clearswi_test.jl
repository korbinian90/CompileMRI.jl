@testset "CLEARSWI compile tests" begin

path = tempname()
compile_clearswi(path; audit=true)

@test !isempty(readdir(path))

phasefile = joinpath(pwd(), "data", "small", "Phase.nii")
magfile = joinpath(pwd(), "data", "small", "Mag.nii")

function test_clearswi(args)
    file = tempname()
    args = [args..., "-o", file]
    name = "clearswi" * (Sys.iswindows() ? ".exe" : "")
    clearswifile = joinpath(path, "bin", name)
    @test isfile(clearswifile)
    cmd = `$clearswifile $args`
    @test success(run(cmd))
end

args = ["-p", phasefile, "-m", magfile]
test_clearswi(args)
end
