%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Get a mappings object property value.
%   @param obj
%   @param name
%
% @details
% Get the value of a property value of a mappings object.  Returns the
% value.
%
% @details
% Used internally by rtbMakeSceneFiles().
%
% @details
% Usage:
%   value = GetObjectProperty(obj, name)
%
% @ingroup Mappings
function value = GetObjectProperty(obj, name)
value = [];
if ~isempty(obj.properties)
    isProp = strcmp(name, {obj.properties.name});
    if any(isProp)
        index = find(isProp, 1, 'first');
        value = obj.properties(index).value;
    end
end
