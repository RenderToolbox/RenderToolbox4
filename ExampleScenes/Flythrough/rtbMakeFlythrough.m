%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
%% Fly the Millennium Falcon through a night club.

%% Choose example files.
clear;
nightClubFile = fullfile(rtbRoot(), 'ExampleScenes', 'Flythrough', 'NightClub', 'stonetee.obj');
millenniumFalconFile = fullfile(rtbRoot(), 'ExampleScenes', 'Flythrough', 'MilleniumFalcon', 'millenium-falcon.obj');


%% Choose batch renderer options.
hints.imageWidth = 320;
hints.imageHeight = 240;
hints.fov = deg2rad(60);
hints.recipeName = 'rtbMakeFlythrough';

hints.renderer = 'Mitsuba';
hints.batchRenderStrategy = RtbAssimpStrategy(hints);
hints.batchRenderStrategy.remodelPerConditionAfterFunction = @rtbFlythroughMexximpRemodeler;
hints.batchRenderStrategy.converter.remodelAfterMappingsFunction = @rtbFlythroughMitsubaRemodeler;

resourceFolder = rtbWorkingFolder('hints', hints, ...
    'folderName', 'resources');


%% Build a combined scene with lights and camera.
nightClub = mexximpCleanImport(nightClubFile, ...
    'workingFolder', resourceFolder);
falcon = mexximpCleanImport(millenniumFalconFile, ...
    'workingFolder', resourceFolder);

falconSize = 50;
insertTransform = mexximpScale(falconSize * [1 1 1]);
scene = mexximpCombineScenes(nightClub, falcon, ...
    'insertTransform', insertTransform, ...
    'insertPrefix', 'falcon');
scene = mexximpCentralizeCamera(scene, 'viewExterior', false);
[sceneBox, middlePoint] = mexximpSceneBox(scene);


%% Explore the scene geometry in a Matlab figure.
%mexximpScenePreview(scene);


%% Choose some waypoints for the camera and falcon movement.
falconPositionWaypoints = [ ...
    143 54 -44; ...
    124 81 -37; ...
    -15 72 -41; ...
    -59 63 -78; ...
    -31 26 -67; ...
    -10 4 -69];
falconTargetWaypoints = [ ...
    -150 49 -63; ...
    7 95 -44; ...
    -150 46 -129; ...
    32 9 -99; ...
    83 -20 -134; ...
    250 4 40];
falconUpWaypoints = [0 1 0; 0 1 0; 0 1 0; 0 1 0; 0 1 0; 0 1 0];
falconWaypointFrames = linspace(0, 1, 6);

cameraPositionWaypoints = [ ...
    68 70 57; ...
    68 60 57; ...
    68 40 57; ...
    68 20 57; ...
    68 15 57; ...
    68 15 57];
cameraTargetWaypoints = falconPositionWaypoints;
cameraUpWaypoints = falconUpWaypoints;
cameraWaypointFrames = linspace(0, 1, 6);


%% Interpolate waypoints for several frames.
nFrames = 12;
frames = linspace(0, 1, nFrames);

cameraPosition = spline(cameraWaypointFrames, cameraPositionWaypoints', frames);
cameraTarget = spline(cameraWaypointFrames, cameraTargetWaypoints', frames);
cameraUp = spline(cameraWaypointFrames, cameraUpWaypoints', frames);

falconPosition = spline(falconWaypointFrames, falconPositionWaypoints', frames);
falconTarget = spline(falconWaypointFrames, falconTargetWaypoints', frames);
falconUp = spline(falconWaypointFrames, falconUpWaypoints', frames);


%% Write conditions for each frame.
names = {'cameraPosition', 'cameraTarget', 'cameraUp', ...
    'falconPosition', 'falconTarget', 'falconUp'};
values = cell(nFrames, numel(names));
values(:,1) = num2cell(cameraPosition, 1);
values(:,2) = num2cell(cameraTarget, 1);
values(:,3) = num2cell(cameraUp, 1);
values(:,4) = num2cell(falconPosition, 1);
values(:,5) = num2cell(falconTarget, 1);
values(:,6) = num2cell(falconUp, 1);

workingFolder = rtbWorkingFolder('hints', hints);
conditionsFile = fullfile(workingFolder, 'FlythroughConditions.txt');
rtbWriteConditionsFile(conditionsFile, names, values);


%% Make Scene files.
hints.whichConditions = 3;
nativeSceneFiles = rtbMakeSceneFiles(scene, ...
    'conditionsFile', conditionsFile, ...
    'hints', hints);


%% Render and Show a montage.
radianceDataFiles = rtbBatchRender(nativeSceneFiles, ...
    'hints', hints);

[SRGBMontage, XYZMontage] = ...
    rtbMakeMontage(radianceDataFiles, ...
    'toneMapFactor', 10, ...
    'isScale', true, ...
    'hints', hints);
rtbShowXYZAndSRGB([], SRGBMontage, sprintf('%s (%s)', hints.recipeName, hints.renderer));
