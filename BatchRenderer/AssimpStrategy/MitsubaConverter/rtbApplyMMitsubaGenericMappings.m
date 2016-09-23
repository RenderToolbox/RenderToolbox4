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
% Copyright (c) 2016 mexximp Team

parser = inputParser();
parser.addRequired('mitsubaScene', @isobject);
parser.addRequired('mappings', @isstruct);
parser.parse(mitsubaScene, mappings);
mitsubaScene = parser.Results.mitsubaScene;
mappings = parser.Results.mappings;

%% Select only RenderToolbox3 "Generic" mappings.
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
    element = rtbApplyMMitsubaMappingOperation(mitsubaScene, mapping, ...
        'type', type);
    if isempty(element)
        continue;
    end
    
    %% Apply Generic mappings special operations.
    switch mapping.operation
        case 'blessAsAreaLight'
            %% Turn an existing shape into an area emitter.
            %
            % We start with a shape declaration:
            % <shape id="LightY-mesh_0" type="serialized">
            %   <string name="filename" value="Dragon-001Unadjusted.serialized"/>
            %   ...
            % </shape>
            %
            % We add an emitter nested in the mesh
            % <shape id="LightY-mesh_0" type="serialized">
            %   <string name="filename" value="Dragon-001Unadjusted.serialized"/>
            %   <emitter id="LightY-mesh_0-area-light" type="area">
            %     <spectrum filename="/home/ben/render/RenderToolbox3/RenderData/D65.spd" name="radiance"/>
            %   </emitter>
            %   ...
            % </shape>
            
            % the emitter
            emitterId = [element.id '-emitter'];
            emitter = MMitsubaElement(emitterId, 'emitter', 'area');
            emitter.setProperty('radiance', 'spectrum', ...
                rtbGetMappingProperty(mapping, 'intensity', '300:1 800:1'));
            
            % nested in the original shape
            element.append(emitter);
            
        case 'blessAsBumpMap'
            %% Turn an existing material into a bumpmap material.
            %
            % We start with an existing texture and existing material.
            %
            % <texture id="earthTexture" type="bitmap">
            %	<float name="gamma" value="1"/>
            %	<float name="maxAnisotropy" value="20"/>
            %	<float name="uoffset" value="0.0"/>
            %	<float name="uscale" value="1.0"/>
            %	<float name="voffset" value="0.0"/>
            %	<float name="vscale" value="1.0"/>
            %	<string name="filename" value="/home/ben/render/VirtualScenes/MiscellaneousData/Textures/earthbump1k-stretch-rgb.exr"/>
            %	<string name="filterType" value="ewa"/>
            %	<string name="wrapMode" value="repeat"/>
            % </texture>
            % ...
            % <bsdf id="Material-material" type="roughconductor">
            % 	<float name="alpha" value="0.4"/>
            % 	<spectrum filename="/home/ben/render/RenderToolbox3/RenderData/PBRTMetals/Au.eta.spd" name="eta"/>
            % 	<spectrum filename="/home/ben/render/RenderToolbox3/RenderData/PBRTMetals/Au.k.spd" name="k"/>
            % </bsdf>
            %
            % We rename the material because we will want existing shapes
            % to refer to a new material that we're about to make, instead
            % of the original material.
            %
            % <bsdf id="Material-material-inner" type="roughconductor">
            % 	...
            % </bsdf>
            %
            % We wrap the texture in a "scale" texture so that we can apply
            % a scale factor to the bumps.
            %
            % <texture id="earthBumpMap-scaled" type="scale">
            %   <float name="scale" value="0.1"/>
            %   <ref id="earthTexture" name="value"/>
            % </texture>
            %
            % Finally, we make a new "bumpmap" material which wraps our
            % scale texture and the renamed original material.  We use the
            % id of the original material so that existing shapes will
            % refer to this new, "blessed" material instead of the
            % original.
            
            % locate and rename the original material
            originalMaterialId = element.id;
            innerMaterialId = [originalMaterialId '-inner'];
            element.id = innerMaterialId;
            
            % locate the original texture
            textureName = rtbGetMappingProperty(mapping, 'texture', '');
            originalTexture = mitsubaScene.find(textureName, ...
                'type', 'texture');
            
            % wrap the original texture in a new scale texture
            scaleTextureId = [originalTexture.id '-scaled'];
            scaleTexture = MMitsubaElement(scaleTextureId, 'texture', 'scale');
            scaleTexture.append(MMitsubaProperty.withData('', 'ref', ...
                'id', originalTexture.id, ...
                'name', 'value'));
            scaleTexture.setProperty('scale', 'float', ...
                rtbGetMappingProperty(mapping, 'scale', 1));
            
            % wrap original material and scaled texture in a "bumpmap" material
            bumpmap = MMitsubaElement(originalMaterialId, 'bsdf', 'bumpmap');
            bumpmap.append(MMitsubaProperty.withData('', 'ref', ...
                'id', innerMaterialId, ...
                'name', 'bsdf'));
            bumpmap.append(MMitsubaProperty.withData('', 'ref', ...
                'id', scaleTextureId, ...
                'name', 'texture'));
            
            % move objects to front in the right order such that:
            %   - things that are independent come first
            %   - thigs that have "ref" properties come next
            %   - elements of the same type are grouped together
            %       because our XML writer will group them anyway,
            %       and we want to choose which group comes first (textures)
            mitsubaScene.prepend(bumpmap);
            mitsubaScene.prepend(element);
            mitsubaScene.prepend(scaleTexture);
            mitsubaScene.prepend(originalTexture);
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
                    element.setProperty('variant', 'string', 'ward');
                    setSpectrumOrTexture(element, mapping, ...
                        'diffuseReflectance', 'diffuseReflectance', 'spectrum', '300:0 800:0');
                    setSpectrumOrTexture(element, mapping, ...
                        'specularReflectance', 'specularReflectance', 'spectrum', '300:0.5 800:0.5');
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
                    element.setProperty('roughness', 'float', ...
                        rtbGetMappingProperty(mapping, 'alpha', .05));
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
