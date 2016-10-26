function [scene, mappings] = rtbFlythroughMexximpRemodeler(scene, mappings, names, conditionValues, conditionNumber)
%% Remodel the mexximp scene based on conditions values.
%
% This is an example of how to modify the incoming mexximp scene directly,
% with a "remodeler" hook funtion.  It modifies the scene struct that will
% be used during subsequent processing and rendering.
%
% The function is called by the batch renderer when needed.  Various
% parameters are passed in, like the mexximp scene, the native scene, and
% names and values read from the conditions file.
%

% build a lookat for the camera
cameraPosition = rtbGetNamedNumericValue(names, conditionValues, 'cameraPosition', []);
cameraTarget = rtbGetNamedNumericValue(names, conditionValues, 'cameraTarget', []);
cameraUp = rtbGetNamedNumericValue(names, conditionValues, 'cameraUp', []);
cameraTransform = mexximpLookAt(cameraPosition, cameraTarget, cameraUp);

% build a lookat for the falcon
falconPosition = rtbGetNamedNumericValue(names, conditionValues, 'falconPosition', []);
falconTarget = rtbGetNamedNumericValue(names, conditionValues, 'falconTarget', []);
falconUp = rtbGetNamedNumericValue(names, conditionValues, 'falconUp', []);
falconTransform = mexximpLookAt(falconPosition, falconTarget, falconUp);

% find the camera node
cameraNodeSelector = strcmp({scene.rootNode.children.name}, 'Camera');
scene.rootNode.children(cameraNodeSelector).transformation = cameraTransform;

% find falcon nodes
for nn = 1:numel(scene.rootNode.children)
    if strncmp('falcon', scene.rootNode.children(nn).name, 6)
        scene.rootNode.children(nn).transformation = ...
            scene.rootNode.children(nn).transformation * falconTransform;
    end
end

% for fun, preview each condition in a Matlab figure
mexximpScenePreview(scene);
drawnow();
