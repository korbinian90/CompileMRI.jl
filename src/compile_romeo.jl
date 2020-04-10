function compile_romeo(path; kw...)
    romeopath = joinpath(pathof(RomeoApp), "..", "..")
    create_app(romeopath, path; kw...)
end
