function compile(path="compiled";
        apps = ["romeo", "clearswi"],
        filter_stdlibs=true,
        precompile_execution_file=abspath(joinpath(@__DIR__, "..", "test", "clearswi_test.jl")),
        include_transitive_dependencies=false,
        kw...)

    for app in apps
        check_pkg(app)
    end
    
    apppath = joinpath(dirname(@__DIR__), "App")
    executables=[c=>c for c in apps]
    create_app(apppath, path; executables, filter_stdlibs, precompile_execution_file, include_transitive_dependencies, kw...)

    for app in apps
        test(path, app)
    end

    copy_matlab(path)

    printstyled("Success! CLEARSWI and ROMEO compiled and tested!\n"; color=:green)
    @warn("Relocatability has to be tested manually!")
end
