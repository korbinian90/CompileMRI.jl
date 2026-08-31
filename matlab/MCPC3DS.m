function [combined_phase, combined_mag] = MCPC3DS(mag, phase, parameters)
%MCPC3DS Coil combination with the bundled mcpc3ds executable.
%   [COMBINED_PHASE, COMBINED_MAG] = MCPC3DS(MAG, PHASE, PARAMETERS)
%
%   MAG and PHASE are 5D arrays [x y z echo channel].
%
%   Recognised fields of PARAMETERS:
%     TE                    echo times, required
%     output_dir            where the temporary NIfTI files are written
%     voxel_size            [x y z], written into the NIfTI header
%     smoothing_sigma       phase offset smoothing size, e.g. [10 10 5]
%     bipolar               true for bipolar readout correction
%     write_phase_offsets   true to also write the phase offsets
%     no_phase_rescale      true if the phase is already in radians
%     fix_ge_phase          true for GE phase saved with slice jumps
%     writesteps            folder for the intermediate results
%     command               path to the mcpc3ds binary, if not bundled
%     additional_flags      pasted through verbatim, see mcpc3ds --help

    mcpc3ds_binary = mritools_binary('mcpc3ds', parameters);

    output_dir = pwd();
    if isfield(parameters, 'output_dir')
        output_dir = parameters.output_dir;
    end

    % Input Files
    fn_mag = fullfile(output_dir, 'Mag.nii');
    fn_phase = fullfile(output_dir, 'Phase.nii');

    voxel_size = [1 1 1];
    if isfield(parameters, 'voxel_size')
        voxel_size = parameters.voxel_size;
    end

    save_nii(make_nii(phase, voxel_size), fn_phase);
    save_nii(make_nii(mag, voxel_size), fn_mag);

    % mcpc3ds names its own outputs, so the output argument is a directory.
    out_dir = fullfile(output_dir, 'mcpc3ds');
    fn_combined_phase = fullfile(out_dir, 'combined_phase.nii');
    fn_combined_mag = fullfile(out_dir, 'combined_mag.nii');

    % deliberately a string, so everything gets promoted to string
    mcpc3ds_cmd = string(mcpc3ds_binary);

    % Always required parameters
    mcpc3ds_cmd = [mcpc3ds_cmd, '-p', fn_phase];
    mcpc3ds_cmd = [mcpc3ds_cmd, '-m', fn_mag];
    mcpc3ds_cmd = [mcpc3ds_cmd, '-o', out_dir];
    mcpc3ds_cmd = [mcpc3ds_cmd, '-t', mat2str(parameters.TE)];

    % Optional parameters
    if isfield(parameters, 'smoothing_sigma')
        mcpc3ds_cmd = [mcpc3ds_cmd, '-s', mat2str(parameters.smoothing_sigma)];
    end
    if isfield(parameters, 'bipolar') && parameters.bipolar
        mcpc3ds_cmd = [mcpc3ds_cmd, '-b'];
    end
    if isfield(parameters, 'write_phase_offsets') && parameters.write_phase_offsets
        mcpc3ds_cmd = [mcpc3ds_cmd, '--write-phase-offsets'];
    end
    if isfield(parameters, 'no_phase_rescale') && parameters.no_phase_rescale
        mcpc3ds_cmd = [mcpc3ds_cmd, '--no-phase-rescale'];
    end
    if isfield(parameters, 'fix_ge_phase') && parameters.fix_ge_phase
        mcpc3ds_cmd = [mcpc3ds_cmd, '--fix-ge-phase'];
    end
    if isfield(parameters, 'writesteps')
        mcpc3ds_cmd = [mcpc3ds_cmd, '--writesteps', parameters.writesteps];
    end

    mritools_run(mcpc3ds_cmd, parameters, "MCPC3DS");

    % Load the calculated output
    combined_phase = load_untouch_nii(fn_combined_phase);
    combined_phase = combined_phase.img;
    combined_mag = load_untouch_nii(fn_combined_mag);
    combined_mag = combined_mag.img;
end
