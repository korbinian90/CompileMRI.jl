function compile_clearswi(path;
        app_name="clearswi",
        filter_stdlibs=true,
        precompile_execution_file=abspath(joinpath(@__DIR__, "..", "test", "clearswi_test.jl")),
        clean=true,
        kw...)
    clearswiapppath = pathof("ClearswiApp")
    if !isdir(clearswiapppath)
        if !isdir(pathof("CLEARSWI"))
            download_pkg("CLEARSWI")
        end
        download_pkg("ClearswiApp")
    end
    create_app(clearswiapppath, path; app_name, filter_stdlibs, precompile_execution_file, kw...)
    test_clearswi(path, app_name)
    if clean
        clean_app(path, app_name) # remove unneccesary artifacts dir (600MB)
    end
    copy_matlab(path)
    printstyled("Success! CLEARSWI compiled and tested!\n"; color=:green)
    @warn("Relocatability has to be tested manually!")
end

function test_clearswi(path, app_name)
    file = tempname()
    phasefile = abspath(joinpath(@__DIR__, "..", "test", "data", "small", "Phase.nii"))
    magfile = abspath(joinpath(@__DIR__, "..", "test", "data", "small", "Mag.nii"))
    args = ["-p", phasefile, "-m", magfile, "-o", file, "-t", "1:3"]
    name = app_name * (Sys.iswindows() ? ".exe" : "")
    clearswifile = joinpath(path, "bin", name)
    @assert isfile(clearswifile)
    cmd = `$clearswifile $args`
    @assert success(run(cmd))
end

function update_clearswi()
    try 
        rm(pathof("ClearswiApp"); force=true, recursive=true)
    catch 
        @warn "Couldn't remove the old ClearswiApp folder! ($(pathof("ClearswiApp"))) Maybe it is opened in another App"
    end
    download_pkg("ClearswiApp")
end
