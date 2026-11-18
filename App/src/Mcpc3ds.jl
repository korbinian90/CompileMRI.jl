module Mcpc3dsApp

using MriResearchTools
using ..Common
import ..Common: CLI, one, many, flag

export mcpc3ds_main

const OPTIONS = [
    CLI.Option("--magnitude", "-m", "The magnitude image (single or multi-echo)"),
    CLI.Option("--phase", "-p", "The phase image (single or multi-echo)"),
    CLI.Option("--output", "-o", "The output path or filename (default: output)"),
    CLI.Option("--echo-times", "-t", """The echo times are required for multi-echo datasets
        specified in array or range syntax (eg. "[1.5,3.0]" or
        "3.5:3.5:14")."""; nargs=:many),
    CLI.Option("--smoothing-sigma", "-s", """Size of gaussian smoothing in voxels applied to the phase offsets.
        If set to [0,0,0], no smoothing will be performed. Defaults to [10,10,5]"""; nargs=:many),
    CLI.Option("--bipolar", "-b", """If set it removes eddy current
        artefacts (requires >= 3 echoes)."""; nargs=:none),
    CLI.Option("--write-phase-offsets", "", """Saves the estimated phase offsets to the output folder."""; nargs=:none),
    CLI.Option("--no-mmap", "-N", """Deactivate memory mapping. Memory mapping might cause
        problems on network storage"""; nargs=:none),
    CLI.Option("--no-phase-rescale", "", """Deactivate automatic rescaling of phase images. By
        default the input phase is rescaled to the range [-π;π]."""; nargs=:none),
    CLI.Option("--fix-ge-phase", "", """GE systems write corrupted phase output (slice jumps).
        This option fixes the phase problems."""; nargs=:none),
    CLI.Option("--writesteps", "", """Set to the path of a folder, if intermediate steps should
        be saved."""),
    CLI.Option("--verbose", "-v", "verbose output messages"; nargs=:none),
]

Base.@kwdef struct Options
    magnitude::String = ""
    phase::String = ""
    output::String = "output"
    echo_times::Vector{String} = String[]
    smoothing_sigma::Vector{String} = String[]
    bipolar::Bool = false
    write_phase_offsets::Bool = false
    no_mmap::Bool = false
    no_phase_rescale::Bool = false
    fix_ge_phase::Bool = false
    writesteps::String = ""
    verbose::Bool = false
end

function Options(v::CLI.Values)
    return Options(;
        magnitude = one(v, "magnitude", ""),
        phase = one(v, "phase", ""),
        output = one(v, "output", "output"),
        echo_times = many(v, "echo-times", String[]),
        smoothing_sigma = many(v, "smoothing-sigma", String[]),
        bipolar = flag(v, "bipolar"),
        write_phase_offsets = flag(v, "write-phase-offsets"),
        no_mmap = flag(v, "no-mmap"),
        no_phase_rescale = flag(v, "no-phase-rescale"),
        fix_ge_phase = flag(v, "fix-ge-phase"),
        writesteps = one(v, "writesteps", ""),
        verbose = flag(v, "verbose"),
    )
end

function getargs(args::AbstractVector, version)
    isempty(args) && (args = ["--help"])
    values = CLI.parse(CLI.Spec("mcpc3ds", string(version), OPTIONS), args)
    values === nothing && return nothing
    return Options(values)
end

function mcpc3ds_main(args; version="1.0")
    opts = Common.parse_command(getargs, "mcpc3ds", args, version)
    opts isa Options || return opts === nothing ? 0 : opts
    run_mcpc3ds(opts, args, version)
    return 0
end

function run_mcpc3ds(opts::Options, args, version)
    writedir, _ = Common.split_output(opts.output, "combined")
    sigma = isempty(opts.smoothing_sigma) ? [10, 10, 5] : Common.parse_numbers(opts.smoothing_sigma)

    mkpath(writedir)
    saveconfiguration(writedir, opts, sigma, args, version)

    isempty(opts.phase) && error("no phase image given (-p)")
    phase, hdr = loadphase(opts.phase; rescale=!opts.no_phase_rescale, fix_ge=opts.fix_ge_phase)
    neco = size(phase, 4)

    ## Perform phase offset correction
    TEs = getTEs(opts)
    if neco != length(TEs) error("Phase offset determination requires all echo times!") end
    if TEs[1] == TEs[2] error("The echo times need to be different for MCPC3D-S phase offset correction!") end
    polarity = opts.bipolar ? "bipolar" : "monopolar"
    opts.verbose && CLI.info("perform phase offset correction with MCPC3D-S ($polarity)")

    po = zeros(Float32, (Common.size3(phase)..., size(phase, 5)))
    mag = isempty(opts.magnitude) ? ones(Float32, size(phase)) : first(loadmag(opts.magnitude))
    combined, mcomb = mcpc3ds_typed(phase, mag, TEs, po, opts.bipolar, sigma)
    opts.verbose && CLI.info("Saving corrected_phase and phase_offset")
    savenii(combined, "combined_phase", writedir, hdr)
    savenii(mcomb, "combined_mag", writedir, hdr)
    opts.write_phase_offsets && savenii(po, "phase_offset", writedir, hdr)
end

# positional arguments are split by type where keyword arguments are not
mcpc3ds_typed(phase, mag, TEs, po, bipolar_correction, sigma) =
    MriResearchTools.mcpc3ds(phase, mag; TEs, po, bipolar_correction, sigma)

function getTEs(opts::Options)
    if isempty(opts.echo_times)
        error("No echo times are given. Please specify the echo times using the -t option.")
    end
    return Common.parse_numbers(opts.echo_times)
end

function saveconfiguration(writedir, opts::Options, sigma, args, version)
    f = CLI.format
    settings = Dict{String,String}(
        "magnitude" => f(opts.magnitude),
        "phase" => f(opts.phase),
        "output" => f(opts.output),
        "echo-times" => f(opts.echo_times),
        "smoothing-sigma" => f(sigma), # what was used
        "bipolar" => f(opts.bipolar),
        "write-phase-offsets" => f(opts.write_phase_offsets),
        "no-mmap" => f(opts.no_mmap),
        "no-phase-rescale" => f(opts.no_phase_rescale),
        "fix-ge-phase" => f(opts.fix_ge_phase),
        "writesteps" => f(opts.writesteps),
        "verbose" => f(opts.verbose),
    )
    # MCPC-3D-S is the method this tool exists to run, so it is always cited.
    write_provenance(abspath(writedir), "mcpc3ds";
        version, args, settings, cite = [:mcpc3ds],
        optional = [:romeo, :julia],
        inputs = Pair{String,Union{Nothing,String}}["phase" => nothing_if_empty(opts.phase), "magnitude" => nothing_if_empty(opts.magnitude)],
        packages = [MriResearchTools, MriResearchTools.ROMEO],
        describe = describe_input,
    )
end

nothing_if_empty(s::String) = isempty(s) ? nothing : s

end
