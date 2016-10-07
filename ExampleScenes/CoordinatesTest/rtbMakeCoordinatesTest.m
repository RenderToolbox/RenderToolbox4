%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
%% Render the CoordinatesTest scene.

%% Choose example files, make sure they're on the Matlab path.
parentSceneFile = 'CoordinatesTest.blend';

%% Choose batch renderer options.
hints.imageWidth = 320;
hints.imageHeight = 240;
hints.fov = 77.31962 * pi() / 180;
hints.recipeName = mfilename();

toneMapFactor = 100;
isScale = true;

%% Render.
for renderer = {'Mitsuba', 'PBRT'}
    hints.renderer = renderer{1};
    
    nativeSceneFiles = rtbMakeSceneFiles(parentSceneFile, 'hints', hints);
    radianceDataFiles = rtbBatchRender(nativeSceneFiles, 'hints', hints);
    
    [SRGBMontage, XYZMontage] = ...
        rtbMakeMontage(radianceDataFiles, ...
        'toneMapFactor', toneMapFactor, ...
        'isScale', isScale, ...
        'hints', hints);
    
    montageName = sprintf('%s (%s)', hints.recipeName, hints.renderer);
    rtbShowXYZAndSRGB([], SRGBMontage, montageName);
end
