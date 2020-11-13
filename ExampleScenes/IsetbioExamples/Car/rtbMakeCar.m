%% Render a Mercedes SLS and optionally display as an isetbio optical image.
%
% This only works with renderer 'PBRT'.

% Henryk Blasinski
% 
% 08/12/17  dhb  Made isetbio stuff conditional on isetbio being installed.
%                Write out a png of the image in any case.
%                Some cosmetic changes.
%                Rename rtbMakeCar... helper functions to rtbCar....  rtbMake...
%                  has a special status for our examples, and should be used only
%                  as the prefix for top level directories.
% 11/12/20  dhb  Initialize isetbio at start so as not to clear variables
%                needed if it is initialized later.

%% Initialize.
%
% If you want to use isetbio and have TbTb installed, but not isetbio, type:
%    tbUse('isetbio','reset','as-is');
close all; clear;
if (exist('ieInit','file'))
    % Initialize isetbio
    ieInit;
end

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
hints.batchRenderStrategy.remodelPerConditionAfterFunction = @rtbCarMexximpRemodeller;
hints.batchRenderStrategy.converter.remodelAfterMappingsFunction = @rtbCarPBRTRemodeller;

parentSceneFile = fullfile(rtbRoot(), 'ExampleScenes', 'IsetbioExamples', ...
    'Car', 'Models', 'Mercedes SLS', 'sls_amg.obj');

resources = rtbWorkingFolder( ...
    'folderName', 'resources', ...
    'hints', hints);

conditionsFile = fullfile(resources, 'rtbMakeCarConditions.txt');

%% Save needed data to resources folder.
[waves, daylight] = rtbReadSpectrum('D65.spd');
rtbWriteSpectrumFile(waves,1e4*daylight,fullfile(resources,'SunLight.spd'));

%% Load the scene.
[scene, elements] = mexximpCleanImport(parentSceneFile,...
    'ignoreRootTransform',true,...
    'flipUVs',false,...
    'exrToolsImage','rendertoolbox/imagemagick',...
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
                    values(cntr,1) = {'Car'};
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

%% Images for display
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
% F-number or the FOV. Now all that info is held in the remodeler. How
% should we move that info out from the remodeler into the oi?
if (exist('ieInit','file') 
    % Create the optical image.
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
end


