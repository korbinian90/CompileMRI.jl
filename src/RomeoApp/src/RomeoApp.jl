module RomeoApp

using ArgParse
using MriResearchTool

function getargs(args)
    if isempty(args) args = ["--help"] end
    s = ArgParseSettings()
    @add_arg_table s begin
        "phase"
            help = "The phase image used for unwrapping"
        "--magnitude", "-m"
            help = "The magnitude image (better unwrapping if specified)"
        "--output", "-o"
            help = "The output path and filename"
            default = "unwrapped.nii"
        "--echo-times", "-t"
            help = """The relative echo times required for temporal unwrapping (default is 1:n)
                    specified in array or range syntax (eg. [1.5,3.0] or 2:5)"""
        "--mask", "-k"
            help = "<mask_file> | nomask | robustmask"
            default = "robustmask"
        "--individual-unwrapping", "-i"
            help = """Unwraps the echoes individually (not temporal)
                    Temporal unwrapping only works with ASPIRE"""
            action = :store_true
        "--unwrap-echoes", "-e"
            help = "Unwrap only the specified echoes"
            default = ":"
        "--weights", "-w"
            help = "<4d-weights-file> | romeo | bestpath"
            default = "romeo"
        "--compute-B0", "-B"
            help = "EXPERIMENTAL! Calculate combined B0 map in [rad/s]"
            action = :store_true
        "--no-mmap", "-N"
            help = """Deactivate memory mapping.
                    Memory mapping might cause problems on network storage"""
            action = :store_false
        "--threshold", "-T"
            help = """<maximum number of wraps>
                    Threshold the unwrapped phase to the maximum number of wraps
                    Sets values to 0"""
            default = Inf
    end
    return parse_args(args, s)
end

function saveconfiguration(writedir, settings, args)
    @show writedir
    open(joinpath(writedir, "settings_romeo.txt"), "w") do io
        for (fname, val) in settings
            if !(typeof(val) <: AbstractArray)
                println(io, "$fname: " * string(val))
            end
        end
        println(io, """Arguments: $(join(args, " "))""")
    end
end

function unwrapping_main(args)
    settings = getargs(args)

    writedir = settings["output"]
    filename = "unwrapped"
    if occursin(r"\.nii$", writedir)
        filename = basename(writedir)
        writedir = dirname(writedir)
    end

    mkpath(writedir)
    saveconfiguration(writedir, settings, args)

    phasenii = readphase(settings["phase"], mmap=!settings["no-mmap"])
    neco = size(phasenii, 4)

    echoes = try
        getechoes(settings, neco)
    catch y
        if isa(y, BoundsError)
            error("echoes=$(settings["unwrap-echoes"]): specified echo out of range! Number of echoes is $neco")
        else
            error("echoes=$(settings["unwrap-echoes"]) wrongly formatted!")
        end
    end

    hdr = copy(phasenii.header)
    hdr.scl_slope = 1
    hdr.scl_inter = 0

    phase = createniiforwriting(phasenii[:,:,:,echoes], filename, writedir; header=hdr, datatype=Float32)
    @show extrema(phase)
    #phase = view(phasenii,:,:,:,echoes)

    keyargs = Dict()
    if settings["magnitude"] != nothing
        keyargs[:mag] = view(readmag(settings["magnitude"], mmap=!settings["no-mmap"]).raw,:,:,:,echoes)
        if size(keyargs[:mag]) != size(phase)
            error("size of magnitude and phase does not match!")
        end
    end

    ## get settings
    if isfile(settings["mask"])
        keyargs[:mask] = niread(settings["mask"]) .!= 0
        if size(keyargs[:mask]) != size(phase)[1:3]
            error("size of mask is $(size(keyargs[:mask])), but it should be $(size(phase)[1:3])!")
        end
    elseif settings["mask"] == "robustmask" && haskey(keyargs, :mag)
        keyargs[:mask] = getrobustmask(keyargs[:mag][:,:,:,1])
        savenii(keyargs[:mask], "mask", writedir, hdr)
    end
    if length(echoes) > 1
        keyargs[:TEs] = getTEs(settings, neco, echoes)
    end
    if isfile(settings["weights"]) && splitext(settings["weights"])[2] != ""
        keyargs[:weights] = UInt8.(niread(settings["weights"]))
    else
        keyargs[:weights] = Symbol(settings["weights"])
    end

    ## Error messages
    if 1 < length(echoes) && length(echoes) != length(keyargs[:TEs])
        error("Number of chosen echoes is $(length(echoes)) ($neco in .nii data), but $(length(keyargs[:TEs])) TEs were specified!")
    end

    if settings["individual-unwrapping"] && length(echoes) > 1
        unwrap_individual!(phase; keyargs...)
    else
        unwrap!(phase; keyargs...)
    end

    if settings["threshold"] != Inf
        max = settings["threshold"] * 2π
        phase[phase .> max] .= 0
        phase[phase .< -max] .= 0
    end

    if settings["compute-B0"]
        if settings["echo-times"] == nothing
            error("echo times are required for B0 calculation! Unwrapping has been performed")
        end
        if !haskey(keyargs, :mag)
            keyargs[:mag] = ones(1,1,1,size(phase,4))
        end
        TEs = reshape(keyargs[:TEs],1,1,1,:)
        B0 = 1000 * sum(phase .* keyargs[:mag]; dims=4)
        B0 ./= sum(keyargs[:mag] .* TEs; dims=4)

        savenii(B0, "B0", writedir, hdr)
    end

    @show writedir
    return 0
end

function getechoes(settings, neco)
    echoes = eval(Meta.parse(settings["unwrap-echoes"]))
    if typeof(echoes) <: Int
        echoes = [echoes]
    end
    echoes = (1:neco)[echoes]
    if length(echoes) == 1 echoes = echoes[1] end
    return echoes
end

function getTEs(settings, neco, echoes)
    if settings["echo-times"] != nothing
        @show TEs = eval(Meta.parse(settings["echo-times"]))
        if length(TEs) == neco
            TEs = TEs[echoes]
        end
    else
        TEs = (1:neco)[echoes]
    end
    return TEs
end

julia_main()::Cint
    try
        unwrapping_main(ARGS)
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0
end

end # module
