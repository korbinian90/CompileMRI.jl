function compile_romeo(path; app_name, kw...)
    romeopath = joinpath(pathof(RomeoApp), "..", "..")
    create_app(romeopath, path; app_name=app_name, kw...)
    test_romeo(path, app_name)
end

function test_romeo(path, app_name)
    file = tempname()
    phasefile = abspath(joinpath(@__DIR__, "..", "test", "data", "small", "Phase.nii"))
    args = [phasefile, "-o", file]
    name = app_name * (Sys.iswindows() ? ".exe" : "")
    romeofile = joinpath(path, "bin", name)
    @assert isfile(romeofile)
    cmd = `$romeofile $args`
    @assert success(run(cmd))
end
