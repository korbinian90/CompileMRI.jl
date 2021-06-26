%% Required
addpath('NIfTI_20140122')
phase = load_nii(fn_phase).img;

%% Optional
parameters.output_dir = fullfile(tempdir, 'romeo_tmp'); % if not set pwd() is used
parameters.TE = [1,2,3]; % required for multi-echo
parameters.mag = load_nii(fn_mag).img;
parameters.mask = load_nii(fn_mask).img; % can be an array or a string: 'nomask' | 'robustmask'
parameters.calculate_B0 = true; % optianal B0 calculation for multi-echo
parameters.phase_offset_correction = 'bipolar'; % options are: 'off' | 'on' | 'bipolar'
parameters.voxel_size = [0.3, 0.3, 1.2]; % for MCPC-3D-S phase offset smoothing
parameters.additional_flags = '--verbose -q'; % settings are pasted directly to ROMEO cmd (see https://github.com/korbinian90/ROMEO for options)

%% Suggested steps
mkdir(parameters.output_dir);

[unwrapped, B0] = ROMEO(phase, parameters);

%rmdir(parameters.output_dir, 's') % remove the temporary ROMEO output folder
