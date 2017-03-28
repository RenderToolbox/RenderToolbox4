%% Get a formatted struct describing a light, material, etc.
%   @param category a scene element category like 'light', 'material', etc.
%   @param type a scene element type like 'area', 'matte', etc.
%   @param propertyNames cell aray of element property names like {'intensity', 'diffuseReflectance'}
%   @param propertyValues cell aray of element property values like {'D65.spd, '255 0 0'}
%   @param valueTypes cell aray of property values types like {'spectrum', 'rgb'}
%
% @details
% Builds a struct with standard formatting that describes some scene
% element.  This struct will be suitable for writing to a RenderToolbox3
% mappings file using utilities like AppendMappings().
%
% @details
% @a category and @a type indicate the kind of scene element to describe,
% for example an area light or matte material.
%
% @details
% @a propertyNames, @a propertyValues, and @a valueTypes all should have
% n elements, and collectively specify n properties of the scene element.
%
% @details
% See <a
% href="https://github.com/DavidBrainard/RenderToolbox3/wiki/Generic-Scene-Elements">Generic-Scene-Elements</a>
% for examples of valid elements and properties.
%
% @details
% Returns a struct with standard formatting which describes a scene element
% and its properties.
%
% @details
% Usage:
%   description = rtbBuildDesription(category, type, propertyNames, propertyValues, valueTypes)
%
% We should update the commenting style of this header someday.

function description = rtbBuildDesription(category, type, propertyNames, propertyValues, valueTypes)
properties = struct( ...
    'propertyName', propertyNames, ...
    'propertyValue', propertyValues, ...
    'valueType', valueTypes);

description = struct( ...
    'category', category, ...
    'type', type, ...
    'properties', properties);
