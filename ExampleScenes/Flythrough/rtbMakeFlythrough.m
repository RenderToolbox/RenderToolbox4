%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
%% Fly the Millenium Falcon through a night club.
clear;

%% Choose example files.
parentSceneFile = fullfile(rtbRoot(), 'ExampleScenes', 'Flythrough', 'NightClub', 'stonetee.obj');

%% Add lights and camera.
scene = mexximpCleanImport(parentSceneFile);
scene = mexximpCentralizeCamera(scene, 'viewExterior', false);
scene = mexximpAddLanterns(scene);

%% Choose batch renderer options.
hints.imageWidth = 320;
hints.imageHeight = 240;
hints.fov = deg2rad(60);
hints.recipeName = 'rtbMakeFlythrough';

hints.renderer = 'Mitsuba';
hints.batchRenderStrategy = RtbAssimpStrategy(hints);
hints.batchRenderStrategy.remodelPerConditionAfterFunction = @rtbFlythroughRemodeler;

%% Choose some camera positions.
nPositions = 60;

names = {'from', 'to', 'up'};
nNames = numel(names);
values = cell(nPositions, nNames);

[sceneBox, middlePoint] = mexximpSceneBox(scene);
startTo = [110 63 -28];
endTo = [10 1 -35];
startFrom = middlePoint + [0 40 0]';
endFrom = middlePoint - [0 30 0]';
for pp = 1:nPositions
    weight = (pp-1) / (nPositions - 1);
    
    % from
    values{pp, 1} = startFrom * (1-weight) + endFrom * weight;
    
    % to
    values{pp, 2} = startTo * (1-weight) + endTo * weight;
    
    % up
    values{pp, 3} = [0 1 0];
end

workingFolder = rtbWorkingFolder('hints', hints);
conditionsFile = fullfile(workingFolder, 'FlythroughConditions.txt');
rtbWriteConditionsFile(conditionsFile, names, values);


%% Render.
nativeSceneFiles = rtbMakeSceneFiles(scene, ...
    'conditionsFile', conditionsFile, ...
    'hints', hints);

radianceDataFiles = rtbBatchRender(nativeSceneFiles, ...
    'hints', hints);

%% Convert renderings to sRGB images.

% choose one scale factor to use for all images
rendering = load(radianceDataFiles{1});
[~, ~, ~, scaleFactor] = rtbMultispectralToSRGB( ...
    rendering.multispectralImage, ...
    rendering.S, ...
    'toneMapFactor', 10, ...
    'isScale', true);

frameCell = cell(1, nPositions);
for ff = 1:nPositions
    rendering = load(radianceDataFiles{ff});
    
    sRGBImage = rtbMultispectralToSRGB( ...
        rendering.multispectralImage, ...
        rendering.S, ...
        'toneMapFactor', 10, ...
        'scaleFactor', scaleFactor);
    
    frameCell{ff} = uint8(sRGBImage);
end

%% Display images like a movie.
for ff = 1:nPositions
    imshow(frameCell{ff});
    pause(1/30);
end

