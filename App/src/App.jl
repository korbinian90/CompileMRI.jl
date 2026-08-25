module App

using MriResearchTools
using ArgParse
using QuantitativeSusceptibilityMappingTGV
import ROMEO: unwrapping_main
import CLEARSWI: clearswi_main

include("Mcpc3ds.jl")
include("HomogeneityCorrection.jl")
include("ROMEO_mask.jl")
import .Mcpc3dsApp: mcpc3ds_main
import .HomogeneityCorrection: makehomogeneous_main
import .RomeoMasking: romeo_mask_main

# App/Project.toml is the single source of truth for the version. Read here at
# precompile time so the value is baked into the sysimage: the compiled app has
# no Project.toml beside it to read at run time. Erroring is deliberate - a
# missing version should stop the build, not silently name the release after
# nothing.
const version = let
    toml = joinpath(@__DIR__, "..", "Project.toml")
    # Without this the value is baked at precompile time and a version bump in
    # Project.toml does not invalidate the cache, so a stale version would be
    # compiled into the app. Verified: editing Project.toml alone left
    # App.version at the old number until this was added.
    include_dependency(toml)
    m = match(r"^version\s*=\s*\"([^\"]+)\""m, read(toml, String))
    m === nothing && error("no version field in $toml")
    String(m.captures[1])
end

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

function romeo_mask()::Cint
    try
        romeo_mask_main(ARGS; version)
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0
end

export romeo, clearswi, mcpc3ds, makehomogeneous, romeo_mask
end # module
