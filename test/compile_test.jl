path = tempname()
compile(path)

@test !isempty(readdir(path))

for app in ["romeo", "clearswi"]
    CompileMRI.test(path, app)
end
