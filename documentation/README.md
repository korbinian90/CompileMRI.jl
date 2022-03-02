# Executables
The folder `bin` contains the executable `romeo`, `clearswi` and `mcpc3ds`

# Help
Help for the individual commands can be printed via the command line, e.g.:

```bash
$ bin/romeo --help
```

# Publications
Please cite the related publications in your research:

**ROMEO**

Dymerska, B., Eckstein, K., Bachrata, B., Siow, B., Trattnig, S., Shmueli, K., Robinson, S.D., 2020.
Phase Unwrapping with a Rapid Opensource Minimum Spanning TreE AlgOrithm (mritools). Magnetic Resonance in Medicine. https://doi.org/10.1002/mrm.28563

**MCPC-3D-S Coil Combination**

Eckstein, K., Dymerska, B., Bachrata, B., Bogner, W., Poljanc, K., Trattnig, S., Robinson, S.D., 2018.
Computationally Efficient Combination of Multi-channel Phase Data From Multi-echo Acquisitions (ASPIRE). Magnetic Resonance in Medicine 79, 2996–3006. https://doi.org/10.1002/mrm.26963

**CLEAR-SWI**

Eckstein, K., Bachrata, B., Hangel, G., Widhalm, G., Enzinger, C., Barth, M., Trattnig, S., Robinson, S., 2021.
Improved susceptibility weighted imaging at ultra-high field using bipolar multi-echo acquisition and optimized image processing: CLEAR-SWI,
NeuroImage, Volume 237, https://doi.org/10.1016/j.neuroimage.2021.118175

# MATLAB
For `romeo` and `clearswi`, Matlab scripts are provided. They internally call the same commandline programs.

# Julia
The programs are written in [julia](https://julialang.org/) and are available open-source:
https://github.com/korbinian90/MriResearchTools.jl
https://github.com/korbinian90/ROMEO.jl
https://github.com/korbinian90/CLEARSWI.jl

# Bug Reports
Please post bug reports as issues on https://github.com/korbinian90/CompileMRI.jl/issues (or one of the related github packages)

# Feature Requests
Feature requests are welcome for discussion as issues on github!
