%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Convert light nodes to physically-based types.
%   @param libraryLights "library_lights" element a Collada document
%
% @details
% Ensures that each light element within the given @a librarylights will be
% of a physically-based type: directional, spot, or point.  ambient lights
% will be converted to directional lights with the same parameters.
%
% @details
% Returns nothing, but updates the given @a libraryLights
%
% @details
% Usage:
%   ConvertColladaLights(libraryLights)
%
% @ingroup SceneDOM
function ConvertColladaLights(libraryLights)

if ~isjava(libraryLights)
    % not a DOM element
    return;
end

% check each light element and coerce as needed
colladaDoc = libraryLights.getOwnerDocument();
lightNodes = GetElementChildren(libraryLights, 'light');
nLights = numel(lightNodes);
for ii = 1:nLights
    
    % does this light use the standard "technique_common"
    techniqueCommons = GetElementChildren(lightNodes{ii}, 'technique_common');
    if isempty(techniqueCommons)
        continue;
    end
    techniqueCommon = techniqueCommons{1};
    
    % take technique children as-is, except ambient
    [childNodes, childNames] = GetElementChildren(techniqueCommon);
    nChildren = numel(childNodes);
    for jj = 1:nChildren
        childNode = childNodes{jj};
        childName = childNames{jj};
        
        if strcmp('ambient', childName)
            % coerce ambient to directional
            %   the have the same schema, so just change the node name
            colladaDoc.renameNode(childNode, [], 'directional');
        end
    end
end
