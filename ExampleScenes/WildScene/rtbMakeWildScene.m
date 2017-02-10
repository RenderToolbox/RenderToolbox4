%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% This is a contrived but reasonable story about trying to load and render
% a "wild" scene that we downloaded from the Web.  These scenes can be
% messy and sometimes broken.  The Assimp tool and our own mexximp
% utilities will help us deal with the messiness.
%
% Let's render a model of the Millenium Falcon!
%   http://tf3dm.com/3d-model/millenium-falcon-82947.html
%
% The model comes in a few different formats, so we'll load more than one
% and pick the one that looks best.
%
% The model won't contain lights or camera, so we'll use utilities to add
% these.
%
% We'll do a rendering with Mitsuba. Then we'll improve the camera position
% and render again.
%
% All of this should demonstrate how handy it is to have the entire scene
% loaded into memory and exposed to us as plain old Matlab structs.
%
% benhamin.heasly@gmail.com

clear;
clc;

pathHere = fileparts(which('rtbMakeWildScene'));

%% Choose batch processing options.
hints.imageWidth = 640;
hints.imageHeight = 480;
hints.recipeName = 'rtbMakeWildScene';
hints.renderer = 'Mitsuba';
hints.batchRenderStrategy = RtbAssimpStrategy(hints);

resourceFolder = rtbWorkingFolder('hints', hints, ...
    'folderName', 'resources');


%% Choose a scene format -- how does the 3DS Max scene look?
wildScene = fullfile(pathHere, 'millenium-falcon.3DS');
scene = mexximpCleanImport(wildScene, ...
    'workingFolder', resourceFolder);

% look at the vertices in a scatter plot
mexximpSceneScatter(scene);


%% Choose a better scene format -- the Wavefront Object.
wildScene = fullfile(pathHere, 'millenium-falcon.obj');
scene = mexximpCleanImport(wildScene, ...
    'workingFolder', resourceFolder);

% look at the vertices in a scatter plot
mexximpSceneScatter(scene);


%% Look at a struct "dump" of the scene
disp(scene);

% look at the struct in more detail
%   nice utility from NC
disp(displayNicelyFormattedStruct(scene, 'scene', '', 50));


%% Add missing lights and camera.

% add a camera if missing
% find the scene bounding box and center
% point the camera at the center
% back up so fov contains bounding box
scene = mexximpCentralizeCamera(scene);

% add point lights in a cube arrangement around the camera
scene = mexximpAddLanterns(scene);

% look at the struct, now with lights and camera
disp(displayNicelyFormattedStruct(scene, 'scene', '', 50));


%% Render with Mitsuba.

% make a scene file and render it
hints.fov = scene.cameras(1).horizontalFov;
nativeSceneFiles = rtbMakeSceneFiles(scene, 'hints', hints);
radianceDataFiles = rtbBatchRender(nativeSceneFiles, 'hints', hints);

% convert to sRGB for viewing
toneMapFactor = 100;
isScale = true;
montageName = sprintf('rtbWildSceneHeadOn (%s)', hints.renderer);
montageFile = [montageName '.png'];
sRgb = rtbMakeMontage(radianceDataFiles, ...
    'outFile', montageFile, ...
    'toneMapFactor', toneMapFactor, ...
    'isScale', isScale, ...
    'hints', hints);
rtbShowXYZAndSRGB([], sRgb, montageName);


%% Choose a nicer viewing axis and render again.
scene = mexximpCleanImport(wildScene, ...
    'workingFolder', resourceFolder, ...
    'flipUVs', true);
viewAxis = [-1 1 1];
scene = mexximpCentralizeCamera(scene, 'viewAxis', viewAxis ./ norm(viewAxis));
scene = mexximpAddLanterns(scene);

% render with Mitsuba
nativeSceneFiles = rtbMakeSceneFiles(scene, 'hints', hints);
radianceDataFiles = rtbBatchRender(nativeSceneFiles, 'hints', hints);

% convert to sRGB for viewing
toneMapFactor = 100;
isScale = true;
montageName = sprintf('rtbWildSceneOblique (%s)', hints.renderer);
montageFile = [montageName '.png'];
sRgb = rtbMakeMontage(radianceDataFiles, ...
    'outFile', montageFile, ...
    'toneMapFactor', toneMapFactor, ...
    'isScale', isScale, ...
    'hints', hints);
rtbShowXYZAndSRGB([], sRgb, montageName);
