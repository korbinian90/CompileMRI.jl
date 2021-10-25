function [swi, mip] = CLEARSWI(mag, phase, parameters)
    [filepath, ~,~] = fileparts(mfilename('fullpath'));
    clearswi_path = fullfile(filepath, '..', 'bin');
    clearswi_name = 'clearswi';
    if ispc
        clearswi_name = 'clearswi.exe';
    end
    clearswi_binary = fullfile(clearswi_path, clearswi_name); 
    
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

    % Output Files
    fn_swi = fullfile(output_dir, 'swi.nii');
    fn_mip = fullfile(output_dir, 'mip.nii');
    
    % Always required parameters
    cmd_phase = [' -p ' fn_phase];
    cmd_output = [' -o ' fn_swi];
    cmd_echo_times = [' -t ' mat2str(parameters.TE)];
    
    % Optional parameters
    cmd_mag_combine = '';
    if isfield(parameters, 'mag_combine')
        cmd_mag_combine = [' --mag-combine ' parameters.mag_combine];
    end
    cmd_unwrapping_algorithm = '';
    if isfield(parameters, 'unwrapping_algorithm')
        cmd_unwrapping_algorithm = [' --unwrapping-algorithm', parameters.unwrapping_algorithm];
    end
    cmd_phase_scaling_strength = '';
    if isfield(parameters, 'phase_scaling_strength')
        cmd_phase_scaling_strength = [' --phase-scaling-strength', parameters.phase_scaling_strength];
    end
    cmd_phase_scaling_type = '';
    if isfield(parameters, 'phase_scaling_type')
        cmd_phase_scaling_type = [' --phase-scaling-type', parameters.phase_scaling_type];
    end
    additional_flags = '';
    if isfield(parameters, 'additional_flags')
        additional_flags = [' ' parameters.additional_flags];
    end
    
    % Create clearswi CMD command
    clearswi_cmd = [clearswi_binary cmd_mag cmd_phase cmd_output cmd_echo_times cmd_mag_combine cmd_unwrapping_algorithm cmd_phase_scaling_type cmd_phase_scaling_strength additional_flags];
    disp(['clearswi command: ' clearswi_cmd])
    
    % Run clearswi
    success = system(clearswi_cmd); % system() call should work on every machine
    
    if success ~= 0
        error(['clearswi unwrapping failed! Check input files for corruption in ' output_dir]);
    end
    
    % Load the calculated output
    swi = load_untouch_nii(fn_swi).img;
    mip = load_untouch_nii(fn_mip).img;
end
