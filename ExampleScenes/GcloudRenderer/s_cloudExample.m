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

% Sets up related to the car renderings and local directory tree
% Maybe should be called nnDirectories
nnConstants;

tokenPath = '/home/wandell/gcloud/primalsurfer-token.json'; % Path to a storage admin access key 
gcloud = true;

% Different labs might want to use the GCP in different zones.
% The defaults are set for the Wandell lab resources.  But to change the zone
% you could use this:
%   zone   = 'us-west1-b';
% and then set a 'zone' parameter below.

% Should have a validity check.  Surprising that we have the tokenPath early in
% the ordering within this nnHintsInit routine
% Small image size for debugging.
hints = rtbHintsInit('imageWidth',160,'imageHeight',120,...
    'recipeName','cloud-example',...
    'tokenPath',tokenPath,...
    'gcloud',gcloud,...
    'remodelerConvertAfter',@remodelerPBRTCloudExample,...
    'remodelerAfter', @remodelerCloudExample);

%% Open the GCP - maybe wait until rendering time?

fprintf('Initializing gcloud');
[gs,kube] = rtbCloudInit(hints);


%% Delete any radiance data files from google cloud

remoteRadianceFiles = gs.ls('cloud-example/renderings/PBRTCloud');
for ii=1:length(remoteRadianceFiles)
    gs.rm(remoteRadianceFiles{ii});
end

%% Full path to the object we are going to render
sceneFile = which('millenium-falcon.obj');

% Is there a way to make this be a camera ob
% Camera set to be 50 meters from an object distance
% This could be an array of cameras.
cameras = rtbCamerasInit('type',{'lens'},...
    'mode',{'radiance'},...
    'distance',25);
nCameras = length(cameras);

% Set up the work space
resourceFolder = rtbWorkingFolder('folderName','resources',...
    'rendererSpecific',false,...
    'hints',hints);

% Copy all the lens files for all the cameras into the work space
for ii=1:length(cameras)
    lensFile = fullfile(lensDir,strcat(cameras(ii).lens,'.dat'));
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
clear objects

% Not sure how I set the camera to look at the middle of the bounding box of the
% object.
objects(2).prefix   = '';    % Note that spaces or : are not allowed
objects(2).position = [0 0 0];
objects(2).orientation = 30;
% [xmin xmax; ymin ymax; zmin zmax],
[box3D , midPoint] = mexximpSceneBox(mfScene);
objects(2).bndbox = mat2str(box3D);
% objects(2) = objects(3);
% objects(2).position = [-5 -5 0];
objects(1) = objects(2);
objects(1).position = [0 0 10];
objectArrangements = cell(length(objects),1);
for ii=1:length(objects)
    objectArrangements{ii} = objects(ii);
end

% For each fixed configuration of the objects, we render a series of images for
% different camera properties. For example, this function sets particularly the position,
% lookAt and film distance variables.  Other slots are copied from the camera
% object itself.  The placedCameras combine the different object arrangements
% and cameras. The output is placedCameras{nCameras}(nArrangements).
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
names = cat(1,'imageName',fieldnames(placedCameras{1}),'objPosFile');
values = cell(1,length(names));

% Think about this
cntr = 1;
sceneId=1;  % Why not
for m=1:length(objectArrangements)
    
    % Create the name for the JSON file and save it
    objectArrangementFile = fullfile(resourceFolder,sprintf('Arrangement_%i.json',m)); 
    savejson('',objectArrangements{m},objectArrangementFile);
    
    currentCameras = placedCameras{m};  % An array of cameras
    
    % At this point, we now set up the parameters for the remodeler.  The
    % remodeler name is in 
    %  hints.batchRenderStrategy.remodelPerConditionAfterFunction
    %
    for c=1:length(placedCameras{m});
        
        % The scene output file name.  Mode determines the type, from radiance,
        % mesh, depth ...
        fName = sprintf('%03i_%s',sceneId,currentCameras(c).mode);
        
        values(cntr,1) = {fName};
        for i=2:(length(names)-1)
            values(cntr,i) = {currentCameras(c).(names{i})};
        end
        values(cntr,length(names)) = {objectArrangementFile};
        
        if strcmp(currentCameras(c).mode,'radiance')
            sceneId = sceneId+1;
        end
        cntr = cntr + 1;
    end
    
end

%%
rtbWriteConditionsFile(conditionsFile,names,values);
% strategy = RtbAssimpStrategy(hints);
% [names, values] = strategy.loadConditions(conditionsFile);
% edit(conditionsFile);

%% Generate files and render
% We parallelize scene generation, not the rendering because
% PBRT automatically scales the number of processes to equal the
% number of cores.
%
nativeSceneFiles = rtbMakeSceneFiles(mfScene, 'hints', hints,...
    'conditionsFile',conditionsFile);

%% Maybe Cloud init here

fprintf('Uploading data to gcloud\n');
rtbCloudUpload(hints, nativeSceneFiles);
fprintf('Data uploaded\n');

%%
fprintf('Batch rendering %d files\n',length(nativeSceneFiles));
rtbBatchRender(nativeSceneFiles, 'hints', hints);
fprintf('Jobs initiated\n');

%% Download, but check when ready

radianceDataFiles = [];
while isempty(radianceDataFiles)
    radianceDataFiles = rtbCloudDownload(hints);
    pause(20);
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

fprintf('Creating OI\n');
fov = 45;
meanIlluminance = 10;  % Lux
%

for i=1:1 %slength(radianceDataFiles)
    % chdir(fullfile(nnGenRootPath,'local'));
    % save('radianceDataFiles','radianceDataFiles');
    
    radianceData = load(radianceDataFiles{i});
    thisCamera = placedCameras{i}(1);
    
    % Create an oi and set the parameters
    clear oiParams;
    oiParams.optics_name = thisCamera.type ;
    oiParams.optics_model = 'diffractionlimited';
    oiParams.fov = fov;
    switch ieParamFormat(thisCamera.type)
        case 'pinhole'
            oiParams.optics_fnumber = 999;
        otherwise
            oiParams.optics_fnumber = thisCamera.fNumber;
    end
    oiParams.optics_focalLength = thisCamera.filmDistance*1e-3; % In meters
    [~, label] = fileparts(radianceDataFiles{i});
    oiParams.name = label;
    
    oi = buildOi(radianceData.multispectralImage, [], oiParams);
    
    oi = oiAdjustIlluminance(oi,meanIlluminance);
    
    ieAddObject(oi);
    oiWindow;
    
end

%% Save out the oi if you like
if 0
    chdir(fullfile(nnGenRootPath,'local','tmp'));
    oiNames = vcGetObjectNames('oi');
    for ii=1:length(oiNames)
        thisOI = ieGetObject('oi',ii);
        save([oiNames{ii},'.mat'],'thisOI');
    end
end

%%
if 0
    %% Experiment with different camera renderings
    oi   = ieGetObject('oi');
    fov  = oiGet(oi,'fov');
    oi   = oiAdjustIlluminance(oi,10);   % The illuminance values are very small
    
    % Big sensor
    sensor = sensorCreate;
    sensor = sensorSet(sensor,'fov',fov);
    
    sensor = sensorCompute(sensor,oi);
    ieAddObject(sensor); sensorWindow;
    
    ip = ipCreate;
    ip = ipCompute(ip,sensor);
    ieAddObject(ip); ipWindow;
    
end

%%




