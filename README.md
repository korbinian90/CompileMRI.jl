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

All five programs can also be built with `juliac`, the static compiler of Julia
1.13. It compiles only the code the programs can reach and leaves out the Julia
compiler, LLVM and the system image, so the result is a small directory that
starts instantly. juliac compiles one entry point per executable, so the bundle
is one `mritools` executable that dispatches on the name it is invoked by, with
`bin/romeo`, `bin/clearswi` and the others links to it; `mritools romeo ...` does
the same. The code the programs share is compiled once.

Measured on Linux x64 against the v4.9.0 release bundle:

| | PackageCompiler bundle (v4.9.0) | juliac bundle |
|---|---|---|
| installed size | 593 MB | 37.4 MB |
| download (.tar.xz) | 101 MB | 7.8 MB |
| `romeo --version` | 0.54 s | 0.03 s |
| `romeo` on `test/data/small` | 4.1 s | 0.08 s |
| `clearswi` on `test/data/small` | 0.9 s | 0.3 s |

Of the 37.4 MB, 22 MB is the program, 9 MB the runtime libraries it loads,
5 MB FFTW, which clearswi uses for its Laplacian unwrapping, and 1 MB the Matlab
wrappers and documents that also ship with the PackageCompiler bundle.

The outputs were compared with the release on 42 command lines covering the
options of all five programs (`test/data/small`, 3 echoes). 34 give
byte-identical files, all 18 clearswi and all 8 romeo_mask command lines among
them. The other 8 all run MCPC-3D-S or the smoothing of makehomogeneous, and
differ in the last bits of Float32 (at most 7e-7 rad in the phase, 6e-5 Hz in
B0). That comes from Julia 1.13 rather than from juliac: the same code, and the
unchanged code of the release, give the same bytes as the juliac build when run
in Julia 1.13.

```bash
julia +1.13 juliac/build.jl build/mritools
build/mritools/bin/romeo phase.nii -m mag.nii -t "[4,8,12]" -o out
build/mritools/bin/mritools clearswi --help
```

`build.jl` installs the `juliac` app on first use. It needs the versions pinned in
`juliac/Project.toml`, the first whose code compiles statically: ROMEO 1.7,
MriResearchTools 3.9 with its own command line parser in place of ArgParse and NIfTI
readers and a writer of fixed type, and CLEARSWI 1.8. Until those are registered,
`juliac/Project.toml` and `App/Project.toml` take them from checkouts beside this
repository, and `build.jl` checks that both pin the same versions. The `juliac`
workflow builds and smoke-tests the bundle on Linux, macOS and Windows. The macOS
bundle is 32 MB. The Windows bundle is 495 MB, because the libraries beside the
executable are not pruned yet.

What the juliac bundle does not do yet:

- `clearswi --qsm`. TGV QSM does not compile statically: it passes its element
  type as an untyped keyword, reports progress through ProgressMeter, picks the GPU
  backend by module lookup, computes a 3x3 SVD through LAPACK, which would bring
  OpenBLAS back into the bundle, and runs its kernels through KernelAbstractions.
  The bundle says so and exits instead. `--qsm-input` works.
- Memory mapping. The inputs are read into memory as Float32, whatever their type
  on disk.
- NIfTI-2 input.
- Stack traces. An error prints its message, which is enough for the errors the
  programs raise themselves.

## Which library versions a release contains

The compiled `mritools` bundle is a snapshot, not a rolling build. `App/Project.toml`
pins the libraries with exact (`=`) version bounds, so the binaries contain those
versions and nothing newer, whatever has been released in the meantime:

| Library | Pinned in `App/Project.toml` |
|---|---|
| `MriResearchTools` | `= 3.9.0` |
| `ROMEO` | `= 1.7.0` |
| `CLEARSWI` | `= 1.8.0` |
| `QuantitativeSusceptibilityMappingTGV` | `= 0.5.4` |

Exact pins are the right thing for a reproducible binary, but nothing moves them:
a release of `MriResearchTools`, `ROMEO` or `CLEARSWI` produces no signal here, so
the pins only advance when someone remembers. Bump the pins here and re-release
when picking up upstream fixes, and check this table before reporting a binary
bug upstream.

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
