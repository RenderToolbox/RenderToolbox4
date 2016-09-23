%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Invoke PBRT.
%   @param scene struct description of the scene to be rendererd
%   @param hints struct of RenderToolbox4 options, see rtbDefaultHints()
%
% @details
% This function is the RenderToolbox4 "Render" function for PBRT.
%
% @details
% See RTB_Render_SampleRenderer() for more about Render functions.
%
% Usage:
%   [status, result, multispectralImage, S] = RTB_Render_PBRT(scene, hints)
function [status, result, multispectralImage, S] = RTB_Render_PBRT(scene, hints)

% copy the scene file to working folder base
%   so that relative paths in scene file will work
sceneFile = scene.pbrtFile;
[~, sceneBase, sceneExt] = fileparts(sceneFile);
copyDir = rtbWorkingFolder('hints', hints);
sceneCopy = fullfile(copyDir, [sceneBase, sceneExt]);
copyfile(sceneFile, sceneCopy, 'f');

renderer = RtbPBRTRenderer(hints);
[status, result, multispectralImage, S] = renderer.render(sceneCopy);
