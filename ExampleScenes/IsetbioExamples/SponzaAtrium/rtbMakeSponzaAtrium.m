%% Render the Sponza Atrium using RTB4
%
% This script renders the Sponza Atrium (simple version) with different
% light spectra and different camera types. The light comes from a large
% rectangular area light on top of the atrium.
%
% The four different renders are:
%   1. D65 light rendered with short DOF (50mm lens)
%   2. D65 light with long DOF (50 mm lens)
%   3. Bright yellow light with a pinhole camera
%   4. Dim blue light with a pinhole camera camera
% In current form, only one conditioned is rendered to make this go
% fast.  Restore commented out code to get all four.
%
% Once rendered, it saves each multispectral image as an ISET optical image
% and uses ISET to display the oi's.
%
% The Sponza model was imported into Blender, an Area Light mesh was added,
% and then exported as a Collada file. In the future, we can probably
% import the OBJ model directly and combine it with a model of the Area
% Light.
%
% 11/22/16 Bump maps are now working! There may be some weird UV mapping
% issues with the texture on the columns - will sort out in the future.
%
% This example runs with PBRT, but proabably not with Mitsuba.
%
% Approximate times to render:
%
% Size = [400x270]
%   Condition 3 (only) --> 1024 pixel samples
% Total Time: ~400 seconds
%
% Size = [150x100]
%   Condition 1 --> (4096 pixel samples)
%   Condition 2 --> (4096 pixel samples)
%   Condition 3 --> (1024 pixel samples)
%   Condition 4 --> (1024 pixel samples)
% Total time: 638 sec ~ 10 min
%
% Size = [400x270]
%   Condition 1 --> (4096 pixel samples)
%   Condition 2 --> (4096 pixel samples)
%   Condition 3 --> (1024 pixel samples)
%   Condition 4 --> (1024 pixel samples)
% Total time: 3891 sec ~ 1 hour
%
% Size = [600x400]
%   Condition 1 --> (8192 pixel samples)
%   Condition 2 --> (8192 pixel samples)
%   Condition 3 --> (4096 pixel samples)
%   Condition 4 --> (4096 pixel samples)
% Total time: 19443 sec ~ 5 hours

% Trisha Lian
%
% 08/12/17  dhb  Made isetbio stuff conditional on isetbio being installed.
%                Write out a png of the image in any case.
%                Some cosmetic changes.
%                Change output name to match example conventions.

%% Initialize
%
% If you want to use isetbio and have TbTb installed, but not isetbio, type:
%    tbUse('isetbio','reset','as-is');
clear; close all;

%% Choose batch renderer options.
hints.imageWidth = 150;
hints.imageHeight = 100;
hints.recipeName = 'SponzaAtrium';
hints.renderer = 'PBRT';
hints.batchRenderStrategy = RtbAssimpStrategy(hints);

% We use "rtbSponzaPBRTRemodeler" to add all the parameters specific to
% PBRT. These include the cameras (e.g. pinhole, realisticDiffraction),
% number of pixel samples, and light spectra.
% If we wanted to change things like camera position and move meshes
% around, we would specify another file like "rtbSponzaMexximpRemodeler"
% instead.
hints.batchRenderStrategy.converter.remodelAfterMappingsFunction = @rtbSponzaPBRTRemodeler;

% Change the docker container to our version of PBRT-spectral
hints.batchRenderStrategy.renderer.pbrt.dockerImage = 'vistalab/pbrt-v2-spectral';

resourceFolder = rtbWorkingFolder( ...
    'folderName', 'resources',...
    'hints', hints);

%% Load scene

% The following scenefile must be a full path.
sceneFile = fullfile(rtbRoot(), 'ExampleScenes', 'IsetbioExamples', ...
    'SponzaAtrium', 'Data', 'SponzaScaled-YForwardZUp.obj');

[scene, elements] = mexximpCleanImport(sceneFile,...
    'flipUVs',true,...
    'imagemagicImage','hblasins/imagemagic-docker',...
    'toReplace',{'jpg','tiff'},...
    'targetFormat','exr', ...
    'strictMatching', true, ...
    'workingFolder', resourceFolder);

%% Move camera to a new position (in millimeters)
% We manually place it in a good position using the LookAt command.

% Add a camera
scene = mexximpCentralizeCamera(scene);

% Move camera
% These position were determined by looking at the Blender model
from = [537 8265 4050];
to = [0 -7265 1031];
up = [0 0 1];
mexximpLookAt(from, to, up);

cameraTransform = mexximpLookAt(from, to, up);
cameraNodeSelector = strcmp(scene.cameras.name, {scene.rootNode.children.name});
scene.rootNode.children(cameraNodeSelector).transformation = cameraTransform;

%% Write the spectrum files.
workingFolder = rtbWorkingFolder('hints', hints);

% Get basis CIE daylight basis vectors
cieInfo = load('B_cieday');

% Load up D65
[wls,spd] = rtbReadSpectrum('D65.spd');
rtbWriteSpectrumFile(wls, spd, fullfile(workingFolder, 'D65.spd'));

% Make a bright yellow sun
temp = 4000;
scale = 1;
spd = scale * GenerateCIEDay(temp, cieInfo.B_cieday);
wls = SToWls(cieInfo.S_cieday);
rtbWriteSpectrumFile(wls, spd, fullfile(workingFolder, 'BrightYellowSun.spd'));

% Make a dimmer blue sky
temp = 10000;
scale = 0.001;
spd = scale * GenerateCIEDay(temp, cieInfo.B_cieday);
wls = SToWls(cieInfo.S_cieday);
rtbWriteSpectrumFile(wls, spd, fullfile(workingFolder, 'DimBlueSky.spd'));

%% Write conditions and generate scene files

% We will have 4 conditions total
% 1. D65 with short DOF (50mm lens)
% 2. D65 with long DOF (50 mm lens)
% 3. Bright yellow light with a pinhole
% 4. Dim blue light with a pinhole camera

%{
names = {'lightSpectrum','apertureDiameter','cameraType','numSamples'};
nConditions = 4;
values = cell(nConditions,numel(names));
values(1,:) = {'D65.spd',17,'realistic',8192}; % First light condition
values(2,:) = {'D65.spd',7,'realistic',8192};
values(3,:) = {'BrightYellowSun.spd',0,'pinhole',4096}; % Second light condition
values(4,:) = {'DimBlueSky.spd',0,'pinhole',4096}; % Third light condition
%}

% ----------
% Only render condition 3 for fast debugging.
% 400x270, 1024 pixel samples --> 260 seconds
names = {'lightSpectrum','apertureDiameter','cameraType','numSamples'};
nConditions = 1;
values = cell(nConditions,numel(names));
values(1,:) = {'BrightYellowSun.spd',0,'pinhole',1024};
% ----------

% Write the parameters in a conditions file.
conditionsFile = 'SponzaConditions.txt';
conditionsPath = fullfile(resourceFolder, conditionsFile);
rtbWriteConditionsFile(conditionsPath, names, values);

% Make the PBRT scene file.
nativeSceneFiles = rtbMakeSceneFiles(scene,'hints', hints,'conditionsFile',conditionsPath);

%% Move lens file into resource folder.
% TODO: Any chance we can do this automatically?
lensFilePath = fullfile(rtbRoot(), 'ExampleScenes', 'IsetbioExamples', ...
    'SponzaAtrium', 'dgauss.50mm.dat');
copyfile(lensFilePath, workingFolder);

%% Render!
radianceDataFiles = rtbBatchRender(nativeSceneFiles, ...
    'hints', hints);

%% Images for display
%
% The different rendered images come with different scales,
% so a montage doesn't work very well.  This just produces
% an output image for the 4th one, which is the nice rendered
% chess set.
toneMapFactor = 10;
isScale = true;
[SRGBMontage, XYZMontage] = ...
    rtbMakeMontage(radianceDataFiles, ...
    'toneMapFactor', toneMapFactor, ...
    'isScale', isScale, ...
    'hints', hints);
rtbShowXYZAndSRGB([], SRGBMontage, sprintf('%s (%s)', hints.recipeName, hints.renderer));

%% Display as an isetbio optical image, if isetbio is available
%
% TODO: Ideally, we want to use BuildOI here. Unfortunately, we don't have
% the "oiParameters" structure anymore. In RTB4, this structure held
% information about the film distance, diagonal, etc. We could then use
% this information to fill in parameter info in the OI, such as the
% F-number or the FOV. Now all that info is held in
% "rtbSponzaPBRTRemodeler.m" How should we move that info out from the
% remodeler into the oi?
if (exist('ieInit','file'))
    ieInit;
    
    renderingsFolder = rtbWorkingFolder( ...
        'folderName', 'renderings',...
        'hints', hints);
    
    % Load in rendered data
    for i = 1:nConditions
        radianceData = load(radianceDataFiles{i});
        photons = radianceData.multispectralImage;
        
        oiName = sprintf('%s_%i',hints.recipeName,i);
        
        % Create an oi
        oi = oiCreate;
        oi = initDefaultSpectrum(oi);
        oi = oiSet(oi, 'photons', single(photons) * 10^13); % I believe scaling here is arbitrary.
        oi = oiSet(oi,'name',oiName);

        vcAddAndSelectObject(oi);
        
        % Save oi
        % TODO: Save rendering parameters somewhere?
        save(fullfile(renderingsFolder,sprintf('oi%i',i)),'oi');
        
        % Save RGB
        rgb = oiGet(oi,'rgb');
        imwrite(rgb,sprintf('%s.png',oiName))      
    end
    oiWindow;
end

