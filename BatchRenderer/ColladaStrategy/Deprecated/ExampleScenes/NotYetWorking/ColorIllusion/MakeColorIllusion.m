%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
%% Render the ColorIllusion scene, with a texture.

%% Choose example files, make sure they're on the Matlab path.
parentSceneFile = 'ColorIllusion.dae';
mappingsFile = 'ColorIllusionMappings.txt';

%% Choose batch renderer options.
hints.whichConditions = [];
hints.imageWidth = 320;
hints.imageHeight = 240;
hints.recipeName = mfilename();
rtbChangeToWorkingFolder(hints);

%% Render with Mitsuba and PBRT.
toneMapFactor = 100;
isScale = true;
for renderer = {'Mitsuba', 'PBRT'}
    hints.renderer = renderer{1};
    nativeSceneFiles = rtbMakeSceneFiles(parentSceneFile, '', mappingsFile, hints);
    radianceDataFiles = rtbBatchRender(nativeSceneFiles, hints);
    montageName = sprintf('%s (%s)', 'ColorIllusion', hints.renderer);
    montageFile = [montageName '.png'];
    [SRGBMontage, XYZMontage] = ...
        rtbMakeMontage(radianceDataFiles, montageFile, toneMapFactor, isScale, hints);
    rtbShowXYZAndSRGB([], SRGBMontage, montageName);
end
