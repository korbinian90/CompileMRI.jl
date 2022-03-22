module CompileMRI

    using Pkg, PackageCompiler

    include("utility.jl")
    include("compile.jl")

    export  compile,
            test,
            version,
            update

end # module
