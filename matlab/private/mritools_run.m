function mritools_run(cmd, parameters, tool)
%MRITOOLS_RUN Quote, display and run an mritools command line.
%   MRITOOLS_RUN(CMD, PARAMETERS, TOOL) quotes every element of the string
%   array CMD so that paths containing spaces survive, appends
%   PARAMETERS.additional_flags unquoted, runs the result, and raises a
%   descriptive error if it fails.

    % Quoting happens here, after the caller has appended every option it
    % knows about, so optional arguments are quoted exactly like required
    % ones. additional_flags is deliberately left unquoted: it is pasted
    % through as written and may hold several flags at once.
    for i = 1:length(cmd)
        cmd(i) = '"' + cmd(i) + '"';
    end
    if isfield(parameters, 'additional_flags') && ~isempty(parameters.additional_flags)
        cmd = [cmd, parameters.additional_flags];
    end

    disp(join([tool + " command:", cmd]))

    % MATLAB runs external programs with its own library paths exported, which
    % makes the bundled binaries load MATLAB's copies of shared libraries
    % instead of their own. Clear those for the duration of the call. macOS
    % uses the DYLD variables rather than LD_LIBRARY_PATH.
    vars = {};
    if ismac
        vars = {'DYLD_LIBRARY_PATH', 'DYLD_FALLBACK_LIBRARY_PATH', 'LD_LIBRARY_PATH'};
    elseif isunix
        vars = {'LD_LIBRARY_PATH'};
    end
    saved = cell(size(vars));
    for i = 1:numel(vars)
        saved{i} = getenv(vars{i});
        setenv(vars{i});
    end
    status = system(join(cmd));
    for i = 1:numel(vars)
        setenv(vars{i}, saved{i});
    end

    if status ~= 0
        msg = ['Something went wrong running ' char(tool) '!' newline ...
               'Please also try whether it works from the command line.'];
        if ismac
            msg = [msg newline newline ...
                   'On macOS this is usually the quarantine flag that the system' newline ...
                   'attaches to anything downloaded from the internet. Open a' newline ...
                   'Terminal, type "xattr -cr " with a trailing space, drag the' newline ...
                   'mritools folder into the window and press Enter, then try' newline ...
                   'again. README_macOS.txt in that folder explains it.'];
        end
        msg = [msg newline ...
               'Otherwise please report the issue on' newline ...
               'https://github.com/korbinian90/CompileMRI.jl/issues'];
        error('%s', msg);
    end
end
