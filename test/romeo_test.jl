include("../src/UnwrappingExecutable.jl")
phasefile = raw"F:\MRI\scanner_nifti\Paper\SWI_paper_7T_volunteers\19950113MTGU_201907041700\nifti\20\reform\Image.nii"
magfile = raw"F:\MRI\scanner_nifti\Paper\SWI_paper_7T_volunteers\19950113MTGU_201907041700\nifti\19\reform\Image.nii"

file = tempname()
UnwrappingExecutable.unwrapping_main([phasefile, "-o", file])
GC.gc()
rm(file)
