module App

using MriResearchTools
using ArgParse
using QSM
import ROMEO: unwrapping_main
import CLEARSWI: clearswi_main

include("Mcpc3ds.jl")
include("HomogeneityCorrection.jl")
import .Mcpc3dsApp: mcpc3ds_main
import .HomogeneityCorrection: makehomogeneous_main

const version = "4.0.6"

function romeo()::Cint
    try
        unwrapping_main(ARGS; version)
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0
end

function clearswi()::Cint
    try
        clearswi_main(ARGS; version)
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0
end

function mcpc3ds()::Cint
    try
        mcpc3ds_main(ARGS; version)
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0
end

function makehomogeneous()::Cint
    try
        makehomogeneous_main(ARGS; version)
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0
end

export romeo, clearswi, mcpc3ds, makehomogeneous
# add romeo_mask
end # module
