# CompileMRI

[![Build Status](https://travis-ci.com/korbinian90/CompileMRI.jl.svg?branch=master)](https://travis-ci.com/korbinian90/CompileMRI.jl)

## Getting Started

1. Install Julia

   Please install Julia using the binaries from this page https://julialang.org. (Julia 1.3 or newer is required, some package managers install outdated versions)

2. Install RomeoApp and CompileMRI

   Start Julia (Type julia in the command line or start the installed Julia executable)

   Type the following in the Julia REPL:
   ```julia
   julia> ] # Be sure to type the closing bracket via the keyboard
   # Enters the Julia package manager
   (@v1.4) pkg> add https://github.com/korbinian90/RomeoApp.jl
   (@v1.4) pkg> add https://github.com/korbinian90/CompileMRI.jl
   # All dependencies are installed automatically
   ```

3. Compile ROMEO into a command line binary

   ```julia
   julia> using CompileMRI
   julia> compile_romeo("/tmp/romeo_compiled")
   ```
