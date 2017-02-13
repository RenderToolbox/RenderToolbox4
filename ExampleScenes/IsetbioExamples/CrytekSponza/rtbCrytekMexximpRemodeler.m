function [scene, mappings] = rtbCrytekMexximpRemodeler(scene, mappings, names, conditionValues, conditionNumber)

% This is an example of how to modify the incoming mexximp scene directly,
% with a "remodeler" hook funtion.  It modifies the scene struct that will
% be used during subsequent processing and rendering.
%
% The function is called by the batch renderer when needed.  Various
% parameters are passed in, like the mexximp scene, the native scene, and
% names and values read from the conditions file.

%% Get condition values

lightRotateAxis = rtbGetNamedNumericValue(names, conditionValues, 'lightRotateAxis', []);
lightRotation = rtbGetNamedNumericValue(names, conditionValues, 'lightRotation', []);

cameraPosition = rtbGetNamedNumericValue(names, conditionValues, 'cameraLocation', []);
cameraTarget = rtbGetNamedNumericValue(names, conditionValues, 'cameraTarget', []);
cameraUp = rtbGetNamedNumericValue(names, conditionValues, 'cameraUp', []);

%% Rotate the area light

rotateTransform = mexximpRotate(lightRotateAxis,lightRotation); 
areaLightNodeSelector = strcmp({scene.rootNode.children.name}, 'AreaLight'); % I found this name manually
scene.rootNode.children(areaLightNodeSelector).transformation = scene.rootNode.children(areaLightNodeSelector).transformation * rotateTransform; 

%% Move camera

% build a lookat for the camera
cameraTransform = mexximpLookAt(cameraPosition, cameraTarget, cameraUp);

% find the camera node
cameraNodeSelector = strcmp({scene.rootNode.children.name}, 'Camera');
scene.rootNode.children(cameraNodeSelector).transformation = cameraTransform;

end