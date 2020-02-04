include("../src/UnwrappingExecutable.jl")
phasefile = raw"F:\MRI\scanner_nifti\Paper\SWI_paper_7T_volunteers\19930503JSPC_201907041530\nifti\4\reform\Image.nii"
magfile = raw"F:\MRI\scanner_nifti\Paper\SWI_paper_7T_volunteers\19930503JSPC_201907041530\nifti\3\reform\Image.nii"

file = tempname()
args = [phasefile, "-o", raw"F:\MRI\Analysis\Volunteer7T\phase\romeo", "-m", magfile]
UnwrappingExecutable.unwrapping_main(args)
#rm(file)

args = [phasefile, "-o", raw"F:\MRI\Analysis\Volunteer7T\phase\romeo", "-B"]

try
    UnwrappingExecutable.unwrapping_main(args)
catch e
    println(e.msg)
finally
    GC.gc()
end
