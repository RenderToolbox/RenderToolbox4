%% Compare lens renderings of different cars
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
hints = nnHintsInit('imageWidth',160,'imageHeight',120,...
    'recipeName','cloud-example',...
    'tokenPath',tokenPath,...
    'gcloud',gcloud,...
    'mexximpRemodeler', @MexximpRemodellerMultipleObj);

%% Open the GCP
rtbCloudInit(hints);

%% Full path to the object we are going to render
sceneFile = which('millenium-falcon.obj');

% Camera set to be 50 meters from an object distance
% This could be an array of cameras.
cameras = nnGenCameras('type',{'pinhole'},...
    'mode',{'radiance'},...
    'distance',50);

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

% dragonFile = which('Dragon.blend');
% dragonScene = mexximpCleanImport(dragonFile,...
%     'ignoreRootTransform',true,...
%     'flipUVs',true,...
%     'imagemagicImage','hblasins/imagemagic-docker',...
%     'toReplace',{'jpg','png','tga'},...
%     'options','-gamma 0.45',...
%     'targetFormat','exr',...
%     'makeLeftHanded',true,...
%     'flipWindingOrder',true,...
%     'workingFolder',resourceFolder);

% Import the millenial faclon, which is small
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

%% Initiate two poses 

objects(2).prefix   = '';    % Note that spaces or : are not allowed
objects(2).position = [10 10 0];
objects(2).orientation = 30;
objects(2).bndbox = mat2str(mexximpSceneBox(mfScene));
objects(1) = objects(2);
objects(1).orientation = 60;

objectArrangements = {objects(1), objects(2)};

% For each fixed configuration of the objects, we render a series of images for
% different camera properties. For example, this function sets particularly the position,
% lookAt and film distance variables.  Other slots are copied from the camera
% object itself.  The placedCameras combine the different object arrangements
% and cameras. The output is placedCameras{nCameras}(nArrangements).
placedCameras = nnPlaceCameras(cameras,objectArrangements);

%% Make values used for the Conditions file.
%
% Parameters are placed in a struct that will be gridded for the
% conditions.

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
        values(cntr,length(names)-1) = {objectArrangementFile};
        
        if strcmp(currentCameras(c).mode,'radiance')
            sceneId = sceneId+1;
        end
        cntr = cntr + 1;
    end
    
end

rtbWriteConditionsFile(conditionsFile,names,values);
% edit(conditionsFile);

%% Generate files and render
% We parallelize scene generation, not the rendering because
% PBRT automatically scales the number of processes to equal the
% number of cores.
%
nativeSceneFiles = rtbMakeSceneFiles(scene, 'hints', hints,...
    'conditionsFile',conditionsFile);

fprintf('Uploading data to gcloud\n');
rtbCloudUpload(hints, nativeSceneFiles);
fprintf('Data uploaded\n');

%%
fprintf('Batch rendering %d files\n',length(nativeSceneFiles));
rtbBatchRender(nativeSceneFiles, 'hints', hints);
fprintf('Jobs initiated\n');

radianceDataFiles = [];
while isempty(radianceDataFiles)
    radianceDataFiles = rtbCloudDownload(hints);
    pause(10);
end

% We aren't saving the radianceDataFiles for all the conditions.
% This means we have to rerun too many times.
%
% Also, we don't have the true irradiance level, just a
% noise-free irradiance.  So, we should aim to set the
% irradiance to a reasonable level here.
%
% load('radianceDataFiles');
%%
fprintf('Creating OI\n');
for i=1:length(radianceDataFiles)
    % chdir(fullfile(nnGenRootPath,'local'));
    % save('radianceDataFiles','radianceDataFiles');
    
    radianceData = load(radianceDataFiles{i});
    
    % Create an oi and set the parameters
    clear oiParams;
    oiParams.optics_name = lensType{lt};
    oiParams.optics_model = 'diffractionlimited';
    oiParams.fov = fov;
    switch ieParamFormat(lensType{lt})
        case 'pinhole'
            oiParams.optics_fnumber = 999;
        otherwise
            oiParams.optics_fnumber = fNumber(lt);
    end
    oiParams.optics_focalLength = filmDistanceVec(lt)*1e-3; % In meters
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




