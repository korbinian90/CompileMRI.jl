module RomeoMasking

using MriResearchTools
using ROMEO
using ArgParse

export romeo_mask_main

function romeo_mask_main(args; version="App 1.0")
    settings = getargs(args, version)
    data = load_data_and_resolve_args!(settings)

    mkpath(settings["output"])
    saveconfiguration(settings["output"], settings, args, version)

    select_echoes!(data, settings)

    calculate_mask!(data, settings)

    keyargs = get_keyargs(settings, data)

    write_qualitymap(settings, data, keyargs)

    return 0
end

function getargs(args::AbstractVector, version)
    if isempty(args)
        args = ["--help"]
    else
        if !('-' in args[1])
            prepend!(args, Ref("-p"))
        end # if phase is first without -p
        if length(args) >= 2 && !("-p" in args || "--phase" in args) && !('-' in args[end-1]) # if phase is last without -p
            insert!(args, length(args), "-p")
        end
    end
    s = ArgParseSettings(;
        exc_handler=exception_handler,
        add_version=true,
        version,
    )
    @add_arg_table! s begin
        "--phase", "-p"
            help = "The phase image that should be unwrapped"
        "--magnitude", "-m"
            help = "The magnitude image (better unwrapping if specified)"
        "--output", "-o"
            help = "The output path or filename"
            default = "unwrapped.nii"
        "--factor", "-f"
            help = "Factor to adjust the masking threshold in [0;1]"
            default = 0.1
        "--echo-times", "-t"
            help = """The echo times in [ms]  
                specified in array or range syntax (eg. "[1.5,3.0]" or 
                "3.5:3.5:14"). For identical echo times, "-t epi" can be
                used"""
            nargs = '+'
        "--unwrap-echoes", "-e"
            help = "Load only the specified echoes from disk"
            default = [":"]
            nargs = '+'
        "--weights", "-w"
            help = """romeo | romeo2 | romeo3 | romeo4 | romeo6 |
                bestpath | <4d-weights-file> | <flags>.
                <flags> are up to 6 bits to activate individual weights
                (eg. "1010"). The weights are (1)phasecoherence
                (2)phasegradientcoherence (3)phaselinearity (4)magcoherence
                (5)magweight (6)magweight2"""
            default = "romeo"
        "--no-phase-rescale"
            help = """Deactivate rescaling of input phase. By default the
                input phase is rescaled to the range [-π;π]. This option
                allows inputting already unwrapped phase images without
                manually wrapping them first."""
            action = :store_true
        "--fix-ge-phase"
            help = """GE systems write corrupted phase output (slice jumps).
                This option fixes the phase problems."""
            action = :store_true
        "--verbose", "-v"
            help = "verbose output messages"
            action = :store_true
        "--write-quality", "-q"
            help = """Writes out the ROMEO quality map as a 3D image with one
                value per voxel"""
            action = :store_true
        "--write-quality-all", "-Q"
            help = """Writes out an individual quality map for each of the
                ROMEO weights."""
            action = :store_true
    end
    return parse_args(args, s)
end

function exception_handler(settings::ArgParseSettings, err, err_code::Int=1)
    if err == ArgParseError("too many arguments")
        println(stderr,
            """wrong argument formatting!"""
        )
    end
    ArgParse.default_handler(settings, err, err_code)
end

function getechoes(settings, neco)
    echoes = eval(Meta.parse(join(settings["unwrap-echoes"], " ")))
    if echoes isa Int
        echoes = [echoes]
    elseif echoes isa Matrix
        echoes = echoes[:]
    end
    echoes = (1:neco)[echoes] # expands ":"
    if (length(echoes) == 1)
        echoes = echoes[1]
    end
    return echoes
end

function getTEs(settings, neco, echoes)
    if isempty(settings["echo-times"])
        if neco == 1 || length(echoes) == 1
            return 1
        else
            error("multi-echo data is used, but no echo times are given. Please specify the echo times using the -t option.")
        end
    end
    TEs = if settings["echo-times"][1] == "epi"
        ones(neco) .* if length(settings["echo-times"]) > 1
            parse(Float64, settings["echo-times"][2])
        else
            1
        end
    else
        eval(Meta.parse(join(settings["echo-times"], " ")))
    end
    if TEs isa AbstractMatrix
        TEs = TEs[:]
    end
    if 1 < length(TEs) == neco
        TEs = TEs[echoes]
    end
    return TEs
end

function parseweights(settings)
    if isfile(settings["weights"]) && splitext(settings["weights"])[2] != ""
        return UInt8.(niread(settings["weights"]))
    else
        try
            reform = "Bool[$(join(collect(settings["weights"]), ','))]"
            flags = falses(6)
            flags_tmp = eval(Meta.parse(reform))
            flags[1:length(flags_tmp)] = flags_tmp
            return flags
        catch
            return Symbol(settings["weights"])
        end
    end
end

function saveconfiguration(writedir, settings, args, version)
    writedir = abspath(writedir)
    open(joinpath(writedir, "settings_romeo_mask.txt"), "w") do io
        for (fname, val) in settings
            if !(val isa AbstractArray || fname == "header")
                println(io, "$fname: " * string(val))
            end
        end
        println(io, """Arguments: $(join(args, " "))""")
        println(io, "RomeoMask version: $version")
    end
    open(joinpath(writedir, "citations_romeo_mask.txt"), "w") do io
        println(io, "# If you use this software, please cite:")
        println(io)
        println(io, """Dymerska, B., Eckstein, K., Bachrata, B., Siow, B., Trattnig, S., Shmueli, K., Robinson, S.D., 2020.
                    Phase Unwrapping with a Rapid Opensource Minimum Spanning TreE AlgOrithm (ROMEO).
                    Magnetic Resonance in Medicine.
                    https://doi.org/10.1002/mrm.28563""")
        println(io)
        
        println(io)
        println(io, "# Optional citations:")
        println(io)
        println(io, """Hagberg, G.E., Eckstein, K., Tuzzi, E., Zhou, J., Robinson, S.D., Scheffler, K., 2022.
                    Phase-based masking for quantitative susceptibility mapping of the human brain at 9.4T.
                    Magnetic Resonance in Medicine.
                    https://doi.org/10.1002/mrm.29368""")
        println(io)
        println(io, """Stewart, A.W., Robinson, S.D., O'Brien, K., Jin, J., Widhalm, G., Hangel, G., Walls, A., Goodwin, J., Eckstein, K., Tourell, M., Morgan, C., Narayanan, A., Barth, M., Bollmann, S., 2022.
                    QSMxT: Robust masking and artifact reduction for quantitative susceptibility mapping.
                    Magnetic Resonance in Medicine.
                    https://doi.org/10.1002/mrm.29048""")
        println(io)
        println(io, """Bezanson, J., Edelman, A., Karpinski, S., Shah, V.B., 2017.
                    Julia: A fresh approach to numerical computing
                    SIAM Review 59, 65--98
                    https://doi.org/10.1137/141000671""")
    end
end

function load_data_and_resolve_args!(settings)
    settings["filename"] = "mask"
    if endswith(settings["output"], ".nii") || endswith(settings["output"], ".nii.gz")
        settings["filename"] = basename(settings["output"])
        settings["output"] = dirname(settings["output"])
    end

    if settings["weights"] == "romeo"
        if isnothing(settings["magnitude"])
            settings["weights"] = "romeo4"
        else
            settings["weights"] = "romeo3"
        end
    end

    data = Dict{String,AbstractArray}()
    phase = readphase(settings["phase"]; rescale=!settings["no-phase-rescale"], fix_ge=settings["fix-ge-phase"])
    settings["verbose"] && println("Phase loaded!")
    if !isnothing(settings["magnitude"])
        data["mag"] = readmag(settings["magnitude"])
        settings["verbose"] && println("Mag loaded!")
    end

    settings["header"] = header(data["phase"])
    settings["neco"] = size(data["phase"], 4)

    ## Echoes for unwrapping
    settings["echoes"] = try
        getechoes(settings, settings["neco"])
    catch y
        if isa(y, BoundsError)
            error("echoes=$(join(settings["unwrap-echoes"], " ")): specified echo out of range! Number of echoes is $(settings["neco"])")
        else
            error("echoes=$(join(settings["unwrap-echoes"], " ")) wrongly formatted!")
        end
    end
    settings["verbose"] && println("Echoes are $(settings["echoes"])")

    settings["TEs"] = getTEs(settings, settings["neco"], settings["echoes"])
    settings["verbose"] && println("TEs are $(settings["TEs"])")

    if 1 < length(settings["echoes"]) && length(settings["echoes"]) != length(settings["TEs"])
        error("Number of chosen echoes is $(length(settings["echoes"])) ($(settings["neco"]) in .nii data), but $(length(settings["TEs"])) TEs were specified!")
    end

    if haskey(data, "mag") && (size.(Ref(data["mag"]), 1:3) != size.(Ref(data["phase"]), 1:3) || size(data["mag"], 4) < maximum(settings["echoes"]))
        error("size of magnitude and phase does not match!")
    end

    return data
end

function get_keyargs(settings, data)
    keyargs = Dict{Symbol,Any}()

    if haskey(data, "mag")
        keyargs[:mag] = data["mag"]
    end

    keyargs[:TEs] = settings["TEs"]
    keyargs[:weights] = parseweights(settings)

    return keyargs
end

function select_echoes!(data, settings)
    data["phase"] = data["phase"][:, :, :, settings["echoes"]]
    if haskey(data, "mag")
        data["mag"] = data["mag"][:, :, :, settings["echoes"]]
    end
end

function calculate_mask!(data, settings)
    qmap = voxelquality(data["phase"]; get_keyargs(settings, data)...)
    data["mask"] = robustmask(qmap; threshold=settings["factor"])
    save(data["mask"], "mask", settings)
end

function write_qualitymap(settings, data, keyargs)
    # no mask used for writing quality maps
    if settings["write-quality"]
        settings["verbose"] && println("Calculate and write quality map...")
        save(voxelquality(data["phase"]; keyargs...), "quality", settings)
    end
    if settings["write-quality-all"]
        for i in 1:6
            flags = falses(6)
            flags[i] = true
            settings["verbose"] && println("Calculate and write quality map $i...")
            qm = voxelquality(data["phase"]; keyargs..., weights=flags)
            if all(qm[1:end-1, 1:end-1, 1:end-1] .== 1.0)
                settings["verbose"] && println("quality map $i skipped for the given inputs")
            else
                save(qm, "quality_$i", settings)
            end
        end
    end
end

save(image, name, settings::Dict) = savenii(image, name, settings["output"], settings["header"])

end