module App

using MriResearchTools
using ArgParse
import ROMEO: unwrapping_main
import ClearswiApp

include("Mcpc3ds.jl")

const version = "4.0.0"

function romeo()::Cint
    try
        unwrapping_main(ARGS; version)
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0
end

clearswi() = ClearswiApp.julia_main(version)

function mcpc3ds()::Cint
    try
        mcpc3ds_main(ARGS; version)
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0
end

export romeo, clearswi, mcpc3ds
# add romeo_mask, intensity_correction
end # module
