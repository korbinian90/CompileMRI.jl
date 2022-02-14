module CompileMRI

    using Pkg, PackageCompiler

    include("utility.jl")
    include("compile_romeo.jl")
    include("compile_clearswi.jl")
    include("compile.jl")

    export  compile,
            compile_romeo,
            update_romeo,
            compile_clearswi,
            update_clearswi

end # module
