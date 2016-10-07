%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
%% Render the MaterialSphere scene with 3 materials.

%% Choose example files, make sure they're on the Matlab path.
parentSceneFile = 'MaterialSphere.blend';
conditionsFile = 'MaterialSphereConditions.txt';
mappingsFile = 'MaterialSphereMappings.json';

%% Choose batch renderer options.
hints.imageWidth = 200;
hints.imageHeight = 160;
hints.fov = 49.13434 * pi() / 180;
hints.recipeName = mfilename();

%% Choose some color matching functions to make sensor images.
% choose several Pyschtoolbox matching functions
%   these are the names of Pyschtoolbox colorimetric .mat files
matchFuncs = {'T_xyz1931.mat', 'T_cones_smj', 'T_rods'};

% invent a new matching function that extracts a narrow wavelength band
bandName = 'narrow-band-matching';
nBands = 81;
bandSampling = [380 5 nBands];
bandFunction = zeros(1, nBands);
bandFunction(round(nBands/2)) = 1;

% choose the invented matching function, along with descriptive metadata
matchFuncs{4} = bandFunction;
matchSampling{4} = bandSampling;
matchNames{4} = bandName;

%% Render with Mitsuba and PBRT.

% how to convert multi-spectral images to sRGB
toneMapFactor = 100;
isScaleGamma = true;

% make a montage and sensor images with each renderer
for renderer = {'Mitsuba', 'PBRT'}
    
    % choose one renderer
    hints.renderer = renderer{1};
    
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
        'isScale', isScaleGamma, ...
        'hints', hints);
    
    % display the sRGB montage
    rtbShowXYZAndSRGB([], SRGBMontage, sprintf('%s (%s)', hints.recipeName, hints.renderer));
    
    % make some sensor images, in addition to the sRGB montage
    sensorImages = rtbMakeSensorImages(radianceDataFiles, matchFuncs, ...
        'matchingS', matchSampling, ...
        'names', matchNames, ...
        'hints', hints);
end
