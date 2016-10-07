%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Invoke the PBRT renderer.
%   @param sceneFile filename or path of a PBRT-native text scene file.
%   @param hints struct of RenderToolbox4 options, see rtbDefaultHints()
%   @param pbrt struct of pbrt config., see getpref("pbrt")
%
% @details
% Invoke the PBRT renderer on the given PBRT-native text @a sceneFile.
% This function handles some of the boring details of invoking PBRT with
% Matlab's unix() command.
%
% @details
% RenderToolbox4 assumes that relative paths in scene files are relative to
% @a hints.workingFolder.  But PBRT assumes that relative paths are
% relative to the folder that contains the scene file.  These are usually
% different folders.  This function copies @a sceneFile into @a
% hints.workingFolder so that relative paths will work using the
% RenderTooblox3 convention.
%
% @details
% Returns the numeric status code and text output from PBRT.
% Also returns the name of the expected output file from PBRT.
%
% Usage:
%   [status, result, output] = RunPBRT(sceneFile, hints)
%
% @ingroup Utilities
function [status, result, output] = RunPBRT(sceneFile, hints, pbrt)

if nargin < 2 || isempty(hints)
    hints = rtbDefaultHints();
else
    hints = rtbDefaultHints(hints);
end

if nargin < 3 || isempty(pbrt)
    pbrt = getpref('PBRT');
end

%% Where to get/put the input/output
% copy scene file to working folder
% so that PBRT can resolve relative paths from there
if rtbIsStructFieldPresent(hints, 'workingFolder')
    copyDir = rtbWorkingFolder('hints', hints);
else
    warning('RenderToolbox4:NoWorkingFolderGiven', ...
        'hints.workingFolder is missing, using pwd() instead');
    copyDir = pwd();
end
[~, sceneBase, sceneExt] = fileparts(sceneFile);
sceneCopy = fullfile(copyDir, [sceneBase, sceneExt]);
fprintf('PBRT needs to copy %s \n  to %s\n', sceneFile, sceneCopy);
[~, ~] = copyfile(sceneFile, sceneCopy, 'f');

renderings = rtbWorkingFolder( ...
    'folderName', 'renderings', ...
    'rendererSpecific', true, ...
    'hints', hints);
output = fullfile(renderings, [sceneBase '.dat']);

%% Invoke PBRT.
% find the PBRT executable
renderCommand = sprintf('%s --outfile %s %s', pbrt.executable, output, sceneCopy);
fprintf('%s\n', renderCommand);
[status, result] = rtbRunCommand(renderCommand, 'hints', hints);

%% Show a warning or figure?
if status ~= 0
    warning(result)
    warning('Could not render scene "%s".', sceneBase)
end
