function check_pkg(name)
    try
        Pkg.activate(get_apppath())
        Pkg.instantiate()
    catch
    end
    try
        download_pkg(get_appname(name))
    catch
    end
    Pkg.activate(pwd())
end

function get_apppath()
    return joinpath(dirname(@__DIR__), "App")
end

function get_appname(name)
    return Dict("romeo" => "RomeoApp", "clearswi" => "ClearswiApp")[name]
end

function download_pkg(pkg, subpkgs=nothing)
    if (isnothing(subpkgs) && pkg == "ClearswiApp") return download_pkg(pkg, ["CLEARSWI"]) end

    Pkg.activate(get_apppath())
    if !isnothing(subpkgs)
        for subpkg in subpkgs
            Pkg.add(PackageSpec(;url="https://github.com/korbinian90/$subpkg.jl"))
        end
    end
    Pkg.develop(PackageSpec(;url="https://github.com/korbinian90/$pkg.jl"))
    Pkg.instantiate()

    Pkg.activate(pwd())
end

function findartifactpath(pth, name)
    for d in readdir(pth; join=true)
        if any(occursin.(lowercase(name), lowercase.(readdir(joinpath(d, "logs")))))
            return d
        end
    end
end

pathof(app) = normpath(homedir(), ".julia/dev", app)

function copy_matlab(path)
    cp(joinpath(dirname(@__DIR__), "matlab"), joinpath(path, "matlab"))
end

function update()
    Pkg.activate(get_apppath())
    for name in ["clearswi", "romeo"]
        app_name = get_appname(name)
        Pkg.update(app_name)
    end
    Pkg.update()
    Pkg.activate(get_apppath())
end

function test(path, app_name)
    file = tempname()
    phasefile = abspath(joinpath(@__DIR__, "..", "test", "data", "small", "Phase.nii"))
    magfile = abspath(joinpath(@__DIR__, "..", "test", "data", "small", "Mag.nii"))
    args_dict = Dict("romeo" => [phasefile, "-o", file, "-t", "1:3", "-k", "nomask"],
                "clearswi" => ["-p", phasefile, "-m", magfile, "-o", file, "-t", "1:3"])
    args = args_dict[app_name]
    name = app_name * (Sys.iswindows() ? ".exe" : "")
    executable = joinpath(path, "bin", name)
    @assert isfile(executable)
    cmd = `$executable $args`
    @assert success(run(cmd))
end

function version()
    Pkg.activate(get_apppath())
    Pkg.status()
    Pkg.activate(pwd())
end

function romeo_version()
    Pkg.TOML.parsefile(joinpath(pathof("RomeoApp"), "Project.toml"))["version"]
end
