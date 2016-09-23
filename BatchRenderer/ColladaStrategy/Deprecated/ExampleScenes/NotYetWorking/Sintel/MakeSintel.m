%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
%% Render a still image from the Sintel Blender animated movie.

%% Choose example files, make sure they're on the Matlab path.
parentSceneFile = 'sintel_lite_cycles_v2.dae';

%% Choose batch renderer options.
hints.imageWidth = 320;
hints.imageHeight = 240;
hints.recipeName = mfilename();
rtbChangeToWorkingFolder(hints);

%% Render with Mitsuba and PBRT.
toneMapFactor = 100;
isScale = true;
for renderer = {'Mitsuba', 'PBRT'}
    hints.renderer = renderer{1};
    nativeSceneFiles = rtbMakeSceneFiles(parentSceneFile, '', '', hints);
    radianceDataFiles = rtbBatchRender(nativeSceneFiles, hints);
    montageName = sprintf('%s (%s)', 'Sintel', hints.renderer);
    montageFile = [montageName '.png'];
    [SRGBMontage, XYZMontage] = ...
        rtbMakeMontage(radianceDataFiles, montageFile, toneMapFactor, isScale, hints);
    rtbShowXYZAndSRGB([], SRGBMontage, montageName);
end
