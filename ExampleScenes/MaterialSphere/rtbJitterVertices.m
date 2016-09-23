function [scene, mappings] = rtbJitterVertices(scene, mappings, names, conditionValues, conditionNumber)
%% Jitter the XYZ position of each vertex in the scene by a few percent.
%
% This is an example of a "remodeler" function that we can use with
% RtbAssimpStrategy.  It's a hook that will be on invoked during batch
% processing and gives us a chance to modify the mexximp scene.
%
% I this case, we truncate and squish each mesh a bit.
%
% 2016 benjamin.heasly@gmail.com

% locate each mesh
for mm = 1:numel(scene.meshes)
    mesh = scene.meshes(mm);
    
    % break vertex positions into xyz components
    x = mesh.vertices(1:3:end);
    y = mesh.vertices(2:3:end);
    z = mesh.vertices(3:3:end);
    
    % get positions relative to mesh center
    centerX = mean(x);
    localX = x - centerX;
    centerY = mean(y);
    localY = y - centerY;
    centerZ = mean(z);
    localZ = z - centerZ;
    
    % truncate vertex positions
    clip = 0.8 * max(localX);
    localX(localX > clip) = clip;
    localX(localX < -clip) = -clip;
    localY(localY > clip) = clip;
    localY(localY < -clip) = -clip;
    localZ(localZ > clip) = clip;
    localZ(localZ < -clip) = -clip;
    
    % move back to new global coordinates
    x = localX + centerX;
    y = localY + centerY;
    z = localZ + centerZ;
    
    % assign back to the scene
    scene.meshes(mm).vertices(1:3:end) = x;
    scene.meshes(mm).vertices(2:3:end) = y;
    scene.meshes(mm).vertices(3:3:end) = z;
end
