%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
%% Render the MaterialSphere scene, with remodeled mexximp parent scene.

%% Choose example files, make sure they're on the Matlab path.
parentSceneFile = 'MaterialSphere.blend';
conditionsFile = 'MaterialSphereConditions.txt';
mappingsFile = 'MaterialSphereMappings.json';

%% Choose batch renderer options.
hints.imageWidth = 200;
hints.imageHeight = 160;
hints.fov = 49.13434 * pi() / 180;
hints.recipeName = mfilename();

%% Choose a remodeler function to modify the mexximp parent scene.
remodelerFunction = 'rtbJitterVertices';

%% Render with Mitsuba and PBRT.

% how to convert multi-spectral images to sRGB
toneMapFactor = 100;
isScale = true;

% make a montage and sensor images with each renderer
for renderer = {'Mitsuba', 'PBRT'}
    
    % choose one renderer
    hints.renderer = renderer{1};
    
    % setup of the remodeler function
    hints.batchRenderStrategy = RtbAssimpStrategy(hints);
    hints.batchRenderStrategy.remodelPerConditionBeforeFunction = remodelerFunction;
    
    % make 3 multi-spectral renderings, saved in .mat files
    nativeSceneFiles = rtbMakeSceneFiles(parentSceneFile, ...
        'mappingsFile', mappingsFile, ...
        'conditionsFile', conditionsFile, ...
        'hints', hints);
    radianceDataFiles = rtbBatchRender(nativeSceneFiles, ...
        'hints', hints);
    
    % condense multi-spectral renderings into one sRGB montage
    [SRGBMontage, XYZMontage] = ...
        rtbMakeMontage(radianceDataFiles, ...
        'toneMapFactor', toneMapFactor, ...
        'isScale', isScale, ...
        'hints', hints);
    
    % display the sRGB montage
    rtbShowXYZAndSRGB([], SRGBMontage, sprintf('%s (%s)', hints.recipeName, hints.renderer));
end
