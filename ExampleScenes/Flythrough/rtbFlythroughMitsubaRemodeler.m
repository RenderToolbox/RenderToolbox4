function nativeScene = rtbFlythroughMitsubaRemodeler(parentScene, nativeScene, mappings, names, conditionValues, conditionNumber)
%% Remodel the mexximp scene based on conditions values.

%% Light up the falcon engines.
% the engine is made from several separate mesh shapes
% find them by all by matching the name "falcong_r_body"
% which I found by clicking around the preview figure

engineShapeName = 'falcong_r_body';
engineSpectrum = '300:5 800:0';
nNested = numel(nativeScene.nested);
for nn = 1:nNested
    element = nativeScene.nested{nn};
    
    if ~strcmp(element.type, 'shape')
        continue;
    end
    
    if isempty(strfind(element.id, engineShapeName))
        continue;
    end
    
    rtbMMitsubaBlessAsAreaLight(element, 'radiance', engineSpectrum);
end

%% Light up a red strip light around the club.
% the strip light is made from several separate mesh shapes
% find them by each by matching their names
% which I found by clicking around the preview figure
% many shapes have similar names, which we want to ignore

stripShapeNames = {'Box09_', 'Box10_', 'Box11_', 'Box12_'};
stripSpectrum = '300:0 500:0 650:1 800:1';
nNested = numel(nativeScene.nested);
for nn = 1:nNested
    element = nativeScene.nested{nn};
    
    if ~strcmp(element.type, 'shape')
        continue;
    end
    
    for ss = 1:numel(stripShapeNames)
        shapeName = stripShapeNames{ss};
        if ~isempty(strfind(element.id, shapeName))
            rtbMMitsubaBlessAsAreaLight(element, 'radiance', stripSpectrum);
            break;
        end
    end
end

%% Configure Various Materials.
% most material names in these free scene files are uninformative:
%   wire_213154229, wire_008008136, 03___Default, etc.
% make some best guesses based on their names and presence of textures
% but generally just choose some arbitrary, fun Mitusba materials

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
            element.setProperty('specularReflectance', 'spectrum', 0.5);
            
        elseif ~isempty(strfind(elementId, 'glass')) ...
                || ~isempty(strfind(elementId, 'solar_panals')) ...
                ||~isempty(strfind(elementId, 'lights'))
            
            % make "glass", "solar panals" (sic), and "lights" be smooth glass
            element.pluginType = 'dielectric';
            
        else
            % make default, including the name "default", be rough metal
            element.pluginType = 'roughconductor';
            element.setProperty('alpha', 'float', 0.4);
            element.setProperty('material', 'string', 'Ir');
        end
        
    else
        
        % make all textured materials be rough plastic
        element.pluginType = 'roughplastic';
        texture.id = 'diffuseReflectance';
        element.setProperty('specularReflectance', 'spectrum', 0.2);
        element.setProperty('alpha', 'float', 0.5);
        
    end
end