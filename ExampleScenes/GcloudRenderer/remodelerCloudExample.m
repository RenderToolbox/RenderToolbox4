function [scene, mappings] = remodelerCloudExample(scene, mappings, names, conditionValues, conditionNumber )
% Remodeler used usually in remodelPerConditionAfterFunction
%
% Typically, this is referred to by a function handle in the hints slot
%  hints.batchRenderStrategy.remodelPerConditionAfterFunction = ...
%      @remodelerPBRTCloudExample
%
%
% Inputs
%   scene           - Assimp scene with a camera attached
%   mappings -
%   names           - From conditions file
%   conditionValues - Values for the conditions file
%   conditionNumber - Not yet used
%
% Typically pointed to by
%    hints.batchRenderStrategy.remodelPerConditionAfterFunction
%
% At this point conditionNumber is not used but it might be used later for
% information.
%
% HB, SCIEN STanford, 2017

%% PROGRAMMING TODO
% The 1000 is just annoying and makes units better but we need a general fix.
% Maybe because we are using millimeters everywhere.

%% Look for specific names in the conditions and acting

% Location (in meters) of the camera in the scene
cameraPosition = rtbGetNamedNumericValue(names,conditionValues,'position',[]);

% Direction the camera is looking at
cameraLookAt = rtbGetNamedNumericValue(names,conditionValues,'lookAt',[]);

% Pan tilt and roll
cameraPTR = rtbGetNamedNumericValue(names,conditionValues,'PTR',[0 0 0]);

% Object position file
objMovementFile = rtbGetNamedValue(names,conditionValues,'objPosFile','');


%% Add a camera

% The scene does not yet have a camera.  
scene = mexximpCentralizeCamera(scene);

[~, sceneMiddlePoint] = mexximpSceneBox(scene);

lookUp = [0 0 -1];
cameraLookDir = cameraLookAt - cameraPosition;
cameraPTR = deg2rad(cameraPTR);

transformation = mexximpLookAt(1000*cameraPosition,1000*cameraLookAt,lookUp);
ptrTransform = mexximpPTR(cameraPTR(1), cameraPTR(2), cameraPTR(3), cameraLookDir, lookUp);

cameraId = strcmp({scene.rootNode.children.name},'Camera');
scene.rootNode.children(cameraId).transformation = ...
    transformation*mexximpTranslate(-1000*cameraPosition)*ptrTransform*mexximpTranslate(1000*cameraPosition);


%% Translate the objects

objects = loadjson(objMovementFile,'SimplifyCell',1);

for i=1:length(scene.rootNode.children)
    for o=1:length(objects)
        if isempty(strfind(scene.rootNode.children(i).name,objects(o).prefix)) == false
    
            position = objects(o).position*1000;
            orientation = objects(o).orientation;
            
            scene.rootNode.children(i).transformation = scene.rootNode.children(i).transformation*...
           mexximpRotate([0 0 -1],deg2rad(orientation))*mexximpTranslate(position);
        end
   end
end

% Add directional light (named 'SunLight');
ambient = mexximpConstants('light');
ambient.position = [0 0 0]';
ambient.type = 'directional';
ambient.name = 'SunLight';
ambient.lookAtDirection = sceneMiddlePoint;  % Direction the light points to
ambient.ambientColor = 10000*[1 1 1]';
ambient.diffuseColor = 10000*[1 1 1]';
ambient.specularColor = 10000*[1 1 1]';
ambient.constantAttenuation = 1;
ambient.linearAttenuation = 0;
ambient.quadraticAttenuation = 1;
ambient.innerConeAngle = 0;
ambient.outerConeAngle = 0;

scene.lights = [scene.lights, ambient];

ambientNode = mexximpConstants('node');
ambientNode.name = ambient.name;
ambientNode.transformation = eye(4);

scene.rootNode.children = [scene.rootNode.children, ambientNode];

end

