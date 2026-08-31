function homogeneous = MakeHomogeneous(mag, parameters)
%MAKEHOMOGENEOUS Bias field correction with the bundled makehomogeneous executable.
%   HOMOGENEOUS = MAKEHOMOGENEOUS(MAG, PARAMETERS)
%
%   Recognised fields of PARAMETERS:
%     output_dir          where the temporary NIfTI files are written
%     voxel_size          [x y z], written into the NIfTI header
%     sigma_bias_field    smoothing size of the bias field, e.g. 7
%     nbox                number of boxes per dimension, default 8
%     datatype            output type, float types only, e.g. 'Float64'
%     command             path to the makehomogeneous binary, if not bundled
%     additional_flags    pasted through verbatim, see makehomogeneous --help

    binary = mritools_binary('makehomogeneous', parameters);

    output_dir = pwd();
    if isfield(parameters, 'output_dir')
        output_dir = parameters.output_dir;
    end

    fn_mag = fullfile(output_dir, 'Mag.nii');

    voxel_size = [1 1 1];
    if isfield(parameters, 'voxel_size')
        voxel_size = parameters.voxel_size;
    end
    save_nii(make_nii(mag, voxel_size), fn_mag);

    % A path ending in .nii is split into a directory and a filename, so the
    % result lands exactly here.
    fn_out = fullfile(output_dir, 'homogeneous.nii');

    % deliberately a string, so everything gets promoted to string
    cmd = string(binary);
    cmd = [cmd, '-m', fn_mag];
    cmd = [cmd, '-o', fn_out];

    % Optional parameters
    if isfield(parameters, 'sigma_bias_field')
        cmd = [cmd, '-s', mat2str(parameters.sigma_bias_field)];
    end
    if isfield(parameters, 'nbox')
        cmd = [cmd, '-n', string(parameters.nbox)];
    end
    if isfield(parameters, 'datatype')
        cmd = [cmd, '-d', parameters.datatype];
    end

    mritools_run(cmd, parameters, "MakeHomogeneous");

    homogeneous = load_untouch_nii(fn_out);
    homogeneous = homogeneous.img;
end
