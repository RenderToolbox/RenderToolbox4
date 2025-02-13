%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
%% Render an illusion from parent scene generated procedurally.

%% Choose example files, make sure they're on the Matlab path.
parentSceneFile = 'CheckerShadowNoDimples.dae';
mappingsFile    = 'CheckerShadowSceneMappings.json';

%% Choose batch renderer options.
hints.imageWidth = 640;
hints.imageHeight = 480;
hints.fov = 36 * pi() / 180;
hints.recipeName = 'rtbMakeCheckerShadowScene';
hints.renderer = 'Mitsuba';

toneMapFactor = 4;
isScale = true;

%% Render with Mitsuba and PBRT.

nativeSceneFiles = rtbMakeSceneFiles(parentSceneFile, ...
    'mappingsFile', mappingsFile, ...
    'hints', hints);
radianceDataFiles = rtbBatchRender(nativeSceneFiles, ...
    'hints', hints);

[SRGBMontage, XYZMontage] = ...
    rtbMakeMontage(radianceDataFiles, ...
    'toneMapFactor', toneMapFactor, ...
    'isScale', isScale, ...
    'hints', hints);
rtbShowXYZAndSRGB([], SRGBMontage, sprintf('CheckerShadowScene (%s)', hints.renderer));
