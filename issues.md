# CompileMRI.jl - issue list

Working notes from the architecture review of 2026-08-19..21. Uncommitted on
purpose. Cross-repository items and release ordering are in `/home/user/issues.md`
(X0..X7). Full evidence:
https://claude.ai/code/artifact/1dcb7a4a-4523-46fc-af23-7c5b0ecc3688

Measured on this machine unless marked *unverified*. State refers to branch
`claude/julia-repos-architecture-review-tj1zzz`.

This is the highest-traffic artefact in the stack, the `mritools` bundle that
the ROMEO README sends every user to first, and it was the least maintained part
of it. Every version-drift problem in the family passes through
`App/Project.toml`.

---

## Done on this branch

- **F14** actions SHA-pinned with dependabot; the matrix now covers the 1.10
  that actually builds the binaries, not only `pre`; two dead release steps
  replaced.
- **Pins moved forward** to `ROMEO = "=1.5.0"`, `MriResearchTools = "=3.6.0"`,
  `CLEARSWI = "=1.6.2"`. They had been `=1.3.3` / `=3.3.3` while the libraries
  were at 1.4.0 / 3.5.0, so two minor versions of foundation fixes were absent
  from every downloaded binary and the shipped `romeo` was not the ROMEO in the
  repository.
- Caught and fixed a self-inflicted conflict while doing that: the App briefly
  pinned `=1.4.0` against a MriResearchTools 3.6.0 that requires ROMEO `1.5`,
  which is unsatisfiable. Verified the App resolves and runs end to end after
  the correction.

## Open

### K1. Nothing moves the pins
Equality pins are right for a reproducible binary build. What is missing is the
mechanism: today a release of MriResearchTools produces no signal anywhere and
someone has to remember. The README's own upgrade instructions are "remove the
folder `~/.julia/dev/CompileMRI` and start over", an accurate description of a
process with no automation in it. Options: a scheduled job that opens a PR when
a dependency registers a new version, or a release checklist item in each
upstream repo. Cheap either way, and it is the root of F14's drift half.

### K2. Re-release is the last step of X0, and it matters more than usual
Every mritools release since ROMEO 1.2.0 (2024-10-03) has shipped the
`unwrap_individual!` data race: `romeo -i` and `clearswi --qsm` on a multi-core
machine could differ by a full 2pi between identical runs. This release is that
fix reaching users. Order: ROMEO 1.5.0, MriResearchTools 3.6.0, CLEARSWI 1.6.2,
then here.

### K2b. Salvage from the closed compilation PRs (#7, #8)

Both are closed as stale (they were near-duplicates of each other), but the
content is worth keeping:

- `sysimage_build_args = ` `--strip-ir` for a smaller sysimage. **Do not add
  `--strip-metadata` alongside it**: PackageCompiler filters `--strip-ir` out of
  the base sysimage build step but not `--strip-metadata`, which segfaults on
  Julia 1.12.
- `include_lazy_artifacts=false`.
- `cpu_target`: leave it at PackageCompiler's default
  (`generic;sandybridge,-xsaveopt,clone_all;haswell,-rdrnd,base(1)` on x86_64),
  which already covers Sandy Bridge and later and avoids AVX-512 on old CPUs.
- Moving the compile toolchain to Julia 1.12 / PackageCompiler 2.2.

Weigh this against X6 before spending time on it: `juliac --trim=safe` measured
2.29 MB and 39 ms on the ROMEO kernel here, against the 160 MB bundle. Stripping
IR makes the bundle smaller; it does not change its class.

### K3. 14.5k lines of vendored third-party MATLAB
Unreviewed here. Worth deciding whether it still needs to ship, and if it does,
whether its provenance and licence are recorded.

### K4. F11 - a fourth copy of `test/data/small`
Byte-identical to MriResearchTools, ROMEO and mritools-binaries; CLEARSWI's has
diverged. Collapse into the conformance artefact (X3).

### K5. F19/X2 - `eval` in the echo-time parsers
`App/src/Mcpc3ds.jl:133` and `App/src/ROMEO_mask.jl`. `Mcpc3ds`'s `parse_array`
is 7 lines against romeo's 25 but evals too, so there is no safe implementation
among the four to promote.

### K6. `romeo` and `romeo_mask` share four drifted function names (F13/X1)
`load_data_and_resolve_args!`, `get_keyargs`, `select_echoes!`,
`write_qualitymap` exist in both and have all drifted. `exception_handler` is
byte-identical (same md5) in all five CLI tools.

### K7. Five `invokelatest` calls in `App.jl`
Three lines each. Irrelevant today; a blocker for X6 if static compilation is
ever picked up.

### K8. Lower the Linux glibc floor with a container build - the widest-reach item left

The released Linux bundle refuses to start on anything older than **glibc
2.34**, which excludes CentOS 7 (2.17) and RHEL 8 / Debian 10 (2.28) - a large
share of the academic cluster nodes this audience actually runs on.

Measured on the shipped v4.7.1 assets, max GLIBC symbol version across all 47
bundled libraries:

| bundle | floor |
|---|---|
| `mritools_ubuntu-22.04_4.7.1` | GLIBC_2.34 |
| `mritools_ubuntu-24.04_4.7.1` | GLIBC_2.38 |

**The floor comes from the runner, not from Julia.** Julia's own shipped
libraries need at most GLIBC_2.17, and that is true for 1.9, 1.11 and 1.12
alike, so upgrading Julia neither helps nor hurts here:

    julia-1.9.0    max across all shipped libs = GLIBC_2.12
    julia-1.11.5   max across all shipped libs = GLIBC_2.17
    julia-1.12.7   max across all shipped libs = GLIBC_2.17

The 2.34 comes from the parts PackageCompiler links locally with the runner's
toolchain. glibc 2.34 merged libpthread/libdl/librt into libc and re-versioned
those symbols, so *any* binary linked on a host with glibc >= 2.34 inherits it.
Demonstrated with a program that does nothing but `pthread_create` + `dlopen`,
compiled on glibc 2.39:

    GLIBC_2.2.5
    GLIBC_2.4
    GLIBC_2.34     <- from pthread/dlopen alone

**`juliac` does not help.** `--trim` removes Julia code from the image; it does
not remove the runtime's libc dependency. libjulia still calls `pthread_create`
and `dlopen`, so a juliac binary linked on ubuntu-22.04 hits the same wall. It
is a size lever (2.29 MB vs 160 MB, see X6), not a portability one.

**What does work: link on an older host.** ubuntu-20.04 (glibc 2.31) is retired
and ubuntu-22.04 (2.35) is the oldest runner available, so the runner cannot go
lower - but the *container* can, on the same free `ubuntu-latest` runner, via
`container:` on the job. Julia's 2.17 is the floor worth aiming at:

| container | glibc | additionally reaches |
|---|---|---|
| `manylinux2014` (CentOS 7) | 2.17 | CentOS/RHEL 7 |
| `manylinux_2_28` (AlmaLinux 8) | 2.28 | RHEL 8, Debian 10 |
| `ubuntu:20.04` / `debian:11` | 2.31 | Ubuntu 20.04, Debian 11 |

Unverified, and the reason this is a note rather than a change:
`julia-actions/setup-julia` may not work inside a container job, so Julia would
be installed with `curl` in a step; the image needs a working `cc` and binutils
for PackageCompiler (the manylinux images have them); and the resulting floor
must be *measured* with the same `objdump -T | grep GLIBC_` check rather than
assumed. There is no Docker in the review container, so none of this could be
tested here.

Independent of the release chain - it changes only how the Linux asset is
built, not what it contains.
