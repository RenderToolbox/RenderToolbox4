function [ scene, mappings ] = rtbCarMexximpRemodeller( scene, mappings, names, conditionValues, conditionNumber)
%% rtbCarMexximpRemodeller  Helper function for rtbMakeCar example.

% 08/12/17  dhb  Rename.  Add one line header comment.
%           dhb  Delete commented out code.

distance = rtbGetNamedNumericValue(names,conditionValues,'cameraDistance',[]);
headlights = rtbGetNamedValue(names,conditionValues,'headlights',[]);
daylight = rtbGetNamedValue(names,conditionValues,'daylight',[]);

% Point the camera towards the scene
[scene, camera, cameraNode] = mexximpCentralizeCamera(scene,'viewAxis',[-1 0 0],...
    'viewUp',[0 1 0]);

% Scale, so that a car is about 5m in diagonal
box = mexximpSceneBox(scene);
diagonal = sqrt(sum((box(:,1)-box(:,2)).^2));
scaleFactor = 5000/diagonal;

for i=1:length(scene.meshes)
    scene.meshes(i).vertices = mexximpApplyTransform(scene.meshes(i).vertices,mexximpScale([1 1 1]*scaleFactor));
end

newPosition = [0, distance, -1500]';

cameraSelector = strcmp('Camera',{scene.rootNode.children.name});
scene.rootNode.children(cameraSelector).transformation = mexximpLookAt(newPosition,[0 0 0]',[0 0 -1]');

% Ambient illumination
if strcmp(daylight,'on')
    
    ambient = mexximpConstants('light');
    ambient.position = [0 0 0]';
    ambient.type = 'directional';
    ambient.name = 'SunLight';
    ambient.lookAtDirection = [0 0 -1]';
    ambient.ambientColor = 10*[1 1 1]';
    ambient.diffuseColor = 10*[1 1 1]';
    ambient.specularcolor = 10*[1 1 1]';
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
    
    ambient = mexximpConstants('light');
    ambient.position = [0 0 0]';
    ambient.type = 'directional';
    ambient.name = 'SunLight5';
    ambient.lookAtDirection = [-1 -1 0.5]';
    ambient.ambientColor = 10*[1 1 1]';
    ambient.diffuseColor = 10*[1 1 1]';
    ambient.specularcolor = 10*[1 1 1]';
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

%% Headlights
if strcmp(headlights,'on')
    headlightLeft = mexximpConstants('light');
    headlightLeft.position = [0 0 0]';
    headlightLeft.type = 'spot';
    headlightLeft.name = 'headlightLeft';
    headlightLeft.lookAtDirection = [-0.2, -sign(distance), 0.2]';
    headlightLeft.ambientColor = 1e11*[0.9 0.9 1]';
    headlightLeft.diffuseColor = 1e11*[0.9 0.9 1]';
    headlightLeft.specularcolor = 1e11*[0.9 0.9 1]';
    headlightLeft.constantAttenuation = 1;
    headlightLeft.linearAttenuation = 0;
    headlightLeft.quadraticAttenuation = 0;
    headlightLeft.innerConeAngle = deg2rad(25);
    headlightLeft.outerConeAngle = deg2rad(40);
    
    scene.lights = [scene.lights, headlightLeft];
    
    headlightNode = mexximpConstants('node');
    headlightNode.name = headlightLeft.name;
    
    lightPosition = [700, sign(distance)*(abs(distance) - 1000), -500];
    
    headlightNode.transformation = mexximpTranslate(lightPosition);    
    
    scene.rootNode.children = [scene.rootNode.children, headlightNode];
    
    headlightRight = mexximpConstants('light');
    headlightRight.position = [0 0 0]';
    headlightRight.type = 'spot';
    headlightRight.name = 'headlightRight';
    headlightRight.lookAtDirection = [0.2, -sign(distance), 0.2]';
    headlightRight.ambientColor = 1e11*[0.9 0.9 1]';
    headlightRight.diffuseColor = 1e11*[0.9 0.9 1]';
    headlightRight.specularcolor = 1e11*[0.9 0.9 1]';
    headlightRight.constantAttenuation = 1;
    headlightRight.linearAttenuation = 0;
    headlightRight.quadraticAttenuation = 0;
    headlightRight.innerConeAngle = deg2rad(25);
    headlightRight.outerConeAngle = deg2rad(40);
    
    scene.lights = [scene.lights, headlightRight];
    
    headlightNode = mexximpConstants('node');
    headlightNode.name = headlightRight.name;
    
    lightPosition = [-700, sign(distance)*(abs(distance) - 1000), -500];
    
    headlightNode.transformation = mexximpTranslate(lightPosition);
    
    scene.rootNode.children = [scene.rootNode.children, headlightNode];

end


end

