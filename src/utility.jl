function get_apppath()
    return joinpath(dirname(@__DIR__), "App")
end

function get_appname(name)
return Dict("romeo" => "ROMEO", "clearswi" => "CLEARSWI")[name]
end

pathof(app) = normpath(homedir(), ".julia/dev", app)

function copy_matlab(path)
    cp(joinpath(dirname(@__DIR__), "matlab"), joinpath(path, "matlab"))
end

function copy_documentation(path)
    docs = joinpath(dirname(@__DIR__), "documentation")
    cp(joinpath(docs, "README.md"), joinpath(path, "README.md"))
    cp(joinpath(dirname(@__DIR__), "LICENSE"), joinpath(path, "LICENSE"))
    # Only macOS quarantines downloads, and the instructions are the first thing
    # a macOS user needs, so they ship inside the bundle rather than living only
    # on a release page the archive gets separated from.
    if Sys.isapple()
        cp(joinpath(docs, "README_macOS.txt"), joinpath(path, "README_macOS.txt"))
    end
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
    args_dict = Dict("romeo" => ["-p", phasefile, "-o", file, "-t", "1:3", "-k", "nomask"],
                "clearswi" => ["-p", phasefile, "-m", magfile, "-o", file, "-t", "1:3"],
                "mcpc3ds" => ["-p", phasefile, "-m", magfile, "-o", file, "-t", "1:3"],
                "makehomogeneous" => ["-m", magfile, "-o", file, "-s", "3", "-n", "4"],
                "romeo_mask" => ["-p", phasefile, "-m", magfile, "-o", file, "-t", "1:3"])
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
    # Same single source of truth as App.jl: App/Project.toml. This used to
    # grep App.jl for the literal line `const version = "..."`, which meant a
    # reformat of that line silently produced "Unknown Version" and named the
    # release archives after it, space and all.
    toml = joinpath(get_apppath(), "Project.toml")
    m = match(r"^version\s*=\s*\"([^\"]+)\""m, read(toml, String))
    m === nothing && error("no version field in $toml")
    return String(m.captures[1])
end

function test()
    Pkg.activate(get_apppath())
    Pkg.test()
    Pkg.activate(pwd())
end