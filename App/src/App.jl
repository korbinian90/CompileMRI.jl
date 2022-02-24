module App

import RomeoApp
import ClearswiApp

include("Mcpc3ds.jl")


romeo = RomeoApp.julia_main
clearswi = ClearswiApp.julia_main
mcpc3ds = Mcpc3dsApp.julia_main

export romeo, clearswi, mcpc3ds
# add romeo_mask, intensity_correction
end # module
