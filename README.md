# CompileMRI - mritools

[![Build Status](https://github.com/korbinian90/CompileMRI.jl/workflows/CI/badge.svg)](https://github.com/korbinian90/CompileMRI.jl/actions)

## [Download executables for ROMEO, CLEAR-SWI and MCPC-3D-S (Linux and Windows)](https://github.com/korbinian90/CompileMRI.jl/releases)

*Note for MacOS:* We automatically compile for MacOS too, however, it seems to only run on the same version it was compiled on (`macos-11`). The MacOS executables are not signed and require the user to allow the execution of multiple files.

## Compile ROMEO and CLEAR-SWI

1. Install Julia

   Please install Julia using the binaries from this page https://julialang.org. (Julia 1.9 is recommended)

2. Install CompileMRI

   Start Julia (Type julia in the command line or start the installed Julia executable)

   Type the following in the Julia REPL:

   ```julia
   julia> ] # Be sure to type the closing bracket via the keyboard
   # Enters the Julia package manager

   # optional: activate a local julia project in the current folder
   (@v1.7) pkg> activate . 

   (compile) pkg> dev https://github.com/korbinian90/CompileMRI.jl
   # All dependencies are installed automatically
   (compile) pkg> build CompileMRI
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

### Update to newest version

Since I'm using unregistered packages in dev mode, it is tricky to get updates to packages.
Easiest is to remove the folder `user/.julia/dev/CompileMRI` and start over at step 2.

## Known problems

### Workaround for Permission Denied Error

```bash
ERROR: SystemError: opening file "/<path>/RomeoApp/<subfolder>/Project.toml"
```

If the compilation fails because of missing permissions, the `RomeoApp` folder needs write permission. In that case, changing the permission with

```bash
chmod 777 /<path>/RomeoApp/<subfolder>
```

and rerunning the command with

```julia
julia> compile("/tmp/compiled"; force=true)
```

should work.
