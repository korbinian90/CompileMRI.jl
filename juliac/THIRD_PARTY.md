# Third-party software in this bundle

mritools itself is MIT licensed, see LICENSE. The bundle also contains:

- The Julia runtime, MIT licensed, see LICENSE_Julia.md, with the runtime
  libraries it loads (on Linux and macOS libstdc++, libgcc_s, libatomic,
  libunwind, zlib, zstd, openlibm, PCRE2, GMP and MPFR; on Windows all libraries
  of the Julia installation). Their licences are listed in
  https://github.com/JuliaLang/julia/blob/master/THIRDPARTY.md.
- FFTW 3 (libfftw3, libfftw3f), which clearswi uses for its Laplacian phase
  unwrapping. FFTW is licensed under the GNU General Public License, version 2
  or later. Its licence text is in `share/julia/artifacts/*/share/licenses/FFTW/`,
  and its source code is available from https://www.fftw.org.
