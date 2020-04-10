@testset "ROMEO compile tests" begin

path = tempname()
app_name = "romeo"
compile_romeo(path; app_name=app_name, filter_stdlibs=true, audit=true, precompile_execution_file=abspath("romeo_test.jl"))

@test !isempty(readdir(path))

phasefile = joinpath(pwd(), "data", "small", "Phase.nii")
magfile = joinpath(pwd(), "data", "small", "Mag.nii")

function test_romeo(args)
    file = tempname()
    args = [args..., "-o", file]
    name = app_name * (Sys.iswindows() ? ".exe" : "")
    romeofile = joinpath(path, "bin", name)
    @test isfile(romeofile)
    cmd = `$romeofile $args`
    @test success(run(cmd))
end

args = [phasefile, "-m", magfile]
test_romeo(args)
end
