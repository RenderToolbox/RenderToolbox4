%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
%% Render the Interior scene with various lighting.

%% Choose example files, make sure they're on the Matlab path.
parentSceneFile = 'interio.dae';
conditionsFile = 'InteriorConditions.txt';
mappingsFile = 'InteriorMappings.json';

%% Choose batch renderer options.
hints.fov = 49.13434 * pi() / 180;
hints.recipeName = 'rtbMakeInterior';

%% Write some spectra to use.
resources = rtbWorkingFolder('folderName', 'resources', 'hints', hints);
cieInfo = load('B_cieday');

% make orange-yellow for a few lights
temp = 4000;
scale = 3;
spd = scale * GenerateCIEDay(temp, cieInfo.B_cieday);
wls = SToWls(cieInfo.S_cieday);
rtbWriteSpectrumFile(wls, spd, fullfile(resources, 'YellowLight.spd'));

% make strong yellow for the hanging spot light
temp = 5000;
scale = 30;
spd = scale * GenerateCIEDay(temp, cieInfo.B_cieday);
wls = SToWls(cieInfo.S_cieday);
rtbWriteSpectrumFile(wls, spd, fullfile(resources, 'HangingLight.spd'));

% make daylight for the windows behind the camera
[wavelengths, magnitudes] = rtbReadSpectrum('D65.spd');
scale = 1;
magnitudes = scale * magnitudes;
rtbWriteSpectrumFile(wavelengths, magnitudes, fullfile(resources, 'WindowLight.spd'));

%% Render with Mitsuba and PBRT.

% how to convert multi-spectral images to sRGB
toneMapFactor = 10;
isScale = true;

% make a montage and sensor images with each renderer
for renderer = {'Mitsuba', 'PBRT'}
    
    % choose one renderer
    hints.renderer = renderer{1};
    
    % make multi-spectral renderings, saved in .mat files
    nativeSceneFiles = rtbMakeSceneFiles(parentSceneFile, ...
        'mappingsFile', mappingsFile, ...
        'conditionsFile', conditionsFile, ...
        'hints', hints);
    radianceDataFiles = rtbBatchRender(nativeSceneFiles, ...
        'hints', hints);
    
    % write each condition to a separate image file
    for ii = 1:numel(radianceDataFiles)
        [outPath, outBase, outExt] = fileparts(radianceDataFiles{ii});
        montageName = sprintf('%s (%s)', outBase, hints.renderer);
        montageFile = [montageName '.png'];
        SRGBMontage = rtbMakeMontage(radianceDataFiles(ii), ...
            'outFile', montageFile, ...
            'toneMapFactor', toneMapFactor, ...
            'isScale', isScale, ...
            'hints', hints);
        rtbShowXYZAndSRGB([], SRGBMontage, montageName);
    end
end
