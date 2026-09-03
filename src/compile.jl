function compile(path="compiled";
        apps = ["romeo", "clearswi", "mcpc3ds", "makehomogeneous", "romeo_mask"],
        filter_stdlibs=true,
        precompile_execution_file=abspath(joinpath(@__DIR__, "..", "test", "clearswi_test.jl")),
        include_transitive_dependencies=false,
        # Halves sys.so. Not --strip-ir, which breaks the binaries. Segfaults on Julia 1.12.
        sysimage_build_args=`--strip-metadata`,
        kw...)

    apppath = joinpath(dirname(@__DIR__), "App")
    executables=[c=>c for c in apps]
    create_app(apppath, path; executables, filter_stdlibs, precompile_execution_file, include_transitive_dependencies, sysimage_build_args, kw...)

    for app in apps
        test(path, app)
    end

    copy_matlab(path)
    copy_documentation(path)

    printstyled("Success! $(uppercase.(apps)) compiled and tested!\n"; color=:green)
    @warn("Relocatability has to be tested manually!")
end
