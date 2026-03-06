module CompileMRI

    using Pkg

    include("utility.jl")
    include("compile.jl")

    export  compile,
            test,
            version,
            update

end # module
