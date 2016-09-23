%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
%% Render a sphere with conditions that might affect output scaling.

%% Choose example files, make sure they're on the Matlab path.
clear hints
hints.imageHeight = 100;
hints.imageWidth = 100;
hints.fov = 49.13434 * pi() / 180;
parentSceneFile = 'ScalingTest.dae';
conditionsFile = 'ScalingTestConditions.txt';
mappingsFile = 'ScalingTestMappings.json';

%% Choose batch renderer options.
hints.recipeName = 'rtbMakeScalingTest';

%% Render with Mitsuba and PBRT.
% make an sRGB montage with each renderer
toneMapFactor = 10;
isScale = true;
for renderer = {'Mitsuba', 'PBRT'}
    % choose one renderer
    hints.renderer = renderer{1};
    
    % specify PBRT "TransformTimes" element with a remodeler function
    if strcmp('PBRT', hints.renderer)
        hints.batchRenderStrategy = RtbAssimpStrategy(hints);
        hints.batchRenderStrategy.converter.remodelAfterMappingsFunction = @CreateTransformTimes;
    end
    
    % turn off radiometric unit scaling
    oldRadiometricScale = getpref(hints.renderer, 'radiometricScaleFactor');
    setpref(hints.renderer, 'radiometricScaleFactor', 1);
    
    % make multi-spectral renderings, saved in .mat files
    nativeSceneFiles = rtbMakeSceneFiles(parentSceneFile, ...
        'mappingsFile', mappingsFile, ...
        'conditionsFile', conditionsFile, ...
        'hints', hints);
    radianceDataFiles = rtbBatchRender(nativeSceneFiles, ...
        'hints', hints);
    
    % restore radiometric unit scaling
    setpref(hints.renderer, 'radiometricScaleFactor', oldRadiometricScale);
    
    % display a montage
    montageName = sprintf('rtbMakeRadianceTest (%s)', hints.renderer);
    montageFile = [montageName '.png'];
    SRGBMontage = rtbMakeMontage(radianceDataFiles, ...
        'outFile', montageFile, ...
        'toneMapFactor', toneMapFactor, ...
        'isScale', isScale, ...
        'hints', hints);
    rtbShowXYZAndSRGB([], SRGBMontage, montageName);
end
