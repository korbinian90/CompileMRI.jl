function compile_romeo(path; kw...)
    romeopath = joinpath(splitpath(pathof(RomeoApp))[1:end-2]...)
    create_app(romeopath, path; kw...)
end
