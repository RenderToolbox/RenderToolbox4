function [scene, mappings] = rtbFlythroughRemodeler(scene, mappings, names, conditionValues, conditionNumber)
%% Remodel the mexximp scene based on conditoins values.

% build a lookat for the camera
from = rtbGetNamedNumericValue(names, conditionValues, 'from', []);
to = rtbGetNamedNumericValue(names, conditionValues, 'to', []);
up = rtbGetNamedNumericValue(names, conditionValues, 'up', []);
cameraTransform = mexximpLookAt(from, to, up);

% find the camera node
cameraNodeInfo = mexximpFindElement(scene, 'Camera', 'type', 'nodes');
cameraNodeIndex = cameraNodeInfo.path{end};
scene.rootNode.children(cameraNodeIndex).transformation = cameraTransform;
