path = mktempdir()
compile_romeo(path)

@test !isempty(readdir(path))

run("$path/romeo.exe")
