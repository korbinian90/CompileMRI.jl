function [mask, quality] = ROMEO_mask(phase, parameters)
%ROMEO_MASK Brain masking with the bundled romeo_mask executable.
%   [MASK, QUALITY] = ROMEO_MASK(PHASE, PARAMETERS)
%
%   Recognised fields of PARAMETERS:
%     output_dir          where the temporary NIfTI files are written
%     voxel_size          [x y z], written into the NIfTI header
%     TE                  echo times, required for multi-echo
%     mag                 magnitude array, improves the quality map
%     factor              masking threshold factor, e.g. 0.8
%     unwrap_echoes       which echoes to use, e.g. '1:3'
%     weights             ROMEO weighting, e.g. 'romeo3'
%     write_quality       true to also return the voxel quality map
%     no_phase_rescale    true if the phase is already in radians
%     fix_ge_phase        true for GE phase saved with slice jumps
%     command             path to the romeo_mask binary, if not bundled
%     additional_flags    pasted through verbatim, see romeo_mask --help

    binary = mritools_binary('romeo_mask', parameters);

    output_dir = pwd();
    if isfield(parameters, 'output_dir')
        output_dir = parameters.output_dir;
    end

    fn_phase = fullfile(output_dir, 'Phase.nii');
    fn_mag = fullfile(output_dir, 'Mag.nii');

    voxel_size = [1 1 1];
    if isfield(parameters, 'voxel_size')
        voxel_size = parameters.voxel_size;
    end
    save_nii(make_nii(phase, voxel_size), fn_phase);
    if isfield(parameters, 'mag') && ~isempty(parameters.mag)
        save_nii(make_nii(parameters.mag, voxel_size), fn_mag);
    end

    % romeo_mask names its own outputs, so the output argument is a directory.
    out_dir = fullfile(output_dir, 'romeo_mask');
    fn_mask = fullfile(out_dir, 'mask.nii');
    fn_quality = fullfile(out_dir, 'quality.nii');

    % deliberately a string, so everything gets promoted to string
    cmd = string(binary);
    cmd = [cmd, '-p', fn_phase];
    cmd = [cmd, '-o', out_dir];

    % Optional parameters
    if isfield(parameters, 'mag') && ~isempty(parameters.mag)
        cmd = [cmd, '-m', fn_mag];
    end
    if isfield(parameters, 'TE')
        cmd = [cmd, '-t', mat2str(parameters.TE)];
    end
    if isfield(parameters, 'factor')
        cmd = [cmd, '-f', string(parameters.factor)];
    end
    if isfield(parameters, 'unwrap_echoes')
        cmd = [cmd, '-e', parameters.unwrap_echoes];
    end
    if isfield(parameters, 'weights')
        cmd = [cmd, '-w', parameters.weights];
    end
    if isfield(parameters, 'write_quality') && parameters.write_quality
        cmd = [cmd, '-q'];
    end
    if isfield(parameters, 'no_phase_rescale') && parameters.no_phase_rescale
        cmd = [cmd, '--no-phase-rescale'];
    end
    if isfield(parameters, 'fix_ge_phase') && parameters.fix_ge_phase
        cmd = [cmd, '--fix-ge-phase'];
    end

    mritools_run(cmd, parameters, "ROMEO_mask");

    mask = load_untouch_nii(fn_mask);
    mask = mask.img;
    quality = [];
    if isfield(parameters, 'write_quality') && parameters.write_quality
        quality = load_untouch_nii(fn_quality);
        quality = quality.img;
    end
end
