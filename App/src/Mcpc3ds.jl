module Mcpc3dsApp
using MriResearchTools
using ArgParse

function getargs(args::AbstractVector, version)
    if isempty(args)
        args = ["--help"]
    end
    s = ArgParseSettings(
        exc_handler=exception_handler,
        add_version=true,
        version,
        )
    @add_arg_table! s begin
        "--magnitude", "-m"
            help = "The magnitude image (single or multi-echo)"
        "--phase", "-p"
            help = "The phase image (single or multi-echo)"
        "--output", "-o"
            help = "The output path or filename"
            default = "output"
        "--echo-times", "-t"
            help = """The echo times are required for multi-echo datasets 
                specified in array or range syntax (eg. "[1.5,3.0]" or 
                "3.5:3.5:14")."""
            nargs = '+'
        "--smoothing-sigma", "-s"
            help = """Size of gaussian smoothing in voxels applied to the phase offsets.
                If set to [0,0,0], no smoothing will be performed. Defaults to [10,10,5]"""
            nargs = '+'
        "--bipolar", "-b"
            help = """If set it removes eddy current
                artefacts (requires >= 3 echoes)."""
            action = :store_true
        "--write-phase-offsets"
            help = """Saves the estimated phase offsets to the output folder.
                This reduces the RAM requirement if memory mapping is activated."""
            action = :store_true
        "--no-mmap", "-N"
            help = """Deactivate memory mapping. Memory mapping might cause
                problems on network storage"""
            action = :store_true
        "--no-phase-rescale"
            help = """Deactivate automatic rescaling of phase images. By
                default the input phase is rescaled to the range [-π;π]."""
            action = :store_true
        "--writesteps"
            help = """Set to the path of a folder, if intermediate steps should
                be saved."""
            default = nothing
        "--verbose", "-v"
            help = "verbose output messages"
            action = :store_true
    end
    return parse_args(args, s)
end

function julia_main()::Cint
    try
        mcpc3ds_main(ARGS)
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0
end

function mcpc3ds_main(args)
    version = "1.0.0"

    settings = getargs(args, version)
    
    writedir = settings["output"]
    filename = "combined"
    if occursin(r"\.nii$", writedir)
        filename = basename(writedir)
        writedir = dirname(writedir)
    end

    σ = [10,10,5]
    if !isempty(settings["smoothing-sigma"])
        σ = parse_array(settings["smoothing-sigma"])
    end

    mkpath(writedir)
    saveconfiguration(writedir, settings, args, version)

    phase = readphase(settings["phase"], mmap=!settings["no-mmap"], rescale=!settings["no-phase-rescale"])
    hdr = header(phase)
    neco = size(phase, 4)

    ## Perform phase offset correction
    TEs = getTEs(settings)
    if neco != length(TEs) error("Phase offset determination requires all echo times!") end
    if TEs[1] == TEs[2] error("The echo times need to be different for MCPC3D-S phase offset correction!") end
    polarity = if settings["bipolar"] "bipolar" else "monopolar" end
    settings["verbose"] && println("perform phase offset correction with MCPC3D-S ($polarity)")
    
    po_size = (size(phase)[1:3]...,size(phase,5))
    po_type = promote_type(eltype(phase), Float32) # use at least Float32 as type (no Int)
    po = if settings["no-mmap"] || !settings["write-phase-offsets"]
        zeros(eltype(phase), po_size)
    else
        write_emptynii(po_size, joinpath(writedir, "phase_offset.nii"); datatype=po_type, header=hdr)
    end
    mag = if !isnothing(settings["magnitude"]) readmag(settings["magnitude"], mmap=!settings["no-mmap"]) else ones(size(phase)) end # TODO trues instead ones?
    bipolar_correction = settings["bipolar"]
    phase, mcomb = MriResearchTools.mcpc3ds(phase, mag; TEs, po, bipolar_correction, σ)
    settings["verbose"] && println("Saving corrected_phase and phase_offset")
    savenii(phase, "combined_phase", writedir, hdr)
    savenii(mcomb, "combined_mag", writedir, hdr)
    settings["write-phase-offsets"] && settings["no-mmap"] && savenii(po, "phase_offset", writedir, hdr)
    return 0
end

function exception_handler(settings::ArgParseSettings, err, err_code::Int=1)
    if err == ArgParseError("too many arguments")
        println(stderr,
            """wrong argument formatting!"""
        )
    end
    ArgParse.default_handler(settings, err, err_code)
end

function getTEs(settings)
    if isempty(settings["echo-times"])
        error("No echo times are given. Please specify the echo times using the -t option.")
    end
    TEs = parse_array(settings["echo-times"])
    return TEs
end

function parse_array(str)
    arr = eval(Meta.parse(join(str, " ")))
    if arr isa Matrix
        arr = arr[:]
    end
    return arr
end

function saveconfiguration(writedir, settings, args, version)
    writedir = abspath(writedir)
    open(joinpath(writedir, "settings_mcpc3ds.txt"), "w") do io
        for (fname, val) in settings
            if !(typeof(val) <: AbstractArray)
                println(io, "$fname: " * string(val))
            end
        end
        println(io, """Arguments: $(join(args, " "))""")
        println(io, "Mcpc3dsApp version: $version")
    end
end

export mcpc3ds_main

end