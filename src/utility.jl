function get_apppath()
    return joinpath(dirname(@__DIR__), "App")
end

function get_appname(name)
return Dict("romeo" => "ROMEO", "clearswi" => "ClearswiApp")[name]
end

pathof(app) = normpath(homedir(), ".julia/dev", app)

function copy_matlab(path)
    cp(joinpath(dirname(@__DIR__), "matlab"), joinpath(path, "matlab"))
end

function copy_documentation(path)
    cp(joinpath(dirname(@__DIR__), "documentation", "README.md"), joinpath(path, "README.md"))
    cp(joinpath(dirname(@__DIR__), "LICENSE"), joinpath(path, "LICENSE"))
end

function update()
    Pkg.activate(get_apppath())
    for name in ["clearswi", "romeo"]
        app_name = get_appname(name)
        Pkg.update(app_name)
    end
    Pkg.update()
    Pkg.activate(pwd())
end

function test(path, app_name)
    file = tempname()
    phasefile = abspath(joinpath(@__DIR__, "..", "test", "data", "small", "Phase.nii"))
    magfile = abspath(joinpath(@__DIR__, "..", "test", "data", "small", "Mag.nii"))
    args_dict = Dict("romeo" => [phasefile, "-o", file, "-t", "1:3", "-k", "nomask"],
                "clearswi" => ["-p", phasefile, "-m", magfile, "-o", file, "-t", "1:3"],
                "mcpc3ds" => ["-p", phasefile, "-m", magfile, "-o", file, "-t", "1:3"])
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

function mritools_version()
    version_file = joinpath(get_apppath(), "src", "App.jl")
    for line in eachline(version_file)
        if startswith(line, "const version = ")
            return split(line, "\"")[2]
        end
    end
    return "Unknown Version"
end

function test()
    Pkg.activate(get_apppath())
    Pkg.test()
    Pkg.activate(pwd())
end