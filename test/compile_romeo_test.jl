@testset "ROMEO compile tests" begin

path = raw"C:\builddir_temp"#tempname()
compile_romeo(path)

@test !isempty(readdir(path))

@show pwd()
phasefile = joinpath(pwd(), "data", "small", "Phase.nii")
magfile = joinpath(pwd(), "data", "small", "Mag.nii")

function test_romeo(args)
    file = tempname()
    args = [args..., "-o", file]
    cmd = `$path/romeo.exe $args`
    run(cmd)
end

args = [phasefile, "-m", magfile]
test_romeo(args)
end
