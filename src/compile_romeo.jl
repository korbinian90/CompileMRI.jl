function compile_romeo(path;
        app_name="romeo",
        filter_stdlibs=false,
        precompile_execution_file=abspath(joinpath(@__DIR__, "..", "test", "romeo_test.jl")),
        clean=true,
        kw...)
    romeopath = pathof("RomeoApp")
    if !isdir(romeopath)
        download_pkg("RomeoApp")
    end
    create_app(romeopath, path; app_name=app_name, filter_stdlibs=filter_stdlibs, precompile_execution_file=precompile_execution_file, kw...)
    test_romeo(path, app_name)
    if clean
        clean_app(path, app_name) # remove unneccesary artifacts dir (600MB)
    end
    copy_matlab(path)
    println("Success! Romeo compiled and tested!")
end

pathof(app) = normpath(homedir(), ".julia/dev", app)

function clean_app(path, app_name)
    # move artifacts dir
    # test if artifacts can be downloaded
    # if not, move back
    # remove mkl artifact
    # test again
    artifact_path = joinpath(path, "artifacts")
    artifact_tmp_path = joinpath(path, "artifacts_tmp")
    if isdir(artifact_path)
        mv(artifact_path, artifact_tmp_path)
    else
        println("No artifacts in $path")
    end
    
    try
        test_romeo(path, app_name) # required artifacts should be downloaded (<10MB)
        rm(artifact_tmp_path; recursive=true) # only removed if test was successfull
    catch
        println("Artifacts could not be downloaded automatically")
        rm(artifact_path; recursive=true, force=true) # delete partly downloaded artifacts, does not complain if not existing
        mv(artifact_tmp_path, artifact_path)
        println("Removing large and unneccessary mkl artifact")
        mkl_path = findartifactpath(artifact_path, "mkl")
        if !isnothing(mkl_path)
            rm(mkl_path; recursive=true)
        end
    end

    try
        test_romeo(path, app_name)
    catch
        @warn("Artifact cleaning failed! Please recompile romeo with the option `clean=false`. The artifacts folder will be very large but some of them might not needed and can be manually removed.")
    end
end

function findartifactpath(pth, name)
    for d in readdir(pth; join=true)
        if any(occursin.(lowercase(name), lowercase.(readdir(joinpath(d, "logs")))))
            return d
        end
    end
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

function download_pkg(pkg)
    Pkg.develop(PackageSpec(path="https://github.com/korbinian90/$pkg.jl"))
    Pkg.instantiate()
end

function update_romeo()
    try 
        rm(pathof("RomeoApp"); force=true, recursive=true)
    catch 
        @warn "Couldn't remove the old RomeoApp folder! ($(pathof("RomeoApp"))) Maybe it is opened in another App"
    end
    download_pkg("RomeoApp")
end

function copy_matlab(path)
    cp(joinpath(dirname(@__DIR__), "matlab"), joinpath(path, "matlab"))
end
