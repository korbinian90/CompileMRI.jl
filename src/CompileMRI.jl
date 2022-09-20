module CompileMRI

    using Pkg, PackageCompiler
    using HostCPUFeatures, Static
    HostCPUFeatures.has_feature(::Val{:x86_64_bmi}) = static(false)

    include("utility.jl")
    include("compile.jl")

    export  compile,
            test,
            version,
            update

end # module
