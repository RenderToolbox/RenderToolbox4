%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
%% Render a perfect reflector and check physical principles.

%% Choose example files.
parentSceneFile = 'RadianceTest.blend';
conditionsFile = 'RadianceTestConditions.txt';
mappingsFile = 'RadianceTestMappings.json';


%% Choose batch renderer options.
hints.fov = 49.13434 * pi() / 180;
hints.imageWidth = 100;
hints.imageHeight = 100;
hints.recipeName = 'rtbMakeRadianceTest';


%% Choose illuminant spectra.
resources = rtbWorkingFolder('folderName', 'resources', 'hints', hints);

% uniform white spectrum sampled every 5mn
wls = 300:5:800;
magnitudes = ones(size(wls));
rtbWriteSpectrumFile(wls, magnitudes, fullfile(resources, 'uniformSpectrum5nm.spd'));

% uniform white spectrum sampled every 10mn
wls = 300:10:800;
magnitudes = ones(size(wls));
rtbWriteSpectrumFile(wls, magnitudes, fullfile(resources, 'uniformSpectrum10nm.spd'));


%% Render with Mitsuba and PBRT.

% how to convert multi-spectral images to sRGB
toneMapFactor = 10;
isScale = true;

% make a montage and sensor images with each renderer
for renderer = {'Mitsuba', 'PBRT'}
    
    % choose one renderer
    hints.renderer = renderer{1};
    
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
