%% Render a vase to test mask and bump textures.
% For testing purposes.

%% Choose batch renderer options.
clear;

hints.imageWidth = 320;
hints.imageHeight = 240;
hints.fov = deg2rad(5);
hints.recipeName = 'maskAndBumpTest';

hints.renderer = 'PBRT';

%% Load the test scene.

parentSceneFile = 'Data/crytekSmall.obj';
scene = mexximpCleanImport(parentSceneFile,...
    'toReplace',{'jpg','png'},...
    'targetFormat','exr');

%% Add camera and lights

% Add camera
% Note: Centralize does not seem to put camera in a good spot?
scene = mexximpCentralizeCamera(scene);

% Move camera
from = [10 5 6];
to = [0 0 0];
up = [0 1 0];
cameraTransform = mexximpLookAt(from, to, up);
cameraNodeSelector = strcmp(scene.cameras.name, {scene.rootNode.children.name});
scene.rootNode.children(cameraNodeSelector).transformation = cameraTransform;

scene = mexximpAddLanterns(scene);

%% Render
nativeSceneFiles = rtbMakeSceneFiles(scene, 'hints', hints);
radianceDataFiles = rtbBatchRender(nativeSceneFiles, 'hints', hints);

SRGBMontage = ...
    rtbMakeMontage(radianceDataFiles, ...
    'toneMapFactor', 10, ...
    'isScale', true, ...
    'hints', hints);

montageName = sprintf('Original');
rtbShowXYZAndSRGB([], SRGBMontage, montageName);
