%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Translate generic object names and values to Mitsuba.
%   @param objects
%
% @details
% Convert generic mappings objectsto Mitsuba-native mappings objects.  @a
% objects must be a struct array of mappings objects as returned from
% SupplementGenericObjects().
%
% @details
% Used internally by rtbMakeSceneFiles().
%
% @details
% Usage:
%   objects = GenericObjectsToMitsuba(objects)
%
% @ingroup Mappings
function objects = GenericObjectsToMitsuba(objects)

for ii = 1:numel(objects)
    % pull out one object to modify
    obj = objects(ii);
    
    switch obj.class
        case 'material'
            obj.class = 'bsdf';
            
            switch obj.subclass
                case 'matte'
                    obj.subclass = 'diffuse';
                    obj = EditObjectProperty(obj, 'diffuseReflectance', 'reflectance');
                case 'anisoward'
                    obj.subclass = 'ward';
                    obj = EditObjectProperty(obj, 'diffuseReflectance', 'diffuseReflectance');
                    obj = EditObjectProperty(obj, 'specularReflectance', 'specularReflectance');
                    obj = EditObjectProperty(obj, 'alphaU', 'alphaU');
                    obj = EditObjectProperty(obj, 'alphaV', 'alphaV');
                    obj = FillInObjectProperty(obj, 'variant', 'string', 'ward');
                case 'metal'
                    obj.subclass = 'roughconductor';
                    obj = EditObjectProperty(obj, 'eta', 'eta');
                    obj = EditObjectProperty(obj, 'k', 'k');
                    obj = EditObjectProperty(obj, 'roughness', 'alpha');
                case 'bumpmap'
                    obj.hints = 'bumpmap';
                    % bump map conversion happens in ApplyMitsubaObjects()
            end
            
        case 'light'
            obj.class = 'merge';
            
            switch obj.subclass
                case {'point', 'spot'}
                    obj = EditObjectProperty(obj, 'intensity', 'intensity');
                case 'directional'
                    obj = EditObjectProperty(obj, 'intensity', 'irradiance');
                case 'area'
                    obj.hints = 'area-light';
                    obj = EditObjectProperty(obj, 'intensity', 'radiance');
            end
            
        case {'floatTexture', 'spectrumTexture'}
            obj.class = 'texture';
            
            switch obj.subclass
                case 'bitmap'
                    obj = EditObjectProperty(obj, 'filename', 'filename');
                    obj = EditObjectProperty(obj, 'wrapMode', 'wrapMode');
                    obj = EditObjectProperty(obj, 'gamma', 'gamma');
                    obj = EditObjectProperty(obj, 'filterMode', 'filterType');
                    obj = EditObjectProperty(obj, 'maxAnisotropy', 'maxAnisotropy');
                    obj = EditObjectProperty(obj, 'offsetU', 'uoffset');
                    obj = EditObjectProperty(obj, 'offsetV', 'voffset');
                    obj = EditObjectProperty(obj, 'scaleU', 'uscale');
                    obj = EditObjectProperty(obj, 'scaleV', 'vscale');
                    
                case 'checkerboard'
                    obj = EditObjectProperty(obj, 'checksPerU', 'uscale');
                    obj = EditObjectProperty(obj, 'checksPerV', 'vscale');
                    obj = EditObjectProperty(obj, 'offsetU', 'uoffset');
                    obj = EditObjectProperty(obj, 'offsetV', 'voffset');
                    obj = EditObjectProperty(obj, 'oddColor', 'color1');
                    obj = EditObjectProperty(obj, 'evenColor', 'color0');
                    
                    % Mitsuba needs UV scales cut in half
                    u = StringToVector(GetObjectProperty(obj, 'uscale')) ./ 2;
                    v = StringToVector(GetObjectProperty(obj, 'vscale')) ./ 2;
                    obj = SetObjectProperty(obj, 'uscale', VectorToString(u));
                    obj = SetObjectProperty(obj, 'vscale', VectorToString(v));
            end
    end
    
    % save the modified object
    objects(ii) = obj;
end
