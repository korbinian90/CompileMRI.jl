function compile(path="compiled";
        apps = ["romeo", "clearswi", "mcpc3ds", "makehomogeneous", "romeo_mask"],
        kw...)

    outpath = abspath(path)
    mkpath(joinpath(outpath, "bin"))
    apppath = joinpath(dirname(@__DIR__), "App")

    julia_bin = joinpath(Sys.BINDIR, "julia" * (Sys.iswindows() ? ".exe" : ""))
    juliac_script = normpath(joinpath(Sys.BINDIR, "..", "share", "julia", "juliac", "juliac.jl"))

    for app in apps
        entry = joinpath(apppath, "entries", "$app.jl")
        outname = app * (Sys.iswindows() ? ".exe" : "")
        outfile = joinpath(outpath, "bin", outname)
        # --project must be a julia flag (juliac uses Base.active_project() internally)
        run(`$julia_bin --startup-file=no --project=$apppath $juliac_script --output-exe $outfile $entry`)
    end

    for app in apps
        test(path, app)
    end

    copy_matlab(path)
    copy_documentation(path)

    printstyled("Success! $(uppercase.(apps)) compiled and tested!\n"; color=:green)
    @warn("Relocatability has to be tested manually!")
end
