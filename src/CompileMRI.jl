module CompileMRI

    using Pkg, PackageCompiler

    include("compile_romeo.jl")

    export compile_romeo, update_romeoapp

end # module
