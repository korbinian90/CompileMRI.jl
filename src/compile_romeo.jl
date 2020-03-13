function compile_romeo(path; kw...)
    romeopath = joinpath(@__DIR__, "RomeoApp")
    create_app(romeopath, path; kw...)
end
