function [swi, mip] = CLEARSWI(mag, phase, parameters)
    if isfield(parameters, 'command') && ~isempty(parameters.command)
        clearswi_binary = parameters.command;
    else
        [filepath, ~,~] = fileparts(mfilename('fullpath'));
        clearswi_path = fullfile(filepath, '..', 'bin');
        clearswi_name = 'clearswi';
        if ispc
            clearswi_name = 'clearswi.exe';
        end
        clearswi_binary = fullfile(clearswi_path, clearswi_name); 
    end
    
    
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

    % deliberately a string, so everything gets promoted to string
    clearswi_cmd = string(clearswi_binary);

    % Always required parameters
    clearswi_cmd = [clearswi_cmd, '-p', fn_phase];
    clearswi_cmd = [clearswi_cmd, '-m', fn_mag];
    clearswi_cmd = [clearswi_cmd, '-o', fn_swi];
    clearswi_cmd = [clearswi_cmd, '-t', mat2str(parameters.TE)];
    
    % Add quotes (to support paths with spaces)
    for i = 1:length(clearswi_cmd)
        clearswi_cmd(i) = '"' + clearswi_cmd(i) + '"';
    end
    
    % Optional parameters
    if isfield(parameters, 'mag_combine')
        clearswi_cmd = [clearswi_cmd, '--mag-combine', parameters.mag_combine];
    end
    if isfield(parameters, 'unwrapping_algorithm')
        clearswi_cmd = [clearswi_cmd, '--unwrapping-algorithm', parameters.unwrapping_algorithm];
    end
    if isfield(parameters, 'phase_scaling_strength')
        clearswi_cmd = [clearswi_cmd, '--phase-scaling-strength', parameters.phase_scaling_strength];
    end
    if isfield(parameters, 'phase_scaling_type')
        clearswi_cmd = [clearswi_cmd, '--phase-scaling-type', parameters.phase_scaling_type];
    end
    if isfield(parameters, 'filter_size')
        clearswi_cmd = [clearswi_cmd, '--filter-size', parameters.filter_size];
    end
    if isfield(parameters, 'echoes')
        clearswi_cmd = [clearswi_cmd, '--echoes', parameters.echoes];
    end
    
    % Additional flags added without quotes
    if isfield(parameters, 'additional_flags')
        clearswi_cmd = [clearswi_cmd, parameters.additional_flags];
    end
    
    % Create clearswi CMD command
    disp(join(['clearswi command:', clearswi_cmd]))
    
    % Run clearswi (with path fixing on linux)
    if isunix; paths = getenv('LD_LIBRARY_PATH'); setenv('LD_LIBRARY_PATH'); end
    success = system(join(clearswi_cmd)); % system() call should work on every machine
    if isunix; setenv('LD_LIBRARY_PATH', paths); end

    if success ~= 0
        error(['Something went wrong!' newline...
            'Please also try if CLEARSWI works via the command line.' newline...
            'Otherwise, please report the issue on https://github.com/korbinian90/CompileMRI.jl/issues']);
    end
    
    % Load the calculated output
    swi = load_untouch_nii(fn_swi);
    swi = swi.img;
    mip = load_untouch_nii(fn_mip);
    mip = mip.img;
end
