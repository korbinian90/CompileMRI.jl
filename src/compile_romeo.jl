function compile_romeo(path)
    d = pwd()
    @show path
    try
        cd(@__DIR__)
        build_executable("UnwrappingExecutable.jl", "romeo"; builddir = path)
    finally
        cd(d)
    end
end
