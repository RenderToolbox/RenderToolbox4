%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Set a mappings object property value.
%   @param obj
%   @param name
%   @param value
%
% @details
% Set a property value for a mappings object.  Returns the updated object.
%
% @details
% Used internally by rtbMakeSceneFiles().
%
% @details
% Usage:
%   obj = SetObjectProperty(obj, name, value)
%
% @ingroup Mappings
function obj = SetObjectProperty(obj, name, value)
if ~isempty(obj.properties)
    isProp = strcmp(name, {obj.properties.name});
    if any(isProp)
        index = find(isProp, 1, 'first');
        obj.properties(index).value = value;
    end
end
