# CompileMRI

[![Build Status](https://travis-ci.com/korbinian90/CompileMRI.jl.svg?branch=master)](https://travis-ci.com/korbinian90/CompileMRI.jl)

## Compile ROMEO

1. Install Julia

   Please install Julia using the binaries from this page https://julialang.org. (Julia 1.3 or newer is required, some package managers install outdated versions)

2. Install RomeoApp and CompileMRI

   Start Julia (Type julia in the command line or start the installed Julia executable)

   Type the following in the Julia REPL:
   ```
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

4. Update to newest version  
   To update to the newest version of the packages, type in the Julia REPL (Package manager):
   ```julia
   julia> ] up # updates all packages
   or
   julia> ] up RomeoApp
   ```

## Known problems

On linux there might occur a problem regarding the permission of the Julia folders. Manually changing the permissions for the specific folder should fix the problem.
``` 
ERROR: SystemError: opening file "/<path>/RomeoApp/Project.toml"
```
