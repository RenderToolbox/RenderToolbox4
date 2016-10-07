%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Fill in generic objects with default properties, if needed.
%   @param objects
%
% @details
% Add default properties to generic mappings objects, as needed to make
% them complete.  @a objects must be a struct array of mappings  
% objects as returned from MappingsToObjects() or
% GenericObjectsToMitsuba().
%
% @details
% Used internally by rtbMakeSceneFiles().
%
% @details
% Usage:
%   objects = SupplementGenericObjects(objects)
%
% @ingroup Mappings
function objects = SupplementGenericObjects(objects)

% fill in properties for each object, by type
for ii = 1:numel(objects)
    % pull out one object to modify
    obj = objects(ii);
    
    switch obj.class
        case 'material'
            switch obj.subclass
                case 'matte'
                    obj = FillInObjectProperty(obj, 'diffuseReflectance', 'spectrum', '300:0.5 800:0.5');
                case 'anisoward'
                    obj = FillInObjectProperty(obj, 'diffuseReflectance', 'spectrum', '300:0.5 800:0.5');
                    obj = FillInObjectProperty(obj, 'specularReflectance', 'spectrum', '300:0.5 800:0.5');
                    obj = FillInObjectProperty(obj, 'alphaU', 'float', '0.1');
                    obj = FillInObjectProperty(obj, 'alphaV', 'float', '0.1');
                case 'metal'
                    dataPath = fullfile(rtbRoot(), 'RenderData', 'PBRTMetals');
                    eta = fullfile(dataPath, 'Cu.eta.spd');
                    k = fullfile(dataPath, 'Cu.k.spd');
                    obj = FillInObjectProperty(obj, 'eta', 'spectrum', eta);
                    obj = FillInObjectProperty(obj, 'k', 'spectrum', k);
                    obj = FillInObjectProperty(obj, 'roughness', 'float', '0.4');
                case 'bumpmap'
                    obj = FillInObjectProperty(obj, 'materialID', 'string', '');
                    obj = FillInObjectProperty(obj, 'textureID', 'string', '');
                    obj = FillInObjectProperty(obj, 'scale', 'float', '1.0');
            end
            
        case 'light'
            switch obj.subclass
                case {'point', 'directional', 'spot', 'area'}
                    obj = FillInObjectProperty(obj, 'intensity', 'spectrum', '300:1.0 800:1.0');
            end
            
        case {'floatTexture', 'spectrumTexture'}
            switch obj.subclass
                case 'bitmap'
                    obj = FillInObjectProperty(obj, 'filename', 'string', '');
                    obj = FillInObjectProperty(obj, 'wrapMode', 'string', 'repeat');
                    obj = FillInObjectProperty(obj, 'gamma', 'float', '1');
                    obj = FillInObjectProperty(obj, 'filterMode', 'string', 'ewa');
                    obj = FillInObjectProperty(obj, 'maxAnisotropy', 'float', '20');
                    obj = FillInObjectProperty(obj, 'offsetU', 'float', '0.0');
                    obj = FillInObjectProperty(obj, 'offsetV', 'float', '0.0');
                    obj = FillInObjectProperty(obj, 'scaleU', 'float', '1.0');
                    obj = FillInObjectProperty(obj, 'scaleV', 'float', '1.0');
                    
                case 'checkerboard'
                    obj = FillInObjectProperty(obj, 'checksPerU', 'float', '2');
                    obj = FillInObjectProperty(obj, 'checksPerV', 'float', '2');
                    obj = FillInObjectProperty(obj, 'offsetU', 'float', '0');
                    obj = FillInObjectProperty(obj, 'offsetV', 'float', '0');
                    if strcmp('floatTexture', obj.subclass)
                        obj = FillInObjectProperty(obj, 'oddColor', 'float', '0');
                        obj = FillInObjectProperty(obj, 'evenColor', 'float', '1');
                    else
                        obj = FillInObjectProperty(obj, 'oddColor', 'spectrum', '300:0 800:0');
                        obj = FillInObjectProperty(obj, 'evenColor', 'spectrum', '300:1 800:1');
                    end
            end
    end
    
    % save the modified object
    objects(ii) = obj;
end
