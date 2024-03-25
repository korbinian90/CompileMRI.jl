module HomogeneityCorrection

using MriResearchTools
using ArgParse

export makehomogeneous_main

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
        "--output", "-o"
        help = "The output path or filename"
        default = "homogenous"
        "--sigma-bias-field", "-s"
        help = "Sigma size [mm] for smoothing to obtain bias field. Takes NIfTI voxel size into account."
        default = 7.0
        arg_type = Float64
        "--nbox", "-n"
        help = "Number of boxes in each dimension for the box-segmentation step."
        default = 15
        arg_type = Int
        "--datatype", "-d"
        help = """The datatype of the output image. Defaults to input type.
            It might be required to change this to a float output type for integer input types.
            e.g. `Float32`"""
        arg_type = DataType
        "--verbose", "-v"
        help = "verbose output messages"
        action = :store_true
    end
    return parse_args(args, s)
end

function ArgParse.parse_item(::Type{DataType}, x::AbstractString)
    types = Dict(
        "Int8" => Int8,
        "Int16" => Int16,
        "Int32" => Int32,
        "Int64" => Int64,
        "Int128" => Int128,
        "UInt8" => UInt8,
        "UInt16" => UInt16,
        "UInt32" => UInt32,
        "UInt64" => UInt64,
        "UInt128" => UInt128,
        "Float16" => Float16,
        "Float32" => Float32,
        "Float64" => Float64,
        "Bool" => Bool
    )
    return types[x]
end

function makehomogeneous_main(args; version="1.0")
    settings = getargs(args, version)
    if isnothing(settings)
        return
    end

    writedir = settings["output"]
    filename = "homogenous"
    if occursin(r"\.nii(\.gz)?$", writedir)
        filename = basename(writedir)
        writedir = dirname(writedir)
    end

    mkpath(writedir)
    saveconfiguration(writedir, settings, args, version)

    mag_nii = readmag(settings["magnitude"])
    hdr = header(mag_nii)

    settings["verbose"] && size(mag_nii, 4) > 1 && println("Multi-echo data detected. Using the first echo for sensitivity estimation.")

    mag = makehomogeneous(mag_nii; sigma_mm=settings["sigma-bias-field"], nbox=settings["nbox"])

    savenii(mag, filename, writedir, hdr)
end

function exception_handler(settings::ArgParseSettings, err, err_code::Int=1)
    if err == ArgParseError("too many arguments")
        println(stderr,
            """wrong argument formatting!"""
        )
    end
    ArgParse.default_handler(settings, err, err_code)
end

function saveconfiguration(writedir, settings, args, version)
    writedir = abspath(writedir)
    open(joinpath(writedir, "settings_makehomogeneous.txt"), "w") do io
        for (fname, val) in settings
            if !(typeof(val) <: AbstractArray)
                println(io, "$fname: " * string(val))
            end
        end
        println(io, """Arguments: $(join(args, " "))""")
        println(io, "MakeHomogeneous version: $version")
    end
    open(joinpath(writedir, "citations_makehomogeneous.txt"), "w") do io
        println(io, "# If you use this software, please cite:")
        println(io)
        println(io, """Eckstein, K., Bachrata, B., Hangel, G., Widhalm, G., Enzinger, C., Barth, M., Trattnig, S., Robinson, S.D., 2021.
                    Improved susceptibility weighted imaging at ultra-high field using bipolar multi-echo acquisition and optimized image processing: CLEAR-SWI.
                    NeuroImage 237, 118175
                    https://doi.org/10.1016/j.neuroimage.2021.118175""")
        println(io)
        println(io, """Eckstein, K., Trattnig, S., Robinson, S.D., 2019.
                    A Simple Homogeneity Correction for Neuroimaging at 7T
                    Proceedings of the 27th Annual Meeting ISMRM. Presented at the ISMRM, Montréal, Québec, Canada.
                    https://index.mirasmart.com/ISMRM2019/PDFfiles/2716.html""")
        println(io)
        
        println(io)
        println(io, "# Optional citations:")
        println(io)
        println(io, """Bezanson, J., Edelman, A., Karpinski, S., Shah, V.B., 2017.
                    Julia: A fresh approach to numerical computing
                    SIAM Review 59, 65--98
                    https://doi.org/10.1137/141000671""")
    end
end
end