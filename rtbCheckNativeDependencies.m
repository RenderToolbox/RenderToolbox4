function [status, result, advice] = rtbCheckNativeDependencies()
% Check whether required native dependencies are installed.
%
% [status, result, advice] = rtbCheckNativeDependencies() checks the local
% system for native dependencies, like renderers and shared libraries.
% Returns a status code which is non-zero if some dependency was missing.
% Also returns a result, such as an error code about the missing
% dependency.  Finally, returns a string with advice about how to obtain
% a missing dependency, if any.
%
% [status, result, advice] = rtbCheckNativeDependencies()
%
%%% RenderToolbox4 Copyright (c) 2012-2017 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.


%% Check for OpenEXR library, also known as IlmImf.
if ismac()
    % assume homebrew
    findLibCommand = 'brew list | grep openexr';
else
    findLibCommand = 'ldconfig -p | grep libIlmImf';
end
openExr = checkSystem('OpenEXR', ...
    findLibCommand, ...
    'It looks like the OpenEXR library is not installed.  Please visit http://www.openexr.com/.  You might also try "sudo apt-get install openexr" or similar.');


%% OpenEXR is required.
if 0 ~= openExr.status
    status = openExr.status;
    result = openExr.result;
    advice = openExr.advice;
    return;
end


%% Check for Docker, the preferred way to obtain renderers.
docker = checkSystem('Docker', ...
    'docker ps', ...
    'It looks like Docker is not installed.  Please visit https://github.com/RenderToolbox/RenderToolbox4/wiki/Docker.');


%% Docker can cover both renderers.
if 0 == docker.status
    status = 0;
    result = 'Local dependencies were found.';
    advice = '';
    return;
end


%% Check for a local installation of the Mitsuba renderer.
mitsuba = checkSystem('Mitsuba', ...
    'which mitsuba', ...
    'It looks like Mitsuba is not installed.  Please visit https://www.mitsuba-renderer.org/.  Or, consider installing Docker so that RenderToolbox can get Mitsuba for you.');


%% Check for a local installation of the PBRT renderer.
pbrt = checkSystem('PBRT', ...
    'which pbrt', ...
    'It looks like PBRT is not installed.  Please visit https://github.com/scienstanford/pbrt-v2-spectral.  Or, consider installing Docker so that RenderToolbox can get PBRT for you.');


%% Check for both renderers.
if 0 ~= mitsuba.status
    status = mitsuba.status;
    result = mitsuba.result;
    advice = mitsuba.advice;
    return;
end

if 0 ~= pbrt.status
    status = pbrt.status;
    result = pbrt.result;
    advice = pbrt.advice;
    return;
end


%% Looks good from here.
status = 0;
result = 'Local dependencies were found.';
advice = '';


%% Check whether something exists and print messages.
function info = checkSystem(name, command, advice)
fprintf('Checking for %s:\n', name);
fprintf('  %s\n', command);
info.name = name;
info.advice = advice;
[info.status, result] = system(command);
info.result = strtrim(result);
if 0 == info.status
    fprintf('  OK.\n');
else
    fprintf('  Not found.  Status %d, result <%s>.\n', info.status, info.result);
end
