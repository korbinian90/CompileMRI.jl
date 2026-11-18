module HomogeneityCorrection

using MriResearchTools
using ..Common
import ..Common: CLI, one, flag

export makehomogeneous_main

const OPTIONS = [
    CLI.Option("--magnitude", "-m", "The magnitude image (single or multi-echo)"),
    CLI.Option("--output", "-o", "The output path or filename (default: homogenous)"),
    CLI.Option("--sigma-bias-field", "-s", """Sigma size [mm] for smoothing to obtain bias field.
        Takes NIfTI voxel size into account. (default: 7.0)"""),
    CLI.Option("--nbox", "-n", "Number of boxes in each dimension for the box-segmentation step. (default: 15)"),
    CLI.Option("--datatype", "-d", """The datatype of the output image. Defaults to Float32.
        Float types only, e.g. `Float64` - an integer type throws, because the
        corrected magnitude is fractional and the writer does not round."""),
    CLI.Option("--verbose", "-v", "verbose output messages"; nargs=:none),
]

Base.@kwdef struct Options
    magnitude::String = ""
    output::String = "homogenous"
    sigma_bias_field::Float64 = 7.0
    nbox::Int = 15
    datatype::String = ""
    verbose::Bool = false
end

function Options(v::CLI.Values)
    return Options(;
        magnitude = one(v, "magnitude", ""),
        output = one(v, "output", "homogenous"),
        sigma_bias_field = parse(Float64, one(v, "sigma-bias-field", "7.0")),
        nbox = parse(Int, one(v, "nbox", "15")),
        datatype = one(v, "datatype", ""),
        verbose = flag(v, "verbose"),
    )
end

function getargs(args::AbstractVector, version)
    isempty(args) && (args = ["--help"])
    values = CLI.parse(CLI.Spec("makehomogeneous", string(version), OPTIONS), args)
    values === nothing && return nothing
    opts = Options(values)
    parse_datatype(opts.datatype) # a wrong type is a wrong command line
    return opts
end

const DATATYPES = ("Int8" => Int8, "Int16" => Int16, "Int32" => Int32, "Int64" => Int64,
    "Int128" => Int128, "UInt8" => UInt8, "UInt16" => UInt16, "UInt32" => UInt32,
    "UInt64" => UInt64, "UInt128" => UInt128, "Float16" => Float16, "Float32" => Float32,
    "Float64" => Float64, "Bool" => Bool)

function parse_datatype(name::String)::Union{Nothing,DataType}
    isempty(name) && return nothing
    for (n, T) in DATATYPES
        n == name && return T
    end
    throw(ArgumentError("invalid argument: $name (conversion to type DataType failed)"))
end

function makehomogeneous_main(args; version="1.0")
    opts = Common.parse_command(getargs, "makehomogeneous", args, version)
    opts isa Options || return opts === nothing ? 0 : opts
    run_makehomogeneous(opts, args, version)
    return 0
end

function run_makehomogeneous(opts::Options, args, version)
    writedir, filename = Common.split_output(opts.output, "homogenous")
    datatype = parse_datatype(opts.datatype)

    mkpath(writedir)
    saveconfiguration(writedir, opts, args, version)

    isempty(opts.magnitude) && error("no magnitude image given (-m)")
    mag, hdr = loadmag(opts.magnitude)
    nd = Int(hdr.dim[1])
    pixdim = Common.pixdim(hdr, nd)
    if all(pixdim .== 1)
        CLI.info("Warning! All voxel dimensions are 1 in NIfTI header, maybe they are wrong.")
    end
    opts.verbose && size(mag, 4) > 1 && CLI.info("Multi-echo data detected. Using the first echo for sensitivity estimation.")

    sigma = opts.sigma_bias_field ./ pixdim
    nbox = opts.nbox
    # savenii writes Float32 unless told otherwise
    if datatype === nothing
        Common.in_file_dims(mag, nd) do m
            savenii(makehomogeneous!(m; sigma, nbox), filename, writedir, hdr)
        end
    else
        # A closure that captured the type itself would have no static type
        output = OutputType(datatype)
        Common.in_file_dims(mag, nd) do m
            savenii(makehomogeneous!(m; sigma, nbox), filename, writedir, hdr; datatype=output.T)
        end
    end
end

struct OutputType
    T::DataType
end

function saveconfiguration(writedir, opts::Options, args, version)
    f = CLI.format
    settings = Dict{String,String}(
        "magnitude" => f(opts.magnitude),
        "output" => f(opts.output),
        "sigma-bias-field" => f(opts.sigma_bias_field),
        "nbox" => f(opts.nbox),
        "datatype" => isempty(opts.datatype) ? "Float32 (default)" : opts.datatype,
        "verbose" => f(opts.verbose),
    )
    write_provenance(abspath(writedir), "makehomogeneous";
        version, args, settings, cite = [:homogeneity, :clearswi],
        optional = [:julia],
        inputs = Pair{String,Union{Nothing,String}}["magnitude" => (isempty(opts.magnitude) ? nothing : opts.magnitude)],
        packages = [MriResearchTools],
        describe = describe_input,
    )
end

end
