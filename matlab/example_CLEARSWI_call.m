clearvars
addpath('NIfTI_20140122')

%% Required Parameters
phase_fn = '/path_to_data/Phase.nii';
mag_fn = '/path_to_data/Magnitude.nii';
phase = load_nii(phase_fn).img;
mag = load_nii(mag_fn).img;
parameters.TE = [1,2,3];

%% Optional Parameters
parameters.output_dir = fullfile(tempdir, 'clearswi_tmp'); % if not set pwd() is used
parameters.voxel_size = load_nii_hdr(phase_fn).dime.pixdim(2:4); % if set, the written NIfTI files will have the matching voxelsize
parameters.mag_combine = 'SNR';
parameters.unwrapping_algorithm = 'laplacian';
parameters.phase_scaling_strength = '4';
parameters.phase_scaling_type = 'tanh';
parameters.additional_flags = '--verbose'; % additional_flags are pasted directly to CLEARSWI cmd (run "$ bin/clearswi --help" for options)

%% Suggested steps
mkdir(parameters.output_dir);

[swi, mip] = CLEARSWI(mag, phase, parameters);

%rmdir(parameters.output_dir, 's') % remove the temporary CLEARSWI output folder
