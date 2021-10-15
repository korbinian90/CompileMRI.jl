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

pathof(app) = normpath(homedir(), ".julia/dev", app)

function clean_app(path, app_name)
    # remove all dlls in mkl artifact but keep
    # mkl_core.1.dll and mkl_rt.1.dll

    artifact_path = joinpath(path, "share", "julia", "artifacts")
    if !ispath(artifact_path)
        artifact_path = joinpath(path, "artifacts")
    end
    
    mkl_path = findartifactpath(artifact_path, "mkl")
    if isdir(joinpath(mkl_path, "bin"))
        for f in readdir(joinpath(mkl_path, "bin"); join=true)
            if !(occursin("mkl_core.1.dll", f) || occursin("mkl_rt.1.dll", f))
                rm(f)
            end
        end
    end
    if isdir(joinpath(mkl_path, "lib"))
        for f in readdir(joinpath(mkl_path, "lib"); join=true)
            if !(occursin("libmkl_core.so", f) || occursin("libmkl_rt.so", f))
                rm(f)
            end
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
