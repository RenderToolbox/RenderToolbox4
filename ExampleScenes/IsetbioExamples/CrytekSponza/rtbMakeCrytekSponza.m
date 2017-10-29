%% Render the Crytek version of the Sponza Atrium using RTB4
%
% This script renders the Sponza Atrium (Crytek version) at three different
% camera positions using a pinhole camera.
%
% Once rendered, it saves each multispectral image as an ISET optical image
% and uses ISET to display the oi's.
%
% The Crytek model was imported into Blender, an Area Light mesh was added,
% and then exported as an OBJ file. The scene was organized in meter units
% in Blender, and then scaled by 10^3 during OBJ export so the units are
% now in millimeters.
%
% This scene could definitely be improved with some specular textures. I
% believe there might be a model with specularity somewhere online, in the
% future let's download that version and load it up into our pipeline.
%
% This example runs with PBRT, but proabably not with Mitsuba.
%
% Approximate times to render:
%
% Size = [144x88]
% Pinhole, 1024 pixel samples
% Total time = 170 seconds
%
% Size = [400x266]
% Pinhole, 1024 pixel samples
% Total time = 870 seconds
%
% Size = [600x400]
% Pinhole, 4096 pixel samples
% Total time = 6963 seconds ~ 2 hours

% Trisha Lian
% 
% 08/12/17  dhb  Made isetbio stuff conditional on isetbio being installed.
%                Write out a png of the image in any case.
%                Some cosmetic changes.

%% Initialize
%
% If you want to use isetbio and have TbTb installed, but not isetbio, type:
%    tbUse('isetbio','reset','as-is');
clear; close all;

%% Choose batch renderer options.
hints.imageWidth = 144;
hints.imageHeight = 88;
hints.recipeName = 'CrytekSponza';
hints.renderer = 'PBRT';
hints.batchRenderStrategy = RtbAssimpStrategy(hints);

% camera params we need to share between the remodeler and iset, below
cameraInfo.filmdiag = 20;
cameraInfo.filmdistance = 20;

% This function modifies general scene paraemters
hints.batchRenderStrategy.remodelPerConditionAfterFunction = @rtbCrytekMexximpRemodeler;

% This function modifies PBRT specific parameters
%   append the cameraInfo to the expected RTB parameters
pbrtRemodelerFunction = @(varargin) rtbCrytekPBRTRemodeler(varargin{:}, cameraInfo);
hints.batchRenderStrategy.converter.remodelAfterMappingsFunction = pbrtRemodelerFunction;

% Change the docker container to our version of PBRT-spectral
hints.batchRenderStrategy.renderer.pbrt.dockerImage = 'rendertoolbox/pbrt-v2-spectral';

resourceFolder = rtbWorkingFolder( ...
    'folderName', 'resources',...
    'hints', hints);

%% Load scene
% When exporting as an OBJ Blender, we must keep the coordinate system
% consistent. Nonetheless, there seems to still be a right/left flip in the
% images right now.

% The following scenefile must be a full path.
sceneFile = fullfile(rtbRoot(), 'ExampleScenes', 'IsetbioExamples', ...
    'CrytekSponza', 'Data', 'scaledCrytek.obj');

% The import will convert the JPG texture files into EXR format if
% necessary.
[scene, elements] = mexximpCleanImport(sceneFile,...
    'flipUVs',true,...
    'imagemagicImage','hblasins/imagemagic-docker',...
    'toReplace',{'jpg','tiff'},...
    'targetFormat','exr', ...
    'workingFolder', resourceFolder);

%% Add a camera and move it to a starting position

scene = mexximpCentralizeCamera(scene, 'viewExterior', false);

% In general, these camera positions are determined by positioning the
% camera in Blender
from = [-5000 0 1000]; % mm
to = [8000 0 1000]; % mm
up = [0 0 1];
mexximpLookAt(from, to, up)

cameraTransform = mexximpLookAt(from, to, up);
cameraNodeSelector = strcmp(scene.cameras.name, {scene.rootNode.children.name});
scene.rootNode.children(cameraNodeSelector).transformation = cameraTransform;

%% Write any spectrum files.

% Load up D65 and move into the working folder.
[wls,spd] = rtbReadSpectrum('D65.spd');
workingFolder = rtbWorkingFolder('hints', hints);
rtbWriteSpectrumFile(wls, spd, fullfile(workingFolder, 'D65.spd'));

%% Write conditions and generate scene files


nConditions = 3;
pixelSamples = ones(1,nConditions).*1024;
lightRotateAxis = [1 0 0;...
    1 0 0;...
    1 0 0]';
lightRotation = deg2rad([0 0 -25]);

cameraLocation = [-5 0 1;...
    -6 0.77 4;...
    -7 -3.5 6.18]'.*10^3;
cameraTarget = [8 0 1;...
    7 0.5 -0.65;...
    7 -1.7 3.37]'.*10^3;
cameraUp = [0 0 1;...
    0 0 1;...
    0 0 1]';

lightSpectra = {'D65.spd','D65.spd','D65.spd'};

names = {'pixelSamples','lightRotateAxis','lightRotation','cameraLocation','cameraTarget','cameraUp','lightSpectra'};
values = cell(nConditions, numel(names));
values(:,1) = num2cell(pixelSamples, 1);
values(:,2) = num2cell(lightRotateAxis, 1);
values(:,3) = num2cell(lightRotation, 1);
values(:,4) = num2cell(cameraLocation, 1);
values(:,5) = num2cell(cameraTarget, 1);
values(:,6) = num2cell(cameraUp, 1);
values(:,7) = lightSpectra;

% Write the parameters in a conditions file.
conditionsFile = 'CrytekConditions.txt';
conditionsPath = fullfile(resourceFolder, conditionsFile);
rtbWriteConditionsFile(conditionsPath, names, values);

% Make the PBRT scene file.
nativeSceneFiles = rtbMakeSceneFiles(scene,'hints', hints,'conditionsFile',conditionsPath);

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
% TODO: use cameraInfo struct to build correct optics for optical image,
% below.
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
        oi = oiSet(oi, 'photons', single(photons));
        oi = oiSet(oi,'name',oiName);
        vcAddAndSelectObject(oi);
        
        % Save oi
        % TODO: Save rendering parameters in oi?
        save(fullfile(renderingsFolder,sprintf('oi%i',i)),'oi');
        
        % Save RGB images
        rgb = oiGet(oi,'rgb');
        imwrite(rgb,sprintf('%s.png',oiName))
        
    end
    oiWindow;
end
