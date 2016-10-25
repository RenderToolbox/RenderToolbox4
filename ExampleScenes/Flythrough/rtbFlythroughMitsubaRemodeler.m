function nativeScene = rtbFlythroughMitsubaRemodeler(parentScene, nativeScene, mappings, names, conditionValues, conditionNumber)
%% Remodel the mexximp scene based on conditions values.
%
% This is an example of how to modify the Mitsuba scene directly, with a
% "remodeler" hook funtion.  The function is called by the batch renderer
% when needed.  Various parameters, like the original and native scenes,
% and names and values read from the conditions file, are passed in.
%

%% Choose integrator and sampler.
integrator = nativeScene.find('integrator');
integrator.pluginType = 'bdpt';

sampler = nativeScene.find('sampler');
sampler.pluginType = 'independent';
sampler.setProperty('sampleCount', 'integer', 256);


%% Let fog permeate the whole night club.
fog = MMitsubaElement('fog', 'medium', 'homogeneous');
%fog.append(MMitsubaProperty.withValue('material', 'string', 'Shampoo'));
fog.append(MMitsubaProperty.withValue('scale', 'float', 0.0001));
nativeScene.prepend(fog);

camera = nativeScene.find('Camera', 'type', 'sensor');
camera.append(MMitsubaProperty.withData('', 'ref', 'id', fog.id));


%% Light up some meshes as area lights.
% I found the mesh names I wanted by clicking in mexximpScenePreview().

% the falcon's main engine
% I chose a "blue led" spectrum by reading g
engineShapeName = 'falcong_r_body';
engineNumbers = [300 0, 400 0.1, 450 1, 470 0.1, 550 0.5, 700 0.1, 800 0];
engineNumbers(2:2:end) = 0.1 * engineNumbers(2:2:end);
engineSpectrum = sprintf('%d:%f ', engineNumbers);

% a red neon light around the club
neonShapeNames = {'Box09_', 'Box10_', 'Box11_', 'Box12_'};
neonNumbers = [300 0, 570 0 580 1 600 0.1 615 0.4 640 0.3 690 0.1 710 0.3 725 0.1 800 0];
neonNumbers(2:2:end) = 0.0075 * neonNumbers(2:2:end);
neonSpectrum = sprintf('%d:%f ', neonNumbers);

% harsh white lights on the wall
wallShapeNames = {'Box25_', 'Box149_', 'Box151_', 'Box150_', 'Window'};
wallSpectrum = 0.01;

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
        rtbMMitsubaBlessAsAreaLight(element, 'radiance', engineSpectrum);
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
    
    % white lights
    for ss = 1:numel(wallShapeNames)
        shapeName = wallShapeNames{ss};
        if ~isempty(strfind(element.id, shapeName))
            rtbMMitsubaBlessAsAreaLight(element, 'radiance', wallSpectrum);
            element.find('emitter').append(MMitsubaProperty.withData('', 'ref', 'id', fog.id));
            continue;
        end
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