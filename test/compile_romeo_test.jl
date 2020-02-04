path = mktempdir()
compile_romeo(path)

@test !isempty(readdir(path))
args = [phasefile, "-o", raw"F:\MRI\Analysis\Volunteer7T\phase\romeo", "-m", magfile]
cmd = `$path/romeo.exe $args`
run(cmd)
