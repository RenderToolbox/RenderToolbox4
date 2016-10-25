function [scene, mappings] = rtbFlythroughMexximpRemodeler(scene, mappings, names, conditionValues, conditionNumber)
%% Remodel the mexximp scene based on conditions values.

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
%mexximpScenePreview(scene);
%drawnow();
