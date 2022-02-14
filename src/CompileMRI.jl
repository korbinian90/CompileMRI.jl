module CompileMRI

    using Pkg, PackageCompiler

    include("utility.jl")
    include("compile.jl")

    export  compile,
            update

end # module
