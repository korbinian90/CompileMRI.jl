function [unwrapped, B0] = ROMEO(phase, parameters)
%ROMEO Phase unwrapping with the bundled romeo executable.
%   [UNWRAPPED, B0] = ROMEO(PHASE, PARAMETERS)
%
%   Recognised fields of PARAMETERS:
%     output_dir                 where the temporary NIfTI files are written
%     voxel_size                 [x y z], written into the NIfTI header
%     TE                         echo times, required for multi-echo
%     mag                        magnitude array, improves unwrapping
%     mask                       array, or 'nomask' | 'robustmask' | 'qualitymask'
%     mask_unwrapped             true to mask the unwrapped output
%     calculate_B0               true to also compute a B0 map in [Hz]
%     phase_offset_correction    'off' | 'on' | 'bipolar'
%     unwrap_echoes              which echoes to unwrap, e.g. '1:3'
%     template                   template echo for multi-echo unwrapping
%     no_phase_rescale           true if the phase is already in radians
%     fix_ge_phase               true for GE phase saved with slice jumps
%     write_quality              true to write the voxel quality map
%     individual_unwrapping      true to unwrap each echo on its own
%     correct_global             true to correct a global phase offset
%     command                    path to the romeo binary, if not bundled
%     additional_flags           pasted through verbatim, see romeo --help

    romeo_binary = mritools_binary('romeo', parameters);

    output_dir = pwd();
    if isfield(parameters, 'output_dir')
        output_dir = parameters.output_dir;
    end

    % Input Files
    fn_phase = fullfile(output_dir, 'Phase.nii');
    fn_mask = fullfile(output_dir, 'Mask.nii');
    fn_mag = fullfile(output_dir, 'Mag.nii');

    voxel_size = [1 1 1];
    if isfield(parameters, 'voxel_size')
        voxel_size = parameters.voxel_size;
    end

    phase_nii = make_nii(phase, voxel_size);
    save_nii(phase_nii, fn_phase);

    if isfield(parameters, 'mag') && ~isempty(parameters.mag)
        mag_nii = make_nii(parameters.mag, voxel_size);
        save_nii(mag_nii, fn_mag);
    end

    if isfield(parameters, 'mask') && isnumeric(parameters.mask)
        mask_nii = make_nii(parameters.mask, voxel_size);
        save_nii(mask_nii, fn_mask);
    end

    % Output Files. romeo splits a path ending in .nii into a directory and a
    % filename, so these are where the results land.
    fn_unwrapped = fullfile(output_dir, 'Unwrapped.nii');
    fn_total_field = fullfile(output_dir, 'B0.nii');

    % deliberately a string, so everything gets promoted to string
    romeo_cmd = string(romeo_binary);

    % Always required parameters
    romeo_cmd = [romeo_cmd, '-p', fn_phase];
    romeo_cmd = [romeo_cmd, '-o', fn_unwrapped];

    % Optional parameters
    if isfield(parameters, 'calculate_B0') && parameters.calculate_B0
        romeo_cmd = [romeo_cmd, '-B'];
    end
    if isfield(parameters, 'mag') && ~isempty(parameters.mag)
        romeo_cmd = [romeo_cmd, '-m', fn_mag];
    end
    if isfield(parameters, 'TE')
        romeo_cmd = [romeo_cmd, '-t', mat2str(parameters.TE)];
    end
    if isfield(parameters, 'mask')
        if isnumeric(parameters.mask)
            romeo_cmd = [romeo_cmd, '-k', fn_mask];
        else
            romeo_cmd = [romeo_cmd, '-k', parameters.mask];
        end
    end
    if isfield(parameters, 'phase_offset_correction')
        romeo_cmd = [romeo_cmd, '--phase-offset-correction', parameters.phase_offset_correction];
    end
    if isfield(parameters, 'unwrap_echoes')
        romeo_cmd = [romeo_cmd, '-e', parameters.unwrap_echoes];
    end
    if isfield(parameters, 'template')
        romeo_cmd = [romeo_cmd, '--template', string(parameters.template)];
    end
    if isfield(parameters, 'mask_unwrapped') && parameters.mask_unwrapped
        romeo_cmd = [romeo_cmd, '--mask-unwrapped'];
    end
    if isfield(parameters, 'no_phase_rescale') && parameters.no_phase_rescale
        romeo_cmd = [romeo_cmd, '--no-rescale'];
    end
    if isfield(parameters, 'fix_ge_phase') && parameters.fix_ge_phase
        romeo_cmd = [romeo_cmd, '--fix-ge-phase'];
    end
    if isfield(parameters, 'write_quality') && parameters.write_quality
        romeo_cmd = [romeo_cmd, '-q'];
    end
    if isfield(parameters, 'individual_unwrapping') && parameters.individual_unwrapping
        romeo_cmd = [romeo_cmd, '-i'];
    end
    if isfield(parameters, 'correct_global') && parameters.correct_global
        romeo_cmd = [romeo_cmd, '--correct-global'];
    end

    mritools_run(romeo_cmd, parameters, "ROMEO");

    % Load the calculated output
    B0 = [];
    unwrapped = [];
    if isfield(parameters, 'calculate_B0') && parameters.calculate_B0
        B0 = load_untouch_nii(fn_total_field);
        B0 = B0.img;
    end
    if ~isfield(parameters, 'no_unwrapped_output') || ~parameters.no_unwrapped_output
        unwrapped = load_untouch_nii(fn_unwrapped);
        unwrapped = unwrapped.img;
    end
end
