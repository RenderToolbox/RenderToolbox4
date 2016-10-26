function mitsubaScene = rtbApplyMMitsubaGenericMappings(mitsubaScene, mappings)
%% Apply mappings with the "Generic" destination directly to the scene.
%
% mitsubaScene = rtbApplyMMitsubaGenericMappings(mitsubaScene, mappings)
% adjusts the given mMitsuba scene in place, by applying the given Generic
% mappings as scene adjustments.
%
% This generally amounts to translating Generic type names and values to
% Mitsuba type names and values, locating scene elements of the scene
% object and updating their field values based on the mappings properties.
%
% mitsubaScene = rtbApplyMMitsubaGenericMappings(mitsubaScene, mappings)
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('mitsubaScene', @isobject);
parser.addRequired('mappings', @isstruct);
parser.parse(mitsubaScene, mappings);
mitsubaScene = parser.Results.mitsubaScene;
mappings = parser.Results.mappings;

%% Select only RenderToolbox "Generic" mappings.
isGeneric = strcmp('Generic', {mappings.destination});
genericMappings = mappings(isGeneric);
nGenericMappings = numel(genericMappings);

%% Update the scene, one mapping at a time.
for mm = 1:nGenericMappings
    
    %% Translate Generic type names to Mitsuba type names.
    %   this allows us to find scene elements by Mitsuba element type
    mapping = genericMappings(mm);
    switch mapping.broadType
        case 'meshes'
            type = 'shape';
        case 'lights'
            type = 'emitter';
        case 'materials'
            type = 'bsdf';
        case {'floatTextures', 'spectrumTextures'}
            type = 'texture';
        otherwise
            warning('applyMMitsubaGenericMappings:invalidBroadType', ...
                'Unrecognized broadType <%s> for Generic mapping.', ...
                mapping.broadType);
            continue;
    end
    
    %% Create/find/delete a scene element.
    element = rtbApplyMMitsubaMappingOperation(mitsubaScene, mapping, 'type', type);
    if isempty(element)
        continue;
    end
    
    %% Apply Generic mappings special operations.
    switch mapping.operation
        case 'blessAsAreaLight'
            radiance = rtbGetMappingProperty(mapping, 'intensity', '300:1 800:1');
            element = rtbMMitsubaBlessAsAreaLight(element, ...
                'radiance', radiance);
            
        case 'blessAsBumpMap'
            textureName = rtbGetMappingProperty(mapping, 'texture', '');
            scale = rtbGetMappingProperty(mapping, 'scale', 1);
            element = rtbMMitsubaBlessAsBumpMap(element, textureName, mitsubaScene, ...
                'scale', scale);
    end
    
    %% Apply Generic mappings properties as PBRT element parameters.
    switch mapping.broadType
        case 'materials'
            switch mapping.specificType
                case 'matte'
                    element.pluginType = 'diffuse';
                    setSpectrumOrTexture(element, mapping, ...
                        'diffuseReflectance', 'reflectance', 'spectrum', '300:0 800:0');
                    
                case 'anisoward'
                    element.pluginType = 'ward';
                    element.setProperty('variant', 'string', 'balanced');
                    setSpectrumOrTexture(element, mapping, ...
                        'diffuseReflectance', 'diffuseReflectance', 'spectrum', '300:0 800:0');
                    setSpectrumOrTexture(element, mapping, ...
                        'specularReflectance', 'specularReflectance', 'spectrum', '300:0.2 800:0.2');
                    element.setProperty('alphaU', 'float', ...
                        rtbGetMappingProperty(mapping, 'alphaU', 0.15));
                    element.setProperty('alphaV', 'float', ...
                        rtbGetMappingProperty(mapping, 'alphaV', 0.15));
                    
                case 'metal'
                    element.pluginType = 'roughconductor';
                    setSpectrumOrTexture(element, mapping, ...
                        'eta', 'eta', 'spectrum', '300:0 800:0');
                    setSpectrumOrTexture(element, mapping, ...
                        'k', 'k', 'spectrum', '300:0 800:0');
                    element.setProperty('alpha', 'float', ...
                        rtbGetMappingProperty(mapping, 'roughness', .05));
            end
            
        case 'lights'
            switch mapping.specificType
                case {'point', 'spot'}
                    element.pluginType = mapping.specificType;
                    setSpectrumOrTexture(element, mapping, ...
                        'intensity', 'intensity', 'spectrum', '300:0 800:0');
                    
                case 'directional'
                    element.pluginType = 'directional';
                    setSpectrumOrTexture(element, mapping, ...
                        'intensity', 'irradiance', 'spectrum', '300:0 800:0');
            end
            
        case {'floatTextures', 'spectrumTextures'}
            
            % move texture to the top of the scene file
            mitsubaScene.prepend(element);
            
            switch mapping.specificType
                case 'bitmap'
                    element.pluginType = 'bitmap';
                    element.setProperty('filename', 'string', ...
                        rtbGetMappingProperty(mapping, 'filename', ''));
                    element.setProperty('gamma', 'float', ...
                        rtbGetMappingProperty(mapping, 'gamma', 1));
                    element.setProperty('maxAnisotropy', 'float', ...
                        rtbGetMappingProperty(mapping, 'maxAnisotropy', 20));
                    element.setProperty('uoffset', 'float', ...
                        rtbGetMappingProperty(mapping, 'offsetU', 0));
                    element.setProperty('voffset', 'float', ...
                        rtbGetMappingProperty(mapping, 'offsetV', 0));
                    element.setProperty('uscale', 'float', ...
                        rtbGetMappingProperty(mapping, 'scaleU', 1));
                    element.setProperty('vscale', 'float', ...
                        rtbGetMappingProperty(mapping, 'scaleV', 1));
                    element.setProperty('wrapMode', 'string', ...
                        rtbGetMappingProperty(mapping, 'wrapMode', 'repeat'));
                    element.setProperty('filterType', 'string', ...
                        rtbGetMappingProperty(mapping, 'filterMode', 'ewa'));
                    
                case 'checkerboard'
                    element.pluginType = 'checkerboard';
                    
                    element.setProperty('uoffset', 'float', ...
                        rtbGetMappingProperty(mapping, 'offsetU', 0));
                    element.setProperty('voffset', 'float', ...
                        rtbGetMappingProperty(mapping, 'offsetV', 0));
                    element.setProperty('uscale', 'float', ...
                        rtbGetMappingProperty(mapping, 'checksPerU', 2) / 2);
                    element.setProperty('vscale', 'float', ...
                        rtbGetMappingProperty(mapping, 'checksPerV', 2) / 2);
                    element.setProperty('color1', 'spectrum', ...
                        rtbGetMappingProperty(mapping, 'oddColor', '300:0 800:0'));
                    element.setProperty('color2', 'spectrum', ...
                        rtbGetMappingProperty(mapping, 'evenColor', '300:0 800:0'));
            end
    end
end


%% Set a spectrum or texture value to a property.
function setSpectrumOrTexture(element, mapping, getName, setName, setType, defaultValue)
[value, property] = rtbGetMappingProperty(mapping, getName, defaultValue);

% texture references require special Mistuab syntax
if ~isempty(property) && strcmp('texture', property.valueType)
    element.append(MMitsubaProperty.withData('', 'ref', ...
        'id', property.value, ...
        'name', setName));
else
    element.setProperty(setName, setType, value);
end
