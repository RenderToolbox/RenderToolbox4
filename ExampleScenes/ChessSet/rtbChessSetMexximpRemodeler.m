function [scene, mappings] = rtb360MexximpRemodeler(scene, mappings, names, conditionValues, conditionNumber)

% This is an example of how to modify the incoming mexximp scene directly,
% with a "remodeler" hook funtion.  It modifies the scene struct that will
% be used during subsequent processing and rendering.
%
% The function is called by the batch renderer when needed.  Various
% parameters are passed in, like the mexximp scene, the native scene, and
% names and values read from the conditions file.

%% Place the camera at a good location

% The following camera location was found by manually moving the camera in
% the Blender scene and then copying camera values over.

cameraPosition = [466 -163 286];
cameraTarget = [39.27 -6.69 11.95];
cameraUp = [0 0 1];

% build a lookat for the camera
cameraTransform = mexximpLookAt(cameraPosition, cameraTarget, cameraUp);

% find the camera node
cameraNodeSelector = strcmp({scene.rootNode.children.name}, 'Camera');
scene.rootNode.children(cameraNodeSelector).transformation = cameraTransform;


end