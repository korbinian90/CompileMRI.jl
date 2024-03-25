using Pkg
Pkg.activate(joinpath(@__DIR__))
cd(joinpath(@__DIR__))
include("../App/src/App.jl")
using .App.RomeoMasking

magfile = abspath(joinpath(@__DIR__, "data", "small", "Mag.nii"))
phasefile = abspath(joinpath(@__DIR__, "data", "small", "Phase.nii"))

function test_romeo_mask(args)
    file = tempname()
    args = [args..., "-o", file]
    romeo_mask_main(args)
end

args = ["-p", phasefile, "-t", "1:3"]
test_romeo_mask(args)

args = ["-p", phasefile, "-t", "1:3", "-m", magfile]
test_romeo_mask(args)

args = ["-p", phasefile, "-t", "1:3", "-e", "1"]
test_romeo_mask(args)

args = ["-p", phasefile, "-t", "1:3", "-e", "[1, 2]"]
test_romeo_mask(args)

args = ["-p", phasefile, "-t", "1:3", "-w", "romeo4"]
test_romeo_mask(args)

args = ["-p", phasefile, "-t", "1:3", "-w", "bestpath"]
test_romeo_mask(args)

args = ["-p", phasefile, "-t", "1:3", "-w", "100011"]
test_romeo_mask(args)

args = ["-p", phasefile, "-t", "1:3", "--no-rescale"]
test_romeo_mask(args)

args = ["-p", phasefile, "-t", "1:3", "-v"]
test_romeo_mask(args)

args = ["-p", phasefile, "-t", "1:3", "-Q"]
test_romeo_mask(args)

args = ["-p", phasefile, "-t", "1:3", "-q"]
test_romeo_mask(args)
