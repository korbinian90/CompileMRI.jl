include("../src/UnwrappingExecutable.jl")
phasefile = raw"F:\MRI\scanner_nifti\Paper\SWI_paper_7T_volunteers\19930503JSPC_201907041530\nifti\4\reform\Image.nii"
magfile = raw"F:\MRI\scanner_nifti\Paper\SWI_paper_7T_volunteers\19930503JSPC_201907041530\nifti\3\reform\Image.nii"

file = tempname()
UnwrappingExecutable.unwrapping_main([phasefile, "-o", raw"F:\MRI\Analysis\Volunteer7T\phase\romeo", "-m", magfile, "-B"])
GC.gc()
#rm(file)
