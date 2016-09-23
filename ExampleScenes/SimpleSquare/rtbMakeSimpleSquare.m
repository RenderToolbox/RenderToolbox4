%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
%% Render a square in many colors.

%% Choose example files.
parentSceneFile = 'SimpleSquare.blend';
mappingsFile = 'SimpleSquareMappings.json';
conditionsFile = 'SimpleSquareConditions.txt';

%% Choose batch renderer options.
hints.fov = 49.13434 * pi() / 180;
hints.imageWidth = 50;
hints.imageHeight = 50;
hints.recipeName = 'rtbMakeSimpleSquare';

%% Render with Mitsuba and PBRT
toneMapFactor = 0;
isScale = true;
for renderer = {'Mitsuba', 'PBRT'}
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
