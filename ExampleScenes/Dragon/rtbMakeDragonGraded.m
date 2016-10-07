%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
%% Render the Dragon scene with 5 graded colors.

%% Choose example files, make sure they're on the Matlab path.
parentSceneFile = 'Dragon.blend';
conditionsFile = 'DragonGradedConditions.txt';
mappingsFile = 'DragonGradedMappings.json';

%% Choose batch renderer options.
nSteps = 6;
hints.whichConditions = 1:nSteps;
hints.imageWidth = 320;
hints.imageHeight = 240;
hints.fov = 49.13434 * pi() / 180;
hints.recipeName = mfilename();

%% Write graded spectrum files.
resourcesFolder = rtbWorkingFolder( ...
    'folderName', 'resources', ...
    'rendererSpecific', false, ...
    'hints', hints);

% choose two spectrums to grade between
spectrumA = 'mccBabel-6.spd';
[wlsA, srfA] = rtbReadSpectrum(spectrumA);
spectrumB = 'mccBabel-9.spd';
[wlsB, srfB] = rtbReadSpectrum(spectrumB);

% grade linearly from a to b
alpha = linspace(0, 1, nSteps);
imageNames = cell(nSteps, 1);
fileNames = cell(nSteps, 1);
for ii = 1:nSteps
    srf = alpha(ii)*srfA + (1-alpha(ii))*srfB;
    imageNames{ii} = sprintf('GradedDragon-%d', ii);
    fileNames{ii} = sprintf('GradedSpectrum_%d.spd', ii);
    rtbWriteSpectrumFile(wlsA, srf, ...
        fullfile(resourcesFolder, fileNames{ii}));
end

% write a conditions file with image names and spectrum file names.
varNames = {'imageName', 'dragonColor'};
varValues = cat(2, imageNames, fileNames);
conditionsPath = fullfile(resourcesFolder, conditionsFile);
rtbWriteConditionsFile(conditionsPath, varNames, varValues);

%% Render with Mitsuba and PBRT.
rtbChangeToWorkingFolder('hints', hints);
toneMapFactor = 10;
isScaleGamma = true;
for renderer = {'Mitsuba'}
    hints.renderer = renderer{1};
    
    nativeSceneFiles = rtbMakeSceneFiles(parentSceneFile, ...
        'mappingsFile', mappingsFile, ...
        'conditionsFile', conditionsPath, ...
        'hints', hints);
    radianceDataFiles = rtbBatchRender(nativeSceneFiles, 'hints', hints);
    
    for ii = 1:nSteps
        [SRGBMontage, XYZMontage] = ...
            rtbMakeMontage(radianceDataFiles(ii), ...
            'toneMapFactor', toneMapFactor, ...
            'isScale', isScaleGamma, ...
            'hints', hints);
        rtbShowXYZAndSRGB([], SRGBMontage, sprintf('%s-%d (%s)', hints.recipeName, ii, hints.renderer));
    end
end
