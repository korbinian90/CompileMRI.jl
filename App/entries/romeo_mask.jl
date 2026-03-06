include(joinpath(@__DIR__, "..", "src", "App.jl"))

function julia_main()::Cint
    return App.romeo_mask()
end
