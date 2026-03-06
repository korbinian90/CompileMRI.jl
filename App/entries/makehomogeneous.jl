include(joinpath(@__DIR__, "..", "src", "App.jl"))

function @main(args::Vector{String})::Cint
    return App.makehomogeneous()
end
