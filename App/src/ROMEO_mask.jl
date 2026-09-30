module RomeoMasking

using MriResearchTools
using ROMEO
using ..Common
import ..Common: CLI, one, many, flag, format_scalar_or_vector

export romeo_mask_main

const OPTIONS = [
    CLI.Option("--phase", "-p", "The phase image that should be unwrapped"),
    CLI.Option("--magnitude", "-m", "The magnitude image (better unwrapping if specified)"),
    CLI.Option("--output", "-o", "The output path or filename (default: unwrapped.nii)"),
    CLI.Option("--factor", "-f", "Factor to adjust the masking threshold in [0;1] (default: 0.1)"),
    CLI.Option("--echo-times", "-t", """The echo times in [ms]
        specified in array or range syntax (eg. "[1.5,3.0]" or
        "3.5:3.5:14"). For identical echo times, "-t epi" can be
        used"""; nargs=:many),
    CLI.Option("--unwrap-echoes", "-e", "Load only the specified echoes from disk (default: :)"; nargs=:many),
    CLI.Option("--weights", "-w", """romeo | romeo2 | romeo3 | romeo4 | romeo6 |
        bestpath | <4d-weights-file> | <flags>.
        <flags> are up to 6 bits to activate individual weights
        (eg. "1010"). The weights are (1)phasecoherence
        (2)phasegradientcoherence (3)phaselinearity (4)magcoherence
        (5)magweight (6)magweight2 (default: romeo)"""),
    CLI.Option("--no-phase-rescale", "", """Deactivate rescaling of input phase. By default the
        input phase is rescaled to the range [-π;π]. This option
        allows inputting already unwrapped phase images without
        manually wrapping them first."""; nargs=:none),
    CLI.Option("--fix-ge-phase", "", """GE systems write corrupted phase output (slice jumps).
        This option fixes the phase problems."""; nargs=:none),
    CLI.Option("--verbose", "-v", "verbose output messages"; nargs=:none),
    CLI.Option("--write-quality", "-q", """Writes out the ROMEO quality map as a 3D image with one
        value per voxel"""; nargs=:none),
    CLI.Option("--write-quality-all", "-Q", """Writes out an individual quality map for each of the
        ROMEO weights."""; nargs=:none),
]

# The command line, resolved. The fields after `write_quality_all` are filled in
# while running and end up in the settings record.
Base.@kwdef mutable struct Options
    phase::String = ""
    magnitude::String = ""
    output::String = "unwrapped.nii"
    factor::Float64 = 0.1
    echo_times::Vector{String} = String[]
    unwrap_echoes::Vector{String} = [":"]
    weights::String = "romeo"
    no_phase_rescale::Bool = false
    fix_ge_phase::Bool = false
    verbose::Bool = false
    write_quality::Bool = false
    write_quality_all::Bool = false
    filename::String = "mask"
    number_of_echoes::Int = 0
    echoes::Vector{Int} = Int[]
    TEs::Union{Vector{Int},Vector{Float64}} = Int[]
end

function Options(v::CLI.Values)
    return Options(;
        phase = one(v, "phase", ""),
        magnitude = one(v, "magnitude", ""),
        output = one(v, "output", "unwrapped.nii"),
        factor = parse(Float64, one(v, "factor", "0.1")),
        echo_times = many(v, "echo-times", String[]),
        unwrap_echoes = many(v, "unwrap-echoes", [":"]),
        weights = one(v, "weights", "romeo"),
        no_phase_rescale = flag(v, "no-phase-rescale"),
        fix_ge_phase = flag(v, "fix-ge-phase"),
        verbose = flag(v, "verbose"),
        write_quality = flag(v, "write-quality"),
        write_quality_all = flag(v, "write-quality-all"),
    )
end

function getargs(args::AbstractVector, version)
    if isempty(args)
        args = ["--help"]
    else
        # startswith, not `'-' in`: a hyphen anywhere in the filename used to
        # make this look like a flag, so BIDS names were rejected as stray
        # positionals. Same fix as ROMEO.jl's getargs.
        if !startswith(args[1], '-')
            prepend!(args, Ref("-p"))
        end # if phase is first without -p
        if length(args) >= 2 && !("-p" in args || "--phase" in args) && !startswith(args[end-1], '-') # if phase is last without -p
            insert!(args, length(args), "-p")
        end
    end
    values = CLI.parse(CLI.Spec("romeo_mask", string(version), OPTIONS), args)
    values === nothing && return nothing
    return Options(values)
end

function romeo_mask_main(args; version="App 1.0")
    opts = Common.parse_command(getargs, "romeo_mask", args, version)
    opts isa Options || return opts === nothing ? 0 : opts
    phase, mag, hdr = load_data_and_resolve_args!(opts)

    mkpath(opts.output)
    saveconfiguration(opts, args, version)

    # A single echo is masked as 3D data, several echoes as 4D data.
    if length(opts.echoes) == 1
        mask_and_write(opts, select_echo(phase, opts.echoes[1]), select_echo(mag, opts.echoes[1]), hdr)
    else
        mask_and_write(opts, select_echoes(phase, opts.echoes), select_echoes(mag, opts.echoes), hdr)
    end
    return 0
end

select_echo(a::AbstractArray{<:Any,5}, i::Int) = a[:,:,:,i,1]
select_echo(::Nothing, i) = nothing
select_echoes(a::AbstractArray{<:Any,5}, echoes::Vector{Int}) = a[:,:,:,echoes,1]
select_echoes(::Nothing, echoes) = nothing

function load_data_and_resolve_args!(opts::Options)
    opts.filename = "mask"
    if Common.is_nifti_path(opts.output)
        opts.filename = basename(opts.output)
        opts.output = dirname(opts.output)
    end

    if opts.weights == "romeo"
        opts.weights = isempty(opts.magnitude) ? "romeo4" : "romeo3"
    end

    isempty(opts.phase) && error("no phase image given (-p)")
    phase, hdr = loadphase(opts.phase; rescale=!opts.no_phase_rescale, fix_ge=opts.fix_ge_phase)
    opts.verbose && CLI.info("Phase loaded!")
    mag = isempty(opts.magnitude) ? nothing : first(loadmag(opts.magnitude))
    opts.verbose && mag !== nothing && CLI.info("Mag loaded!")

    neco = opts.number_of_echoes = size(phase, 4)

    ## Echoes for unwrapping
    opts.echoes = try
        Common.parse_echoes(opts.unwrap_echoes, neco)
    catch y
        if isa(y, BoundsError)
            error("echoes=$(join(opts.unwrap_echoes, " ")): specified echo out of range! Number of echoes is $neco")
        else
            error("echoes=$(join(opts.unwrap_echoes, " ")) wrongly formatted!")
        end
    end
    opts.verbose && CLI.info("Echoes are " * format_scalar_or_vector(opts.echoes))

    opts.TEs = getTEs(opts, neco, opts.echoes)
    opts.verbose && CLI.info("TEs are " * format_scalar_or_vector(opts.TEs))

    if 1 < length(opts.echoes) && length(opts.echoes) != length(opts.TEs)
        error("Number of chosen echoes is $(length(opts.echoes)) ($neco in .nii data), but $(length(opts.TEs)) TEs were specified!")
    end

    if mag !== nothing && (Common.size3(mag) != Common.size3(phase) || size(mag, 4) < maximum(opts.echoes))
        error("size of magnitude and phase does not match!")
    end

    return phase, mag, hdr
end

function getTEs(opts::Options, neco, echoes)
    if isempty(opts.echo_times)
        if neco == 1 || length(echoes) == 1
            return [1]
        else
            error("multi-echo data is used, but no echo times are given. Please specify the echo times using the -t option.")
        end
    end
    TEs = if opts.echo_times[1] == "epi"
        ones(neco) .* (length(opts.echo_times) > 1 ? parse(Float64, opts.echo_times[2]) : 1.0)
    else
        Common.parse_numbers(opts.echo_times)
    end
    if 1 < length(TEs) == neco
        TEs = TEs[echoes]
    end
    return TEs
end

function parseweights(opts::Options)
    w = opts.weights
    if isfile(w) && any(==('.'), basename(w))
        weights, _ = loadnii(w)
        return UInt8.(Common.as4d(weights))
    end
    flags = MriResearchTools.parse_weight_flags(w)
    return flags === nothing ? Symbol(w) : flags
end

# The magnitude, the weights and the echo times each have several possible
# types. They are split one at a time, so that every call below them has static
# types and a compiled program does not need dynamic dispatch.
function mask_and_write(opts::Options, phase, mag, hdr)
    weights = parseweights(opts)
    TEs = opts.TEs
    if TEs isa Vector{Int}
        mask_and_write(opts, phase, mag, weights, TEs, hdr)
    else
        mask_and_write(opts, phase, mag, weights, TEs, hdr)
    end
end

function mask_and_write(opts::Options, phase, mag, weights, TEs, hdr)
    keyargs = mag === nothing ? (; TEs, weights) : (; mag, TEs, weights)
    qmap = voxelquality(phase; keyargs...)
    mask = robustmask(qmap; threshold=opts.factor)
    save(mask, "mask", opts, hdr)
    write_qualitymap(opts, phase, keyargs, hdr)
end

function write_qualitymap(opts::Options, phase, keyargs, hdr)
    # no mask used for writing quality maps
    if opts.write_quality
        opts.verbose && CLI.info("Calculate and write quality map...")
        save(voxelquality(phase; keyargs...), "quality", opts, hdr)
    end
    if opts.write_quality_all
        for i in 1:6
            flags = falses(6)
            flags[i] = true
            opts.verbose && CLI.info("Calculate and write quality map $i...")
            qm = voxelquality(phase; keyargs..., weights=flags)
            if all(qm[1:end-1, 1:end-1, 1:end-1] .== 1.0)
                opts.verbose && CLI.info("quality map $i skipped for the given inputs")
            else
                save(qm, "quality_$i", opts, hdr)
            end
        end
    end
end

save(image, name, opts::Options, hdr) = savenii(image, name, opts.output, hdr)

function saveconfiguration(opts::Options, args, version)
    f = CLI.format
    settings = Dict{String,String}(
        "phase" => f(opts.phase),
        "magnitude" => f(opts.magnitude),
        "output" => f(opts.output),
        "factor" => f(opts.factor),
        "echo-times" => f(opts.echo_times),
        "unwrap-echoes" => f(opts.unwrap_echoes),
        "weights" => f(opts.weights),
        "no-phase-rescale" => f(opts.no_phase_rescale),
        "fix-ge-phase" => f(opts.fix_ge_phase),
        "verbose" => f(opts.verbose),
        "write-quality" => f(opts.write_quality),
        "write-quality-all" => f(opts.write_quality_all),
        "filename" => f(opts.filename),
        "number-of-echoes" => f(opts.number_of_echoes),
        "echoes" => format_scalar_or_vector(opts.echoes),
        "TEs" => format_scalar_or_vector(opts.TEs),
    )
    # The mask is a threshold on the ROMEO voxel quality map.
    write_provenance(abspath(opts.output), "romeo_mask";
        version, args, settings, cite = [:romeo],
        optional = [:phase_based_masking, :qsmxt, :julia],
        inputs = Pair{String,Union{Nothing,String}}["phase" => opts.phase, "magnitude" => (isempty(opts.magnitude) ? nothing : opts.magnitude)],
        packages = [MriResearchTools, MriResearchTools.ROMEO],
        describe = describe_input,
    )
end

end
