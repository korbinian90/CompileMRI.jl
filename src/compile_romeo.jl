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
        test_romeo(path, app_name)
        rm(artifact_tmp_path; recursive=true) # only removed if test was successfull
    catch
        @warn("Artifacts could not be downloaded automatically")
        mv(artifact_tmp_path, artifact_path)
        @warn("Trying to remove large and unneccessary mkl artifact")
        mkl_path = findartifactpath(artifact_path, "mkl")
        if !isnothing(mkl_path)
            rm(mkl_path; recursive=true)
        end
    end

    try
        test_romeo(path, app_name) # required artifacts should be downloaded (<10MB)
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
    args = [phasefile, "-o", file]
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
    rm(pathof("RomeoApp"); force=true, recursive=true)
    download_pkg("RomeoApp")
end
