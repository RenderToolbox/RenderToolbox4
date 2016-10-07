%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Invoke the Mitsuba renderer.
%   @param sceneFile filename or path of a Mitsuba-native scene file.
%   @param hints struct of RenderToolbox4 options, see rtbDefaultHints()
%   @param mitsuba struct of mitsuba config., see getpref("Mitsuba")
%
% @details
% Invoke the Mitsuba renderer on the given Mitsuba-native @a sceneFile.
% This function handles some of the boring details of invoking Mitsuba with
% Matlab's unix() command.
%
% @details
% Returns the numeric status code and text output from Mitsuba.
% Also returns the name of the expected output file from Mitsuba.
%
% Usage:
%   [status, result, output] = RunMitsuba(sceneFile, hints)
%
% @ingroup Utilities
function [status, result, output] = RunMitsuba(sceneFile, hints, mitsuba)

if nargin < 2 || isempty(hints)
    hints = rtbDefaultHints();
else
    hints = rtbDefaultHints(hints);
end

if nargin < 3 || isempty(mitsuba)
    mitsuba = getpref('Mitsuba');
end

%% Where to get/put the input/output
[~, sceneBase] = fileparts(sceneFile);
renderings = rtbWorkingFolder( ...
    'folderName', 'renderings', ...
    'rendererSpecific', true, ...
    'hints', hints);
output = fullfile(renderings, [sceneBase '.exr']);

%% Invoke Mitsuba.

% find the Mitsuba executable
libPathName = getpref('Mitsuba', 'libraryPathName');
libPath = getpref('Mitsuba', 'libraryPath');
executable = fullfile(mitsuba.app, mitsuba.executable);
renderCommand = sprintf('%s="%s" "%s" -o "%s" "%s"', ...
    libPathName, ...
    libPath, ...
    executable, ...
    output, ...
    sceneFile);
fprintf('%s\n', renderCommand);
[status, result] = rtbRunCommand(renderCommand, 'hints', hints);

%% Show a warning or figure?
if status ~= 0
    warning(result)
    warning('Could not render scene "%s".', sceneFile)
end
