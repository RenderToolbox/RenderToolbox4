%% Render the Crytek version of the Sponza Atrium using RTB4

% This script renders the Sponza Atrium (Crytek version) at three different
% camera positions using a pinhole camera.

% Once rendered, it saves each multispectral image as an ISET optical image
% and uses ISET to display the oi's. 

% The Crytek model was imported into Blender, an Area Light mesh was added,
% and then exported as an OBJ file. The scene was organized in meter units
% in Blender, and then scaled by 10^3 during OBJ export so the units are
% now in millimeters.

% Approximate times to render:
%
% Size = [400x266]
% Pinhole, 1024 pixel samples
% Total time = 900 seconds?

% Size = [600x400]
% Pinhole, 4096 pixel samples
% Total time = 6963 seconds ~ 2 hours

% TL

%% Initialize
clear; close all;
ieInit;

% We must be in the same folder as this script
[path,name,ext] = fileparts(mfilename('fullpath'));
cd(path);

%% Load scene

% When exporting as an OBJ Blender, we must keep the coordinate system
% consistent. Nonetheless, there seems to still be a right/left flip in the
% images right now.
sceneFile = 'Data/scaledCrytek-YForwardZUp.obj';

% The import will convert the JPG texture files into EXR format if
% necessary. 
[scene, elements] = mexximpCleanImport(sceneFile,...
                                        'toReplace',{'jpg','png'},...
                                        'targetFormat','exr');
                                    
%% Add a camera and move it to a starting position

scene = mexximpCentralizeCamera(scene);

% In general, these camera positions are determined by positioning the
% camera in Blender
from = [-5000 0 1000]; % mm
to = [8000 0 1000]; % mm
up = [0 0 1];
mexximpLookAt(from, to, up)

cameraTransform = mexximpLookAt(from, to, up);
cameraNodeSelector = strcmp(scene.cameras.name, {scene.rootNode.children.name});
scene.rootNode.children(cameraNodeSelector).transformation = cameraTransform;

%% Choose batch renderer options.
hints.imageWidth = 400;
hints.imageHeight = 266;
hints.recipeName = 'rtbMakeCrytek';

hints.renderer = 'PBRT';
hints.batchRenderStrategy = RtbAssimpStrategy(hints);

% This function modifies general scene paraemters
hints.batchRenderStrategy.remodelPerConditionAfterFunction = @rtbCrytekMexximpRemodeler;
% This function modifies PBRT specific parameters
hints.batchRenderStrategy.converter.remodelAfterMappingsFunction = @rtbCrytekPBRTRemodeler;

% Change the docker container to our version of PBRT-spectral
hints.batchRenderStrategy.renderer.pbrt.dockerImage = 'vistalab/pbrt-v2-spectral';

%% Write any spectrum files.

% Load up D65 and move into the working folder. 
[wls,spd] = rtbReadSpectrum('D65.spd');
rtbWriteSpectrumFile(wls, spd, fullfile(rtbWorkingFolder('hints', hints),'D65.spd'));

%% Write conditions and generate scene files

nConditions = 3;
pixelSamples = ones(1,nConditions).*1024;
lightRotateAxis = [1 0 0;...
                   1 0 0;...
                   1 0 0]';
lightRotation = deg2rad([0 0 -25]);

cameraLocation = [-5 0 1;...
                  -6 0.77 4;...
                  -6 -2.46 4]'.*10^3;
cameraTarget = [8 0 1;...
                7 0.5 -0.65;...
                7 -0.97 2.1]'.*10^3;
cameraUp = [0 0 1;...
            0 0 1;...
            0 0 1]';

names = {'pixelSamples','lightRotateAxis','lightRotation','cameraLocation','cameraTarget','cameraUp'};
values = cell(nConditions, numel(names));
values(:,1) = num2cell(pixelSamples, 1);
values(:,2) = num2cell(lightRotateAxis, 1);
values(:,3) = num2cell(lightRotation, 1);
values(:,4) = num2cell(cameraLocation, 1);
values(:,5) = num2cell(cameraTarget, 1);
values(:,6) = num2cell(cameraUp, 1);

% Write the parameters in a conditions file. 
conditionsFile = 'CrytekConditions.txt';
resourceFolder = rtbWorkingFolder( ...
    'folderName', 'resources',...
    'hints', hints);
conditionsPath = fullfile(resourceFolder, conditionsFile);
rtbWriteConditionsFile(conditionsPath, names, values);

% Make the PBRT scene file.
nativeSceneFiles = rtbMakeSceneFiles(scene,'hints', hints,'conditionsFile',conditionsPath);

%% Render!
radianceDataFiles = rtbBatchRender(nativeSceneFiles, ...
    'hints', hints);

%% View as an OI

% TODO: Ideally, we want to use BuildOI here. Unfortunately, we don't have
% the "oiParameters" structure anymore. In RTB4, this structure held
% information about the film distance, diagonal, etc. We could then use
% this information to fill in parameter info in the OI, such as the
% F-number or the FOV. Now all that info is held in the remodeler. How
% should we move that info out from the remodeler into the oi?

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
oi = oiSet(oi, 'photons', single(photons) * 10^13); % I believe the scaling here is arbitrary.
oi = oiSet(oi,'name',oiName);

vcAddAndSelectObject(oi);

% Save oi
% TODO: Save rendering parameters in oi?
save(fullfile(renderingsFolder,sprintf('oi%i',i)),'oi');

end

oiWindow;

