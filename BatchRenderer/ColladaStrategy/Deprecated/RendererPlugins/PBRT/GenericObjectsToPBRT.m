%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Translate generic object names and values to PBRT.
%   @param objects
%
% @details
% Convert generic mappings objectsto PBRT-native mappings objects.  @a
% objects must be a struct array of mappings objects as returned from
% SupplementGenericObjects().
%
% @details
% Used internally by rtbMakeSceneFiles().
%
% @details
% Usage:
%   objects = GenericObjectsToPBRT(objects)
%
% @ingroup Mappings
function objects = GenericObjectsToPBRT(objects)

for ii = 1:numel(objects)
    % pull out one object to modify
    obj = objects(ii);
    
    switch obj.class
        case 'material'
            obj.class = 'Material';
            
            switch obj.subclass
                case 'matte'
                    obj = EditObjectProperty(obj, 'diffuseReflectance', 'Kd');
                case 'anisoward'
                    obj = EditObjectProperty(obj, 'diffuseReflectance', 'Kd');
                    obj = EditObjectProperty(obj, 'specularReflectance', 'Ks');
                    obj = EditObjectProperty(obj, 'alphaU', 'alphaU');
                    obj = EditObjectProperty(obj, 'alphaV', 'alphaV');
                case 'metal'
                    obj = EditObjectProperty(obj, 'eta', 'eta');
                    obj = EditObjectProperty(obj, 'k', 'k');
                    obj = EditObjectProperty(obj, 'roughness', 'roughness');
                    r = StringToVector(GetObjectProperty(obj, 'roughness'))/5;
                    obj = SetObjectProperty(obj, 'roughness', VectorToString(r));
                case 'bumpmap'
                    obj.hints = 'bumpmap';
                    % bump map conversion happens in ApplyPBRTObjects()
            end
            
        case 'light'
            obj.class = 'merge';
            
            switch obj.subclass
                case {'point', 'spot'}
                    obj = EditObjectProperty(obj, 'intensity', 'I');
                case 'directional'
                    obj.subclass = 'distant';
                    obj = EditObjectProperty(obj, 'intensity', 'L');
                case 'area'
                    obj.hints = 'AreaLightSource';
                    obj.subclass = 'diffuse';
                    obj = EditObjectProperty(obj, 'intensity', 'L');
                    obj = FillInObjectProperty(obj, 'nsamples', 'integer', '8');
            end
            
        case {'floatTexture', 'spectrumTexture'}
            % for textures, supply an extra "dataType" property
            %   which is a hint to WritePBRTFile()
            if strcmp('spectrumTexture', obj.class)
                dataType = 'spectrum';
            else
                dataType = 'float';
            end
            obj = FillInObjectProperty(obj, 'dataType', 'string', dataType);
            
            % all textures use the PBRT 'Texture' identifier
            obj.class = 'Texture';
            
            switch obj.subclass
                case 'bitmap'
                    obj.subclass = 'imagemap';
                    obj = EditObjectProperty(obj, 'filename', 'filename');
                    obj = EditObjectProperty(obj, 'wrapMode', 'wrap');
                    if strcmp('zero', GetObjectProperty(obj, 'wrap'))
                        obj = SetObjectProperty(obj, 'wrap', 'black');
                    end
                    obj = EditObjectProperty(obj, 'gamma', 'gamma');
                    obj = EditObjectProperty(obj, 'filterMode', 'trilinear', 'bool');
                    if strcmp('trilinear', GetObjectProperty(obj, 'trilinear'))
                        obj = SetObjectProperty(obj, 'trilinear', 'true');
                    else
                        obj = SetObjectProperty(obj, 'trilinear', 'false');
                    end
                    obj = EditObjectProperty(obj, 'maxAnisotropy', 'maxanisotropy');
                    obj = EditObjectProperty(obj, 'offsetU', 'udelta');
                    obj = EditObjectProperty(obj, 'offsetV', 'vdelta');
                    obj = EditObjectProperty(obj, 'scaleU', 'uscale');
                    obj = EditObjectProperty(obj, 'scaleV', 'vscale');
                    
                case 'checkerboard'
                    obj = EditObjectProperty(obj, 'checksPerU', 'uscale');
                    obj = EditObjectProperty(obj, 'checksPerV', 'vscale');
                    obj = EditObjectProperty(obj, 'offsetU', 'udelta');
                    obj = EditObjectProperty(obj, 'offsetV', 'vdelta');
                    obj = EditObjectProperty(obj, 'oddColor', 'tex2');
                    obj = EditObjectProperty(obj, 'evenColor', 'tex1');
                    
                    % PBRT needs some extra parameters
                    obj = FillInObjectProperty(obj, 'mapping', 'string', 'uv');
                    obj = FillInObjectProperty(obj, 'dimension', 'integer', '2');
            end
    end
    
    % save the modified object
    objects(ii) = obj;
end
