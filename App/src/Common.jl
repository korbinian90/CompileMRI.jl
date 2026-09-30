# Helpers the command line tools of this package share. Every tool parses with
# MriResearchTools.CLI and reads NIfTI through the loaders of fixed type, so that
# the same code runs in the PackageCompiler bundle and compiles with juliac --trim.
module Common

using MriResearchTools
const CLI = MriResearchTools.CLI

"""
    parse_command(getargs, name, args, version)

The options `getargs(args, version)` returns, `nothing` after --help or
--version, or `1` after a wrong command line, which is reported the way romeo
reports it.
"""
function parse_command(getargs::F, name::String, args, version) where F
    try
        return getargs(args, version)
    catch e
        e isa ArgumentError || rethrow()
        msg = e.msg
        msg isa String || (msg = "wrong arguments")
        CLI.print_stderr(name * ": " * msg * "\nwrong argument formatting! See " * name * " --help\n")
        return 1
    end
end

one(v::CLI.Values, key, default::String) = haskey(v, key) ? v[key][1] : default
many(v::CLI.Values, key, default::Vector{String}) = haskey(v, key) ? v[key] : default
flag(v::CLI.Values, key) = haskey(v, key)

# a single echo or echo time is recorded as the number itself
format_scalar_or_vector(v::AbstractVector) = length(v) == 1 ? CLI.format(v[1]) : CLI.format(v)

"`\"out.nii\"` and `\"out.nii.gz\"` name the output file, anything else the output folder."
is_nifti_path(path) = endswith(path, ".nii") || endswith(path, ".nii.gz")

"""
    split_output(output, filename)

The output folder and file name `output` stands for, with `filename` when it
names a folder. Returned rather than reassigned, since a reassigned variable
that a closure captures has no static type.
"""
split_output(output, filename) = is_nifti_path(output) ? (dirname(output), basename(output)) : (output, filename)

"""
    parse_numbers(strs)

The numbers given in array syntax, as a vector. See `MriResearchTools.parse_array`.
"""
function parse_numbers(strs)
    parsed = MriResearchTools.parse_array(strs)
    parsed isa Int && return [parsed]
    parsed isa Float64 && return [parsed]
    parsed isa Vector{Int} && return parsed
    parsed isa Vector{Float64} && return parsed
    throw(ArgumentError("\"$(join(strs, " "))\" is not a number or an array of numbers"))
end

"""
    parse_echoes(strs, neco)

The echoes selected with array syntax, `:` for all of them, as a vector of
indices. Throws a `BoundsError` for an echo out of range.
"""
function parse_echoes(strs, neco)
    parsed = MriResearchTools.parse_array(strs)
    echoes = if parsed isa Colon
        collect(1:neco)
    elseif parsed isa Int
        [parsed]
    elseif parsed isa Vector{Int}
        parsed
    else
        throw(ArgumentError("echoes must be integers"))
    end
    return (1:neco)[echoes]
end

"""
    in_file_dims(f, data, nd)

Calls `f` with the five dimensional `data` from `loadnii` reshaped to the `nd`
dimensions of the file, so that what is written has the dimensions of what was
read. One call per rank, each with a static type.
"""
function in_file_dims(f::F, data::Array{T,5}, nd::Integer) where {F,T}
    nd == 5 && return f(data)
    nd == 4 && return f(reshape(data, ntuple(i -> size(data, i), Val(4))))
    nd == 3 && return f(reshape(data, ntuple(i -> size(data, i), Val(3))))
    nd == 2 && return f(reshape(data, ntuple(i -> size(data, i), Val(2))))
    return f(reshape(data, size(data, 1)))
end

"The voxel size of the `nd` dimensions of the file."
pixdim(hdr, nd) = Float32[hdr.pixdim[i + 1] for i in 1:nd]

size3(a) = (size(a, 1), size(a, 2), size(a, 3))
as4d(a::AbstractArray{<:Any,5}) = reshape(a, Base.front(size(a)))
as4d(::Nothing) = nothing

end # module
