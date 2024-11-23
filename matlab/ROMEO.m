function [unwrapped, B0] = ROMEO(phase, parameters)
	if isfield(parameters, 'command') && ~isempty(parameters.command)
        romeo_binary = parameters.command;
	else
        [filepath, ~,~] = fileparts(mfilename('fullpath'));
        romeo_path = fullfile(filepath, '..', 'bin');
        romeo_name = 'romeo';
        if ispc
            romeo_name = 'romeo.exe';
        end
        romeo_binary = fullfile(romeo_path, romeo_name); 
	end
    
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
    
    % Output Files
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
    
    % Add quotes (to support paths with spaces)
    for i = 1:length(romeo_cmd)
        romeo_cmd(i) = '"' + romeo_cmd(i) + '"';
    end
    
    % Additional flags added without quotes
    if isfield(parameters, 'additional_flags')
        romeo_cmd = [romeo_cmd, parameters.additional_flags];
    end
    
    % Create romeo CMD command
    disp(join(['ROMEO command:', romeo_cmd]))
    
    % Run romeo (with path fixing on linux)
    if isunix; paths = getenv('LD_LIBRARY_PATH'); setenv('LD_LIBRARY_PATH'); end
    success = system(join(romeo_cmd)); % system() call should work on every machine
    if isunix; setenv('LD_LIBRARY_PATH', paths); end
    
    if success ~= 0
        error(['Something went wrong!' newline...
            'Please also try if ROMEO works via the command line.' newline...
            'Otherwise, please report the issue on https://github.com/korbinian90/ROMEO/issues']);
    end
    
    % Load the calculated output
    B0 = [];
    unwrapped = [];
    if isfield(parameters, 'calculate_B0') && parameters.calculate_B0
        B0 = load_untouch_nii(fn_total_field);
        B0 = B0.img;
    end
    if ~isfield(parameters, 'no_unwrapped_output') || ~parameters.no_unwrapped_output
        unwrapped = load_untouch_nii(fn_unwrapped)
        unwrapped = unwrapped.img;
    end
end
