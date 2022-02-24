using Pkg
Pkg.activate(joinpath(dirname(@__DIR__), "App"))
# registered
Pkg.add("ArgParse")
Pkg.add("MriResearchTools")
# unregistered
Pkg.add(PackageSpec(;url="https://github.com/korbinian90/CLEARSWI.jl"))
Pkg.add(PackageSpec(;url="https://github.com/korbinian90/ClearswiApp.jl"))
Pkg.add(PackageSpec(;url="https://github.com/korbinian90/RomeoApp.jl"))
