function compile_romeo(path;
        app_name="romeo",
        filter_stdlibs=true,
        precompile_execution_file=abspath(joinpath(@__DIR__, "..", "test", "romeo_test.jl")),
        clean=true,
        kw...)
    romeopath = pathof("RomeoApp")
    if !isdir(romeopath)
        download_pkg("RomeoApp")
    end
    create_app(romeopath, path; app_name, filter_stdlibs, precompile_execution_file, kw...)
    test_romeo(path, app_name)
    if clean
        clean_app(path, app_name) # remove unneccesary artifacts dir (600MB)
    end
    copy_matlab(path)
    printstyled("Success! Romeo compiled and tested!\n"; color=:green)
    @warn("Relocatability has to be tested manually!")
end

function test_romeo(path, app_name)
    file = tempname()
    phasefile = abspath(joinpath(@__DIR__, "..", "test", "data", "small", "Phase.nii"))
    args = [phasefile, "-o", file, "-t", "1:3", "-k", "nomask"]
    name = app_name * (Sys.iswindows() ? ".exe" : "")
    romeofile = joinpath(path, "bin", name)
    @assert isfile(romeofile)
    cmd = `$romeofile $args`
    @assert success(run(cmd))
end

function update_romeo()
    try 
        rm(pathof("RomeoApp"); force=true, recursive=true)
    catch 
        @warn "Couldn't remove the old RomeoApp folder! ($(pathof("RomeoApp"))) Maybe it is opened in another App"
    end
    download_pkg("RomeoApp")
end
