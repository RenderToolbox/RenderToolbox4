%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
%% Render the Dragon scene with 24 ColorChecker colors.

%% Choose example files, make sure they're on the Matlab path.
parentSceneFile = 'Dragon.blend';
mappingsFile = 'DragonColorCheckerMappings.json';
conditionsFile = 'DragonColorCheckerConditions.txt';

%% Choose batch renderer options.
hints.imageWidth = 150;
hints.imageHeight = 120;
hints.fov = 49.13434 * pi() / 180;
hints.recipeName = mfilename();

%% Make a fresh conditions file.
% choose spectrum file names and output image names
nSpectra = 24;
imageNames = cell(nSpectra, 1);
fileNames = cell(nSpectra, 1);
for ii = 1:nSpectra
    imageNames{ii} = sprintf('macbethDragon-%d', ii);
    fileNames{ii} = sprintf('mccBabel-%d.spd', ii);
end

% write file names and image names to a conditions file
varNames = {'imageName', 'dragonColor'};
varValues = cat(2, imageNames, fileNames);
resourceFolder = rtbWorkingFolder( ...
    'folderName', 'resources', ...
    'rendererSpecific', false, ...
    'hints', hints);
conditionsPath = fullfile(resourceFolder, conditionsFile);
rtbWriteConditionsFile(conditionsPath, varNames, varValues);

%% Render with Mitsuba and PBRT.
toneMapFactor = 10;
isScale = true;
for renderer = {'Mitsuba', 'PBRT'}
    hints.renderer = renderer{1};
    
    nativeSceneFiles = rtbMakeSceneFiles(parentSceneFile, ...
        'mappingsFile', mappingsFile, ...
        'conditionsFile', conditionsPath, ...
        'hints', hints);
    radianceDataFiles = rtbBatchRender(nativeSceneFiles, 'hints', hints);
    
    [SRGBMontage, XYZMontage] = ...
        rtbMakeMontage(radianceDataFiles, ...
        'toneMapFactor', toneMapFactor, ...
        'isScale', isScale, ...
        'hints', hints);
    rtbShowXYZAndSRGB([], SRGBMontage, sprintf('%s (%s)', hints.recipeName, hints.renderer));
end

