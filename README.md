# CompileMRI
## Compile ROMEO and CLEAR-SWI

1. Install Julia

   Please install Julia using the binaries from this page https://julialang.org. (Julia 1.6 or newer is recommended, some package managers install outdated versions)

2. Install CompileMRI

   Start Julia (Type julia in the command line or start the installed Julia executable)

   Type the following in the Julia REPL:
   ```julia
   julia> ] # Be sure to type the closing bracket via the keyboard
   # Enters the Julia package manager
   (@v1.6) pkg> add https://github.com/korbinian90/CompileMRI.jl#master
   # All dependencies are installed automatically
   ```

3. Create a command line executable

   ```julia
   julia> using CompileMRI
   julia> compile("/tmp/compiled")
   ```
   If the folder to output the binary (here `/tmp/compiled`) already exists, the additional keyword argument `force=true` is required:
   ```julia
   julia> compile("/tmp/compiled"; force=true)
   ```
   If only one app should be compiled, use the syntax
   ```julia
   julia> compile("/tmp/compiled"; apps=["romeo"])
   ```
   
### Update to newest version
To update to the newest version of the packages, type in the Julia REPL (Package manager):  
**CompileMRI**
```
julia> ] up CompileMRI
```
**ROMEO and CLEAR-SWI**
```julia
   julia> using CompileMRI
   julia> update("romeo")
   julia> update("clearswi")
   julia> ] up # required to update depending packages
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
julia> compile("/tmp/compiled"; force=true)
```
should work.
