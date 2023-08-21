using Pkg
Pkg.activate(joinpath(dirname(@__DIR__), "App"))
# registered
Pkg.add(["ArgParse", "MriResearchTools", "ROMEO", "CLEARSWI"])
