# CompileMRI - mritools

[![Build Status](https://github.com/korbinian90/CompileMRI.jl/workflows/CI/badge.svg)](https://github.com/korbinian90/CompileMRI.jl/actions)

## [Download executables for ROMEO, CLEAR-SWI and MCPC-3D-S (Linux and Windows)](https://github.com/korbinian90/CompileMRI.jl/releases)

*Note for MacOS:* We automatically compile for MacOS too, however, it seems to only run on the same version it was compiled on (`macos-11`). The MacOS executables are not signed and require the user to allow the execution of multiple files.

## Compile ROMEO and CLEAR-SWI

1. Install Julia

   Please install Julia using the binaries from this page https://julialang.org. (Julia 1.10 is recommended, newer versions might error)

2. Install CompileMRI (For julia 1.9 see below)

   Start Julia (Type julia in the command line or start the installed Julia executable)

   Type the following in the Julia REPL:

   ```julia
   julia> ] # Be sure to type the closing bracket via the keyboard
   # Enters the Julia package manager

   # optional: activate a local julia project in the current folder
   (@v1.10) pkg> activate . 

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

## Static compilation with juliac (experimental)

`romeo` can also be built with `juliac`, the static compiler that ships with
Julia 1.13. It compiles only the code the program can reach and leaves out the
Julia compiler, LLVM and the system image, so the result is a small directory
that starts instantly. Measured on the `test/data/small` dataset (3 echoes,
51x51x41, with magnitude and robustmask), Linux x64:

| | PackageCompiler bundle (v4.9.0) | juliac `romeo` |
|---|---|---|
| installed size | 593 MB | 57 MB |
| download (.tar.xz) | 101 MB | 13 MB |
| `romeo` run, including start-up | 3.9 s | 0.08 s |

The output files are byte-identical to the ones from the PackageCompiler
bundle. There is no memory mapping in this build: the inputs are read into
memory as Float32.

```bash
julia +1.13 juliac/build.jl build/romeo
build/romeo/bin/romeo phase.nii -m mag.nii -t "[4,8,12]" -o out
```

`build.jl` installs the `juliac` app on first use. It needs the versions pinned
in `juliac/Project.toml`, which are the first ones whose code compiles
statically: ROMEO 1.7 with its own command line parser in place of ArgParse,
and MriResearchTools 3.9 with NIfTI readers and a writer of fixed type. The
`juliac` workflow builds and smoke-tests it on demand.

`clearswi`, `mcpc3ds`, `makehomogeneous` and `romeo_mask` are not compiled
this way yet: their entry points still parse with ArgParse into untyped
dictionaries, which needs the same port that `romeo` received, and CLEAR-SWI
additionally calls into TGV QSM. Until then the PackageCompiler bundle above is
the release.

## Which library versions a release contains

The compiled `mritools` bundle is a snapshot, not a rolling build. `App/Project.toml`
pins the libraries with exact (`=`) version bounds, so the binaries contain those
versions and nothing newer, whatever has been released in the meantime:

| Library | Pinned in `App/Project.toml` |
|---|---|
| `MriResearchTools` | `= 3.3.3` |
| `ROMEO` | `= 1.3.3` |
| `CLEARSWI` | `= 1.6.1` |
| `QuantitativeSusceptibilityMappingTGV` | `0.5.0` (range) |

Exact pins are the right thing for a reproducible binary, but nothing currently
moves them: a release of `MriResearchTools`, `ROMEO` or `CLEARSWI` produces no
signal here, so the pins only advance when someone remembers. **They are behind at
the time of writing** - `MriResearchTools` is at 3.5.0 and `ROMEO` at 1.4.0 - which
means the shipped `romeo` is not the ROMEO in `ROMEO.jl@master`. Bump the pins here
and re-release when picking up upstream fixes, and check this table before reporting
a binary bug upstream.

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

## Installing CompileMRI version for Julia 1.9

```julia
julia> ] # Be sure to type the closing bracket via the keyboard
# Enters the Julia package manager

# optional: activate a local julia project in the current folder
(@v1.10) pkg> activate . 

(compile) pkg> dev https://github.com/korbinian90/CompileMRI.jl
```

Manually navigate to `~/.julia/dev/CompileMRI` in a system shell and checkout last julia 1.9 compatible version:

```bash
   git checkout v1.9
```

Continue in julia REPL

```julia
(compile) pkg> build CompileMRI
```
