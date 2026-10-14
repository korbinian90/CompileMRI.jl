module CompileMRI

    using Pkg, PackageCompiler, Patchelf_jll

    include("utility.jl")
    include("compile.jl")

    export  compile,
            test,
            version,
            update

end # module
