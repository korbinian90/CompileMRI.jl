function compile(path="compiled";
        apps = ["romeo", "clearswi", "mcpc3ds", "makehomogeneous", "romeo_mask"],
        filter_stdlibs=true,
        precompile_execution_file=abspath(joinpath(@__DIR__, "..", "test", "clearswi_test.jl")),
        include_transitive_dependencies=false,
        # --strip-metadata drops the source-location and docstring metadata from
        # the sysimage. Measured on this app with Julia 1.10.12: sys.so goes from
        # 437.6 MB to 263.8 MB and the bundle from 679.0 MB to 502.7 MB. Nothing
        # about the results changes - 14 option combinations across all five
        # programs produced byte identical NIfTIs and identical exit codes - and
        # startup is slightly faster because there is less image to page in.
        # Error messages keep their file and line; only argument names in stack
        # frames become "?".
        #
        # NOT --strip-ir, which is what the earlier attempt at this used
        # alongside it: that one produced binaries that exited 1 with no output
        # and no error. The two flags were never separated then.
        #
        # It also segfaults on Julia 1.12, where PackageCompiler filters
        # --strip-ir out of the base sysimage build step but not
        # --strip-metadata. We build with 1.10.
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
