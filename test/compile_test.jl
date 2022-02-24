path = tempname()
compile(path)

@test !isempty(readdir(path))

for app in ["romeo", "clearswi", "mcpc3ds"]
    CompileMRI.test(path, app)
end
