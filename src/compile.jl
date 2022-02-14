function compile(path;
        filter_stdlibs=true,
        precompile_execution_file=abspath(joinpath(@__DIR__, "..", "test", "clearswi_test.jl")),
        clean=true,
        kw...)
    apppath = "App" # make absolut path?
    compile = ["romeo", "clearswi"]
    
    executables=[c=>c for c in compile]
    create_app(apppath, path; executables, filter_stdlibs, precompile_execution_file, kw...)
    copy_mkl(path)
    for app in compile
        test(path, app)
    end
    if clean
        clean_app(path, app_name) # remove unneccesary artifacts dir (600MB)
    end
    copy_matlab(path)
    printstyled("Success! CLEARSWI and ROMEO compiled and tested!\n"; color=:green)
    @warn("Relocatability has to be tested manually!")
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
