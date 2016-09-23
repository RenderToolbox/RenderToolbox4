%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Change a mappings object property name and type.
%   @param obj
%   @param oldName
%   @param newName
%   @param newType
%
% @details
% Change the name and type of a mappings object's existing property.  The
% property with the given @a oldName will be modified to have the given @a
% newName and @a newType.  Returns the updated mappings object.
%
% @details
% Used internally by rtbMakeSceneFiles().
%
% @details
% Usage:
%   obj = EditObjectProperty(obj, oldName, newName, newType)
%
% @ingroup Mappings
function obj = EditObjectProperty(obj, oldName, newName, newType)
if ~isempty(obj.properties)
    isProp = strcmp(oldName, {obj.properties.name});
    if any(isProp)
        % replace the property name
        obj.properties(isProp).name = newName;
        
        if nargin >= 4
            % replace the property type
            obj.properties(isProp).type = newType;
        end
    end
end
