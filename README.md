# CompileMRI

[![Build Status](https://github.com/korbinian90/CompileMRI.jl/workflows/CI/badge.svg)](https://github.com/korbinian90/CompileMRI.jl/actions)

## Compile ROMEO

1. Install Julia

   Please install Julia using the binaries from this page https://julialang.org. (Julia 1.5 or newer is required, some package managers install outdated versions)

2. Install RomeoApp and CompileMRI

   Start Julia (Type julia in the command line or start the installed Julia executable)

   Type the following in the Julia REPL:
   ```julia
   julia> ] # Be sure to type the closing bracket via the keyboard
   # Enters the Julia package manager
   (@v1.5) pkg> add https://github.com/korbinian90/RomeoApp.jl#master
   (@v1.5) pkg> add https://github.com/korbinian90/CompileMRI.jl#master
   # All dependencies are installed automatically
   ```

3. Compile ROMEO into a command line binary

   ```julia
   julia> using CompileMRI
   julia> compile_romeo("/tmp/romeo_compiled")
   ```
   If the folder to output the binary (here `/tmp/romeo_compiled`) already exists, the additional keyword argument `force=true` is required:
   ```julia
   julia> compile_romeo("/tmp/romeo_compiled"; force=true)
   ```
   
### Update to newest version
To update to the newest version of the packages, type in the Julia REPL (Package manager):
```julia
julia> ] up # updates all packages
or
julia> ] up RomeoApp
```

## Known problems
### Workaround for Permission Denied Error
``` 
ERROR: SystemError: opening file "/<path>/RomeoApp/<subfolder>/Project.toml"
``` 
If the compilation fails because of missing permissions, the `RomeoApp` folder needs write permission. In that case, changing the permission with
```bash
$ chmod 777 /<path>/RomeoApp/<subfolder>
```
and rerunning the command with
```julia
julia> compile_romeo("/tmp/romeo_compiled"; force=true)
```
should work.
