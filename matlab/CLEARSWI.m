function [swi, mip] = CLEARSWI(mag, phase, parameters)
%CLEARSWI Susceptibility weighted imaging with the bundled clearswi executable.
%   [SWI, MIP] = CLEARSWI(MAG, PHASE, PARAMETERS)
%
%   Recognised fields of PARAMETERS:
%     TE                         echo times, required
%     output_dir                 where the temporary NIfTI files are written
%     voxel_size                 [x y z], written into the NIfTI header
%     mag_combine                'SNR' | 'average' | 'echo <n>' | ...
%     mag_sensitivity_correction 'on' | 'off'
%     mag_softplus_scaling       'on' | 'off'
%     unwrapping_algorithm       'laplacian' | 'romeo' | 'laplacianslice'
%     filter_size                high pass filter size, e.g. [4 4 0]
%     phase_scaling_type         'tanh' | 'negativetanh' | 'positive' | ...
%     phase_scaling_strength     scaling strength, e.g. 4
%     echoes                     which echoes to use, e.g. '1:3'
%     mip_slices                 number of slices for the mIP
%     qsm                        true to weight the phase with TGV QSM
%     qsm_input                  path to a precomputed QSM, instead of phase
%     qsm_mask                   path to a mask for the QSM step
%     writesteps                 folder for the intermediate results
%     no_phase_rescale           true if the phase is already in radians
%     fix_ge_phase               true for GE phase saved with slice jumps
%     command                    path to the clearswi binary, if not bundled
%     additional_flags           pasted through verbatim, see clearswi --help

    clearswi_binary = mritools_binary('clearswi', parameters);

    output_dir = pwd();
    if isfield(parameters, 'output_dir')
        output_dir = parameters.output_dir;
    end

    % Input Files
    fn_mag = fullfile(output_dir, 'Mag.nii');
    fn_phase = fullfile(output_dir, 'Phase.nii');

    phase_nii = make_nii(phase);
    mag_nii = make_nii(mag);
    if isfield(parameters, 'voxel_size')
        phase_nii.hdr.dime.pixdim(2:4) = parameters.voxel_size;
        mag_nii.hdr.dime.pixdim(2:4) = parameters.voxel_size;
    end
    save_nii(phase_nii, fn_phase);
    save_nii(mag_nii, fn_mag);

    % Output Files. clearswi splits a path ending in .nii into a directory and
    % a filename, so swi.nii and mip.nii land next to each other here.
    fn_swi = fullfile(output_dir, 'swi.nii');
    fn_mip = fullfile(output_dir, 'mip.nii');

    % deliberately a string, so everything gets promoted to string
    clearswi_cmd = string(clearswi_binary);

    % Always required parameters
    clearswi_cmd = [clearswi_cmd, '-p', fn_phase];
    clearswi_cmd = [clearswi_cmd, '-m', fn_mag];
    clearswi_cmd = [clearswi_cmd, '-o', fn_swi];
    clearswi_cmd = [clearswi_cmd, '-t', mat2str(parameters.TE)];

    % Optional parameters
    if isfield(parameters, 'mag_combine')
        % 'echo 3' and 'SE 5' are two arguments to clearswi, not one: it reads
        % the first token to pick the algorithm and the last as its value. Every
        % element is quoted before the call, so this has to be split here.
        clearswi_cmd = [clearswi_cmd, '--mag-combine', split(string(parameters.mag_combine))'];
    end
    if isfield(parameters, 'mag_sensitivity_correction')
        clearswi_cmd = [clearswi_cmd, '--mag-sensitivity-correction', parameters.mag_sensitivity_correction];
    end
    if isfield(parameters, 'mag_softplus_scaling')
        clearswi_cmd = [clearswi_cmd, '--mag-softplus-scaling', parameters.mag_softplus_scaling];
    end
    if isfield(parameters, 'unwrapping_algorithm')
        clearswi_cmd = [clearswi_cmd, '--unwrapping-algorithm', parameters.unwrapping_algorithm];
    end
    if isfield(parameters, 'phase_scaling_strength')
        clearswi_cmd = [clearswi_cmd, '--phase-scaling-strength', string(parameters.phase_scaling_strength)];
    end
    if isfield(parameters, 'phase_scaling_type')
        clearswi_cmd = [clearswi_cmd, '--phase-scaling-type', parameters.phase_scaling_type];
    end
    if isfield(parameters, 'filter_size')
        clearswi_cmd = [clearswi_cmd, '--filter-size', mat2str(parameters.filter_size)];
    end
    if isfield(parameters, 'echoes')
        clearswi_cmd = [clearswi_cmd, '--echoes', parameters.echoes];
    end
    if isfield(parameters, 'mip_slices')
        clearswi_cmd = [clearswi_cmd, '--mip-slices', string(parameters.mip_slices)];
    end
    if isfield(parameters, 'qsm') && parameters.qsm
        clearswi_cmd = [clearswi_cmd, '--qsm'];
    end
    if isfield(parameters, 'qsm_input')
        clearswi_cmd = [clearswi_cmd, '--qsm-input', parameters.qsm_input];
    end
    if isfield(parameters, 'qsm_mask')
        clearswi_cmd = [clearswi_cmd, '--qsm-mask', parameters.qsm_mask];
    end
    if isfield(parameters, 'writesteps')
        clearswi_cmd = [clearswi_cmd, '--writesteps', parameters.writesteps];
    end
    if isfield(parameters, 'no_phase_rescale') && parameters.no_phase_rescale
        clearswi_cmd = [clearswi_cmd, '--no-phase-rescale'];
    end
    if isfield(parameters, 'fix_ge_phase') && parameters.fix_ge_phase
        clearswi_cmd = [clearswi_cmd, '--fix-ge-phase'];
    end

    mritools_run(clearswi_cmd, parameters, "CLEARSWI");

    % Load the calculated output
    swi = load_untouch_nii(fn_swi);
    swi = swi.img;
    mip = load_untouch_nii(fn_mip);
    mip = mip.img;
end
