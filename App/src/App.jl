module App

import RomeoApp
import ClearswiApp

include("Mcpc3ds.jl")

const version = "3.6.6"
romeo() = RomeoApp.julia_main(version)
clearswi() = ClearswiApp.julia_main(version)
mcpc3ds() = Mcpc3dsApp.julia_main(version)

export romeo, clearswi, mcpc3ds
# add romeo_mask, intensity_correction
end # module
