% Render a Mercedes SLS and display as an isetbio optical image.
%
% Henryk Blasinski


%% Initialize.

% tbUse('isetbio','reset','as-is');
close all;
clear;
clc;
ieInit;


%% Choose simulation parameters.
filmDiag = 20;
targetDistance = 5000;
nSamples = 256;

%% Choose Batch Render Options.
hints.imageWidth = 320;
hints.imageHeight = 240;
hints.renderer = 'PBRT';
hints.recipeName = 'Car';
hints.batchRenderStrategy = RtbAssimpStrategy(hints);
hints.batchRenderStrategy.remodelPerConditionAfterFunction = @rtbMakeCarMexximpRemodeller;
hints.batchRenderStrategy.converter.remodelAfterMappingsFunction = @rtbMakeCarPBRTRemodeller;

% Change the docker container
hints.batchRenderStrategy.renderer.pbrt.dockerImage = 'vistalab/pbrt-v2-spectral';

parentSceneFile = fullfile(rtbRoot(), 'ExampleScenes', 'IsetbioExamples', ...
    'Car', 'Models', 'Mercedes SLS', 'sls_amg.obj');

resources = rtbWorkingFolder( ...
    'folderName', 'resources', ...
    'hints', hints);

conditionsFile = fullfile(resources, 'rtbMakeCarConditions.txt');


%% Save data to resources folder.
[waves, daylight] = rtbReadSpectrum('D65.spd');
rtbWriteSpectrumFile(waves,1e4*daylight,fullfile(resources,'SunLight.spd'));


%% Load the scene.
[scene, elements] = mexximpCleanImport(parentSceneFile,...
    'ignoreRootTransform',true,...
    'flipUVs',false,...
    'exrToolsImage','hblasins/imagemagic-docker',...
    'convertToLeftHanded',true, ...
    'workingFolder', resources);


%% Write conditions file and scene files.
condition = {'clear'};
daylight = {'off'};
headlights = {'on'};
taillights = {'on'};
nConditions = length(targetDistance)*length(condition);

names = {'imageName','mode','pixelSamples','volumeStep','filmDist','filmDiag','cameraDistance','daylight','headlights','taillights'};

values = cell(nConditions,numel(names));
cntr = 1;
for d=1:length(daylight)
    for h=1:length(headlights)
        for t=1:length(taillights)
            for td = targetDistance
                for c=1:length(condition)
                    
                    % Generate condition entries
                    values(cntr,1) = {'someName'};
                    values(cntr,2) = condition(c);
                    values(cntr,3) = num2cell(nSamples,1);
                    values(cntr,4) = num2cell(50,1);
                    values(cntr,5) = num2cell(((0.8*filmDiag*td)/5000),1);
                    values(cntr,6) = num2cell(filmDiag,1);
                    values(cntr,7) = num2cell(td,1);
                    values(cntr,8) = daylight(d);
                    values(cntr,9) = headlights(h);
                    values(cntr,10) = taillights(t);
                    
                    cntr = cntr+1;
                end
            end
        end
    end
end

rtbWriteConditionsFile(conditionsFile,names,values);
nativeSceneFiles = rtbMakeSceneFiles(scene, 'hints', hints, ...
    'conditionsFile',conditionsFile);


%% Render!
radianceDataFiles = rtbBatchRender(nativeSceneFiles, 'hints', hints);


%% Display as an isetbio optical image.

% TODO: Ideally, we want to use BuildOI here. Unfortunately, we don't have
% the "oiParameters" structure anymore. In RTB4, this structure held
% information about the film distance, diagonal, etc. We could then use
% this information to fill in parameter info in the OI, such as the
% F-number or the FOV. Now all that info is held in the remodeler. How
% should we move that info out from the remodeler into the oi?

for i=1:length(radianceDataFiles)
    radianceData = load(radianceDataFiles{i});
    photons = radianceData.multispectralImage;
    
    oiName = sprintf('%s_%i',hints.recipeName,i);
    
    % Create an oi
    oi = oiCreate;
    oi = initDefaultSpectrum(oi);
    oi = oiSet(oi, 'photons', single(photons));
    oi = oiSet(oi, 'name',oiName);
    
    vcAddAndSelectObject(oi);
end

oiWindow;

