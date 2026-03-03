"""
    compile(path="compiled"; kwargs...)

Compile all MRI tools into standalone executables using PackageCompiler.

Uses `--strip-ir` to produce smaller binaries by removing LLVM IR from the sysimage.
Note: `--strip-metadata` is intentionally omitted — PackageCompiler does not filter it
from the base sysimage build step, causing a segfault on Julia 1.12.
Standard libraries are filtered and lazy artifacts excluded to minimize binary size.

# Keyword Arguments
- `apps`: Vector of app names to compile (default: all 5 tools)
- `filter_stdlibs`: Remove unused standard libraries (default: true)
- `include_lazy_artifacts`: Include lazy artifacts (default: false)
- `include_transitive_dependencies`: Include transitive deps (default: false)
- `strip`: Strip LLVM IR from the sysimage for smaller binaries (default: true)
- `cpu_target`: CPU target string for broad hardware compatibility.
  Defaults to `nothing`, which uses PackageCompiler's built-in default:
  `generic;sandybridge,-xsaveopt,clone_all;haswell,-rdrnd,base(1)` on x86_64.
  This already supports Sandy Bridge (2011+) and avoids AVX-512 issues on old CPUs.
  Pass an explicit string to override (must be a valid multi-target LLVM spec).
- `precompile_execution_file`: File to run for precompilation warmup
- `force`: Overwrite existing output directory (default: false)
"""
function compile(path="compiled";
        apps = ["romeo", "clearswi", "mcpc3ds", "makehomogeneous", "romeo_mask"],
        filter_stdlibs=true,
        include_lazy_artifacts=false,
        include_transitive_dependencies=false,
        strip=true,
        cpu_target=nothing,
        precompile_execution_file=abspath(joinpath(@__DIR__, "..", "test", "clearswi_test.jl")),
        kw...)

    apppath = joinpath(dirname(@__DIR__), "App")
    executables = [c => c for c in apps]

    # Only use --strip-ir (not --strip-metadata): PackageCompiler correctly filters
    # --strip-ir from the base sysimage step, but does NOT filter --strip-metadata,
    # which causes a segfault on Julia 1.12 during base sysimage compilation.
    sysimage_build_args = strip ? `--strip-ir` : ``

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
    strip && printstyled(" with IR stripping for smaller binaries"; color=:cyan)
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
