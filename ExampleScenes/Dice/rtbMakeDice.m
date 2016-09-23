%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
%% Render the Dice scene, with a texture.

%% Choose example files, make sure they're on the Matlab path.
parentSceneFile = 'Dice.dae';
mappingsFile = 'DiceMappings.json';

%% Choose batch renderer options.
hints.fov = 49.13434 * pi() / 180;
hints.imageWidth = 640;
hints.imageHeight = 480;
hints.recipeName = 'rtbMakeDice';

%% Render with Mitsuba and PBRT.
toneMapFactor = 100;
isScale = true;
for renderer = {'Mitsuba', 'PBRT'}
    hints.renderer = renderer{1};
    
    nativeSceneFiles = rtbMakeSceneFiles(parentSceneFile, ...
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
