"""
    compile(path="compiled"; kwargs...)

Compile all MRI tools into standalone executables using PackageCompiler.

Uses `--strip-ir` and `--strip-metadata` to produce smaller binaries (JuliaC-style stripping).
Standard libraries are filtered and lazy artifacts excluded to minimize binary size.

# Keyword Arguments
- `apps`: Vector of app names to compile (default: all 5 tools)
- `filter_stdlibs`: Remove unused standard libraries (default: true)
- `include_lazy_artifacts`: Include lazy artifacts (default: false)
- `include_transitive_dependencies`: Include transitive deps (default: false)
- `strip`: Strip IR and metadata from the sysimage for smaller binaries (default: true)
- `cpu_target`: CPU target string for broad hardware compatibility.
  Default targets Sandy Bridge (2011+) to avoid AVX-512 issues on old CPUs.
  Set to `nothing` to use PackageCompiler's default (native CPU).
- `precompile_execution_file`: File to run for precompilation warmup
- `force`: Overwrite existing output directory (default: false)
"""
function compile(path="compiled";
        apps = ["romeo", "clearswi", "mcpc3ds", "makehomogeneous", "romeo_mask"],
        filter_stdlibs=true,
        include_lazy_artifacts=false,
        include_transitive_dependencies=false,
        strip=true,
        cpu_target="generic;sandybridge,-xsaveopt,clone_all",
        precompile_execution_file=abspath(joinpath(@__DIR__, "..", "test", "clearswi_test.jl")),
        kw...)

    apppath = joinpath(dirname(@__DIR__), "App")
    executables = [c => c for c in apps]

    # Build sysimage args for smaller binaries (JuliaC-style stripping)
    sysimage_build_args = strip ? `--strip-ir --strip-metadata` : ``

    create_app_kwargs = Dict{Symbol,Any}(
        :executables => executables,
        :filter_stdlibs => filter_stdlibs,
        :precompile_execution_file => precompile_execution_file,
        :include_transitive_dependencies => include_transitive_dependencies,
        :include_lazy_artifacts => include_lazy_artifacts,
        :sysimage_build_args => sysimage_build_args,
    )

    if !isnothing(cpu_target)
        create_app_kwargs[:cpu_target] = cpu_target
    end

    # Merge any additional keyword arguments
    for (k, v) in kw
        create_app_kwargs[k] = v
    end

    printstyled("Compiling $(length(apps)) MRI tools"; color=:cyan)
    strip && printstyled(" with IR/metadata stripping for smaller binaries"; color=:cyan)
    println()

    create_app(apppath, path; create_app_kwargs...)

    for app in apps
        test(path, app)
    end

    copy_matlab(path)
    copy_documentation(path)

    printstyled("Success! $(uppercase.(apps)) compiled and tested!\n"; color=:green)
    @warn("Relocatability has to be tested manually!")
end
