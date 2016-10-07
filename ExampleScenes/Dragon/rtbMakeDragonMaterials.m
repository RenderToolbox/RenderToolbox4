%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
%% Render a dragon in several materials.

%% Choose example files, make sure they're on the Matlab path.
parentSceneFile = 'Dragon.blend';
conditionsFile = 'DragonMaterialsConditions.txt';
mappingsFile = 'DragonMaterialsMappings.json';

%% Choose batch renderer options.
hints.imageWidth = 320;
hints.imageHeight = 240;
hints.fov = 49.13434 * pi() / 180;
hints.recipeName = mfilename();

%% Render with Mitsuba and PBRT.
toneMapFactor = 10;
isScale = true;
for renderer = {'PBRT'}
    hints.renderer = renderer{1};
    
    nativeSceneFiles = rtbMakeSceneFiles(parentSceneFile, ...
        'conditionsFile', conditionsFile, ...
        'mappingsFile', mappingsFile, ...
        'hints', hints);
    radianceDataFiles = rtbBatchRender(nativeSceneFiles, 'hints', hints);
    
    [SRGBMontage, XYZMontage] = ...
        rtbMakeMontage(radianceDataFiles, ...
        'toneMapFactor', toneMapFactor, ...
        'isScale', isScale, ...
        'hints', hints);
    rtbShowXYZAndSRGB([], SRGBMontage, sprintf('%s (%s)', hints.recipeName, hints.renderer));
end
