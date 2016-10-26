function nativeScene = rtbFlythroughMitsubaRemodeler(parentScene, nativeScene, mappings, names, conditionValues, conditionNumber)
%% Remodel the mexximp scene based on conditions values.
%
% This is an example of how to modify the Mitsuba scene directly, with a
% "remodeler" hook funtion.  The function is called by the batch renderer
% when needed.  Various parameters are passed in, like the mexximp scene,
% the native scene, and names and values read from the conditions file.
%

%% Choose integrator and sampler.
integrator = nativeScene.find('integrator');
integrator.pluginType = 'volpath';

sampler = nativeScene.find('sampler');
sampler.pluginType = 'ldsampler';
sampler.setProperty('sampleCount', 'integer', 64);


%% Create some moody fog.
fog = MMitsubaElement('fog', 'medium', 'homogeneous');
fog.setProperty('material', 'string', 'Sugar Powder');
fog.setProperty('scale', 'float', 0.001);
nativeScene.prepend(fog);

camera = nativeScene.find('Camera', 'type', 'sensor');
camera.append(MMitsubaProperty.withData('', 'ref', 'id', fog.id));


%% Light up some meshes as area lights.
% I found the mesh names I wanted by clicking in mexximpScenePreview().

% the falcon's main engine
% I chose a "blue led" spectrum by reading g
engineShapeName = 'falcong_r_body';
engineNumbers = [300 0, 400 0.1, 450 1, 470 0.1, 550 0.5, 700 0.1, 800 0];
engineNumbers(2:2:end) = engineNumbers(2:2:end);
engineSpectrum = sprintf('%d:%f ', engineNumbers);

% a red neon light around the club
neonShapeNames = {'Box09_', 'Box10_', 'Box11_', 'Box12_'};
neonNumbers = [300 0, 570 0 580 1 600 0.1 615 0.4 640 0.3 690 0.1 710 0.3 725 0.1 800 0];
neonNumbers(2:2:end) = neonNumbers(2:2:end);
neonSpectrum = sprintf('%d:%f ', neonNumbers);

% soft white light on the ceiling
%  because otherwise it's really hard to light the room!
ceilingName = 'Box02_';
ceilingSpectrum = 0.2;

% identify meshes by name matching
%   many objects are made of multiple meshes, so multiple matches
nNested = numel(nativeScene.nested);
for nn = 1:nNested
    element = nativeScene.nested{nn};
    
    if ~strcmp(element.type, 'shape')
        continue;
    end
    
    % engines
    if ~isempty(strfind(element.id, engineShapeName))
        % bless this mesh as an area light emitter
        rtbMMitsubaBlessAsAreaLight(element, 'radiance', engineSpectrum);
        
        % connect the emmiter to the fog medium
        element.find('emitter').append(MMitsubaProperty.withData('', 'ref', 'id', fog.id));
        continue;
    end
    
    % neon lights
    for ss = 1:numel(neonShapeNames)
        shapeName = neonShapeNames{ss};
        if ~isempty(strfind(element.id, shapeName))
            rtbMMitsubaBlessAsAreaLight(element, 'radiance', neonSpectrum);
            element.find('emitter').append(MMitsubaProperty.withData('', 'ref', 'id', fog.id));
            continue;
        end
    end
    
    % back wall
    if ~isempty(strfind(element.id, ceilingName))
        rtbMMitsubaBlessAsAreaLight(element, 'radiance', ceilingSpectrum);
        element.find('emitter').append(MMitsubaProperty.withData('', 'ref', 'id', fog.id));
        continue;
    end
end


%% Configure Various Materials.
% most material names in these scene files are uninformative:
%   wire_213154229, wire_008008136, 03___Default, etc.
% make some best guesses based on their names and presence of textures
% but generally just choose some fun Mitusba materials

nNested = numel(nativeScene.nested);
for nn = 1:nNested
    element = nativeScene.nested{nn};
    elementId = lower(element.id);
    
    if ~strcmp(element.type, 'bsdf')
        continue;
    end
    
    texture = element.find('', 'type', 'texture');
    if isempty(texture)
        
        if ~isempty(strfind(elementId, 'wire'))
            
            % make "wire" be rough plastic parts of the night club
            element.pluginType = 'roughplastic';
            
            % rename reflectance to be diffuse reflectance, specifically
            element.find('reflectance').id = 'diffuseReflectance';
            
            % choose arbitrary specular reflectance
            element.setProperty('specularReflectance', 'spectrum', 0.25);
            
            % choose an arbitrary roughness
            element.setProperty('alpha', 'float', 0.6);
            
        elseif ~isempty(strfind(elementId, 'glass')) ...
                || ~isempty(strfind(elementId, 'solar_panals')) ...
                ||~isempty(strfind(elementId, 'lights'))
            
            % make "glass", "solar panals" (sic), and "lights" be smooth glass
            element.pluginType = 'dielectric';
            
        else
            % make default, including the name "default", be rough metal
            element.pluginType = 'roughconductor';
            element.setProperty('alpha', 'float', 0.1);
            element.setProperty('material', 'string', 'Mo');
        end
        
    else
        
        % make all textured materials be rough plastic
        element.pluginType = 'roughplastic';
        texture.id = 'diffuseReflectance';
        element.setProperty('specularReflectance', 'spectrum', 0.5);
        element.setProperty('alpha', 'float', 0.15);
        
    end
end