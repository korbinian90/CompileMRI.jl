function download_pkg(pkg, subpkgs=nothing)
    Pkg.develop(PackageSpec(;url="https://github.com/korbinian90/$pkg.jl"))
    if !isnothing(subpkgs)
        Pkg.activate(pathof(pkg))
        for subpkg in subpkgs
            Pkg.add(PackageSpec(;url="https://github.com/korbinian90/$subpkg.jl"))
        end
    end
    Pkg.instantiate()
end

function findartifactpath(pth, name)
    for d in readdir(pth; join=true)
        if any(occursin.(lowercase(name), lowercase.(readdir(joinpath(d, "logs")))))
            return d
        end
    end
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
        @warn("Artifact cleaning failed! Please recompile clearswi with the option `clean=false`. The artifacts folder will be very large but some of them might not needed and can be manually removed.")
    end
end

function copy_matlab(path)
    cp(joinpath(dirname(@__DIR__), "matlab"), joinpath(path, "matlab"))
end
