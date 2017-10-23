%% Illustrates google cloud platform usage
%
%  Reads in a small object (millenial falcon).
%  Sets up a camera array
%  Places the object with respect to the cameras
%  Calls batch render on the cloud
%
% Uses - rtbCloudInit, rtbCloudUpload, rtbCloudDownload
% Uses - rtbHintsInit, rtbCamerasInit, rtbCamerasPlace
% Uses - local remodelers.  More discussion here.
%
% For this to run, you must have set up a google cloud account, have appropriate
% permissions, and have kubectl installed.  Instructions for this should be on
% the RenderToolbox4 web-site.  Soon, we hope.  Now a bunch of it is on the
% NN_Camera_Generalization web site.
%
% BW, Henryk Blasinski, SCIEN Stanford, 2017

%% Scene description

% Initialize ISET related variables
ieInit;

% Different labs might want to use the GCP in different zones.
% The defaults are set for the Wandell lab resources.  But to change the zone
% you could use this:
%   zone   = 'us-west1-b';
% and then set a 'zone' parameter below.

% Should have a validity check.  Surprising that we have the tokenPath early in
% the ordering within this nnHintsInit routine
% Small image size for debugging.
hints = rtbHintsInit('imageWidth',640,'imageHeight',480,...
    'recipeName','cloud-example',...
    'gcloud',true,...
    'remodelerConvertAfter',@remodelerPBRTCloudExample,...
    'remodelerAfter', @remodelerCloudExample);

%% Open the GCP - maybe wait until rendering time?

fprintf('Initializing gcloud');
[gs,kube] = rtbCloudInit(hints);

%% Delete radiance data files from google cloud and local
%{
if gcloud
    % Build the directories from the hints
    remoteRadianceFiles = gs.ls(fullfile(hints.recipeName,'renderings','PBRTCloud'));
    for ii=1:length(remoteRadianceFiles)
        gs.rm(remoteRadianceFiles{ii});
    end
end
delete(fullfile(rtbWorkingFolder('hints',hints,'folderName','renderings','rendererSpecific',true),'*radiance*'));
%}
%% Full path to the object we are going to render
sceneFile = fullfile(rtbRoot,'ExampleScenes','Flythrough','MilleniumFalcon','millenium-falcon.obj');

% Is there a way to make this be a camera ob
% Camera set to be 50 meters from an object distance
% This could be an array of cameras.
cameras = rtbCamerasInit('type',{'pinhole'},...
    'mode',{'radiance'},...
    'PTR',{[0 -40 0]},...
    'distance',5,...
    'pixelSamples',32);
nCameras = length(cameras);

% Set up the work space
resourceFolder = rtbWorkingFolder('folderName','resources',...
    'rendererSpecific',false,...
    'hints',hints);

% Copy all the lens files for all the cameras into the work space
for ii=1:length(cameras)
    lensFile = fullfile(rtbRoot,'RenderData','Lenses',strcat(cameras(ii).lens,'.dat'));
    copyfile(lensFile,resourceFolder);
end

% Use ISET, get D65 spectrum in photons and write to work space
wave = 400:10:700;
il  = illuminantCreate('D65',wave);
d65 = illuminantGet(il,'photons');
rtbWriteSpectrumFile(wave,d65,fullfile(resourceFolder,'D65.spd'));

%% Build the scene

% Import the millenial faclon, which is small.  mfScene is a struct that
% includes information about the object that will be converted into PBRT format
% for rendering.  Perhaps it should be called an objectFile, rather than a scene
% file.
mfScene = mexximpCleanImport(sceneFile,...
    'ignoreRootTransform',true,...
    'flipUVs',true,...
    'imagemagicImage','hblasins/imagemagic-docker',...
    'toReplace',{'jpg','png','tga'},...
    'options','-gamma 0.45',...
    'targetFormat','exr',...
    'makeLeftHanded',true,...
    'flipWindingOrder',true,...
    'workingFolder',resourceFolder);

%% Initiate some positions 

% Find the current bounding box of the object, which is set below.  The midPoint
% is not yet used.
objects(1).prefix   = ''; 
objects(1).position = [0 0 0];
objects(1).orientation = 30;
objects(1).bndbox = mexximpSceneBox(mfScene);


% Assemble the objects into a cell array of object arrangements
objectArrangements = cell(length(objects),1);
for ii=1:length(objects)
    objectArrangements{ii} = objects(ii);
end

% For each fixed configuration of the objects, we render a series of images for
% different camera properties. This function sets the camera position, lookAt
% and film distance variables for each combination of camera and object
% arrangements. Other slots in placedCameras are copied from the cameras object.
%
% I am confused about what camera.position means.  From following the code, it
% might mean the position of the object that camera is looking at.
%
% Also, the camera has a position and also a height.  The position is 3D and the
% height is one number that in this cases matches the 3rd dimension of the
% position. 
%
% The dimensions of this variable are placedCameras{nCameras}(nArrangements).
placedCameras = rtbCamerasPlace(cameras,objectArrangements);

%% Make values used for the Conditions file.
%
% Parameters are placed in a struct that will be gridded for the
% conditions.
%
% Look at other method for building up the conditions file.

% These are the variable names used in the conditionsFile.  
%  See
%  https://github.com/RenderToolbox/RenderToolbox4/wiki/Conditions-File-
% Some of these are standard.  Some are selected here.
conditionsFile = fullfile(resourceFolder,'Conditions.txt');
names = cat(1,'imageName','objPosFile',fieldnames(placedCameras{1}));

sceneId=1;  % Why not
for m=1:length(objectArrangements)
    
    values = cell(1,length(names));
    cntr = 1;
    
    % Create the name for the JSON file and save it
    objectArrangementFile = fullfile(resourceFolder,sprintf('Arrangement_%i.json',m)); 
    savejson('',objectArrangements{m},objectArrangementFile);
    
    currentCameras = placedCameras{m};  % An array of cameras
    
    
    for c=1:length(placedCameras{m})
        
        % The scene output file name.  Mode determines the type, from radiance,
        % mesh, depth ...
        fName = sprintf('%03i_%s',sceneId,currentCameras(c).mode);
        
        values(cntr,1) = {fName};
        values(cntr,2) = {objectArrangementFile};
        
        for i=3:(length(names))
            values(cntr,i) = {currentCameras(c).(names{i})};
        end
                
        cntr = cntr + 1;
        sceneId = sceneId + 1;
    end
    
end

%%
rtbWriteConditionsFile(conditionsFile,names,values);

%% Generate files and render
% We parallelize scene generation, not the rendering because
% PBRT automatically scales the number of processes to equal the
% number of cores.
%
nativeSceneFiles = rtbMakeSceneFiles(mfScene, 'hints', hints,...
    'conditionsFile',conditionsFile);

%% Maybe Cloud init here

rtbCloudUpload(hints, nativeSceneFiles);

%rtbCloudUpload_Ali(hints, nativeSceneFiles);

%%
rtbBatchRender(nativeSceneFiles, 'hints', hints);

%% Download, but check when ready

% To get rid of the Warning and to speed things up, we should follow the
% Installation instructions on this page.
% https://cloud.google.com/storage/docs/gsutil/addlhelp/CRC32CandInstallingcrcmod
%
radianceDataFiles = [];
while isempty(radianceDataFiles)
    pause(30);
    radianceDataFiles = rtbCloudDownload(hints);
end

% We aren't saving the radianceDataFiles for all the conditions.
% This means we have to rerun too many times.
%
% Also, we don't have the true irradiance level, just a
% noise-free irradiance.  So, we should aim to set the
% irradiance to a reasonable level here.
%
% load('radianceDataFiles');
%% The camera object could be the ISET camera object
%
% Maybe implement opticsCreate('pbrt') and attach this to the OI.  Then run if
% optics.type is 'pbrt' at the beginning call pbrtGet/Set
% 
% Figure out a plan to make the cameras and arrangement be clear either from the
% radianceDataFiles or the list or something.

for i=1:length(radianceDataFiles)
    
    radianceData = load(radianceDataFiles{i});
    
    % Create an oi and set the parameters
    oiParams.lensType = values{i,strcmp(names,'lens')};
    oiParams.filmDistance = values{i,strcmp(names,'filmDistance')};
    oiParams.filmDiag = values{i,strcmp(names,'filmDiagonal')};
        
    [~, label] = fileparts(radianceDataFiles{i});
    oiParams.name = label;
    
    oi = BuildOI(radianceData.multispectralImage,[],oiParams);
    oi = oiAdjustIlluminance(oi,100);
    
    ieAddObject(oi);
    oiWindow;
    
end






