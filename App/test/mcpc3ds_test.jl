using Test
using App.Mcpc3dsApp

@testset "MCPC3DS function tests" begin

niread = Mcpc3dsApp.niread
savenii = Mcpc3dsApp.savenii

p = joinpath("..", "..", "test", "data", "small")
phasefile_me = joinpath(p, "Phase.nii")
magfile_me = joinpath(p, "Mag.nii")
tmpdir = mktempdir()

phasefile_me_5D = joinpath(tmpdir, "phase_multi_channel.nii")
magfile_5D = joinpath(tmpdir, "mag_multi_channel.nii")
savenii(repeat(niread(phasefile_me),1,1,1,1,2), phasefile_me_5D)
savenii(repeat(niread(magfile_me),1,1,1,1,2), magfile_5D)

function test_mcpc3ds(args)
    folder = tempname()
    args = [args..., "-o", folder]
    try
        println(args)
        msg = mcpc3ds_main(args)
        @test msg == 0
        @test isfile(joinpath(folder, "combined_phase.nii"))
        @test isfile(joinpath(folder, "combined_mag.nii"))
    catch e
        println(args)
        println(sprint(showerror, e, catch_backtrace()))
        @test "test failed" == "with error" # signal a failed test
    end
end

configurations_me(phasefile_me, magfile_me) = configurations_me(["-p", phasefile_me, "-m", magfile_me])
configurations_me(pm) = [
    [pm..., "-t", "[2,4,6]"],
    [pm..., "-t", "2:2:6"],
    [pm..., "-t", "[2.1,4.2,6.3]"],
    [pm..., "-b", "-t", "[2,4,6]"],
    [pm..., "-b", "-t", "[2" ,"4", "6]"], # when written like [2 4 6] in command line
    [pm..., "-N", "-t", "[2,4,6]"],
    [pm..., "--write-phase-offsets", "-t", "[2,4,6]"],
    [pm..., "--no-phase-rescale", "-t", "[2,4,6]"],
    [pm..., "--writesteps", tmpdir, "-t", "[2,4,6]"],
    [pm..., "--verbose", "-t", "[2,4,6]"],
    [pm..., "-t", "[2,4,6]", "-s", "[0,0,0]"]
]

for args in configurations_me(phasefile_me, magfile_me)
    test_mcpc3ds(args)
end
for args in configurations_me(phasefile_me_5D, magfile_5D)
    test_mcpc3ds(args)
end


## Test error and warning messages
m = "No echo times are given. Please specify the echo times using the -t option."
@test_throws ErrorException(m) mcpc3ds_main(["-p", phasefile_me, "-m", magfile_me, "-o", tmpdir, "-v"])
m = "Phase offset determination requires all echo times!"
@test_throws ErrorException(m) mcpc3ds_main(["-p", phasefile_me, "-m", magfile_me, "-o", tmpdir, "-v", "-t", "5"])
@test_throws ErrorException(m) mcpc3ds_main(["-p", phasefile_me, "-m", magfile_me, "-o", tmpdir, "-v", "-t", "[5]"])

@test_logs mcpc3ds_main(["-p", phasefile_me, "-o", tmpdir, "-m", magfile_me, "-t", "[2,4,6]"]) # test that no warning appears
@test_logs mcpc3ds_main(["-p", phasefile_me_5D, "-o", tmpdir, "-m", magfile_5D, "-t", "[2,4,6]"]) # test that no warning appears

## print version to verify
println()
mcpc3ds_main(["--version"])

end