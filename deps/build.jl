using Pkg
Pkg.activate(joinpath(dirname(@__DIR__), "App"))
# registered
Pkg.add(["ArgParse", "MriResearchTools", "ROMEO"])
# unregistered
Pkg.add([PackageSpec(;url="https://github.com/korbinian90/CLEARSWI.jl"))
Pkg.add(PackageSpec(;url="https://github.com/korbinian90/ClearswiApp.jl"))
