clearvars
addpath(fileparts(mfilename('fullpath')))
addpath(fullfile(fileparts(mfilename('fullpath')), 'NIfTI_20140122'))

%% Phase
% The example data shipped next to this script is a small three echo dataset.
% Replace these two paths with your own once you have seen this run.
data_dir = fullfile(fileparts(mfilename('fullpath')), 'example_data');
phase_fn = fullfile(data_dir, 'Phase.nii');
mag_fn = fullfile(data_dir, 'Mag.nii');
phase = load_nii(phase_fn).img;

%% Optional Parameters

parameters.output_dir = fullfile(tempdir, 'romeo_tmp'); % if not set pwd() is used
parameters.TE = [1,2,3]; % required for multi-echo; these belong to the example data
parameters.mag = load_nii(mag_fn).img;
parameters.mask = 'robustmask'; % an array, or 'nomask' | 'robustmask' | 'qualitymask'
parameters.calculate_B0 = true; % optianal B0 calculation for multi-echo
parameters.phase_offset_correction = 'off'; % options are: 'off' | 'on' | 'bipolar'
parameters.voxel_size = load_nii_hdr(phase_fn).dime.pixdim(2:4); % if set the written NIfTI files will have the matching voxelsize; is also used for optimal kernel size in MCPC-3D-S phase offset smoothing; can be given as [0.3, 0.3, 1.2]
parameters.additional_flags = '--verbose -q -i'; % settings are pasted directly to ROMEO cmd (see https://github.com/korbinian90/ROMEO for options)
% parameters.command = '<romeo_location>'; % for special cases, when romeo binary is not found or a wrapper is used

%% Suggested steps
mkdir(parameters.output_dir);

[unwrapped, B0] = ROMEO(phase, parameters);

%rmdir(parameters.output_dir, 's') % remove the temporary ROMEO output folder

unwrapped_nii = make_nii(unwrapped);
unwrapped_nii.hdr = load_nii_hdr(phase_fn);
