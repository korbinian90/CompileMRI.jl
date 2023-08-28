import Pkg
Pkg.activate(joinpath(dirname(@__DIR__), "App"))
Pkg.instantiate()
