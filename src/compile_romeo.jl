function compile_romeo(path;
        app_name="romeo",
        filter_stdlibs=false,
        precompile_execution_file=abspath(joinpath(@__DIR__, "..", "test", "romeo_test.jl")),
        kw...)
    romeopath = pathof("RomeoApp")
    if !isdir(romeopath)
        download_pkg("RomeoApp")
    end
    create_app(romeopath, path; app_name=app_name, filter_stdlibs=filter_stdlibs, precompile_execution_file=precompile_execution_file, kw...)
    clean_app(path) # remove unneccesary artifacts dir (600MB)
    test_romeo(path, app_name) # required artifacts should be downloaded (<10MB)
end

pathof(app) = normpath(homedir(), ".julia/dev", app)

function clean_app(path)
    if isdir(path)
        rm(joinpath(path, "artifacts"); recursive=true)
    else
        println("No artifacts in $path")
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

function update_romeoapp()
    rm(pathof("RomeoApp"); force=true, recursive=true)
    download_romeoapp()
end
