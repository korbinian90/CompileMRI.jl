function binary = mritools_binary(name, parameters)
%MRITOOLS_BINARY Path of a bundled mritools executable.
%   BINARY = MRITOOLS_BINARY(NAME, PARAMETERS) returns PARAMETERS.command when
%   it is set, and otherwise the executable NAME in the bin folder of this
%   bundle. The .exe suffix is added on Windows.
    if isfield(parameters, 'command') && ~isempty(parameters.command)
        binary = parameters.command;
        return
    end
    % This file lives in matlab/private, so the bundle root is two levels up.
    [filepath, ~, ~] = fileparts(mfilename('fullpath'));
    if ispc
        name = [name '.exe'];
    end
    binary = fullfile(filepath, '..', '..', 'bin', name);
end
