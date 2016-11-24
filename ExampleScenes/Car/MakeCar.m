%%% RenderToolbox3 Copyright (c) 2012-2013 The RenderToolbox3 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox3/wiki/About-Us
%%% RenderToolbox3 is released under the MIT License.  See LICENSE.txt.

%% Scene description

% Henryk Blasinski
close all;
clear all;
clc;

ieInit;

%% Simulation parameters

filmDiag = 20;
targetDistance = 5000;


nSamples = 256;

conditionsFile = 'MakeCarConditions.txt';

%%
    
parentSceneFile = fullfile('Models','Mercedes SLS','sls_amg.obj');
% parentSceneFile = fullfile('Models','Renault Megane RS','exportedMegane.obj');

% Renderer options.
hints.imageWidth = 640;
hints.imageHeight = 480;
hints.renderer = 'PBRT'; % We're only using PBRT right now
hints.recipeName = 'MakeCar';
hints.copyResources = 1;
hints.batchRenderStrategy = RtbAssimpStrategy(hints);
hints.batchRenderStrategy.remodelPerConditionAfterFunction = @MakeCarMexximpRemodeller;
hints.batchRenderStrategy.converter.remodelAfterMappingsFunction = @MakeCarPBRTRemodeller;

% Change the docker container
hints.batchRenderStrategy.renderer.pbrt.dockerImage = 'vistalab/pbrt-v2-spectral';

resources = rtbWorkingFolder('folderName','resources', 'hints', hints);
root = rtbWorkingFolder('hints',hints);






%% Save data to resources folder
[waves, daylight] = rtbReadSpectrum('D65.spd');
rtbWriteSpectrumFile(waves,1e4*daylight,fullfile(resources,'SunLight.spd'));


%% Choose files to render


[scene, elements] = mexximpCleanImport(parentSceneFile,...
                                    'ignoreRootTransform',true,...
                                    'flipUVs',false,...
                                    'exrToolsImage','hblasins/imagemagic-docker',...
                                    'convertToLeftHanded',true);
                                    % 'toReplace',{'tga'},...
                                    % 'targetFormat','exr',...
                                    
                                    


%% Start rendering
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
%%
radianceDataFiles = rtbBatchRender(nativeSceneFiles, 'hints', hints);
 
for i=1:length(radianceDataFiles)
    radianceData = load(radianceDataFiles{i});
                
    % Create an oi
    oiParams.lensType = 'pinhole';
    oiParams.filmDistance = values{i,4};
    oiParams.filmDiag = 20;
    
    
    oi = BuildOI(radianceData.multispectralImage, [], oiParams);
    oi = oiSet(oi,'name',values{i,1});
    
    ieAddObject(oi);
    oiWindow;
end

