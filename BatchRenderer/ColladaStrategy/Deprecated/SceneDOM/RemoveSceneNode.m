%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Remove an element or attribute from an XML document.
%   @param idMap "id map" that represents an XML document
%   @param nodePath Scene DOM path within the XML document
%
% @details
% Remove the element or attribute from the XML document represented by @a
% idMap, at the given @a nodePath.
%
% @details
% idMap must be an "id map" that represents an XML document, as returned
% from ReadSceneDOM().
%
% @details
% @a nodePath must be a Scene DOM path as returned from GetNodePath().
%
% @details
% Returns the element or attribute that was removed, or [] if there is no
% element or attribute the given @a nodePath.
%
% @details
% Usage:
%   node = RemoveSceneNode(idMap, nodePath)
%
% @ingroup SceneDOM
function node = RemoveSceneNode(idMap, nodePath)

% resolve the node to remove at the given path
node = SearchScene(idMap, nodePath, false);
if isempty(node)
    return;
end

% remove the node from the document structure
if ~isempty(node)
    
    ELEMENT_NODE = 1;
    ATTRIBUTE_NODE = 2;
    switch node.getNodeType();
        case ELEMENT_NODE
            % remove a whole element node
            parent = node.getParentNode();
            parent.removeChild(node);
            
        case ATTRIBUTE_NODE
            % remove just an attribute
            owner = node.getOwnerElement();
            owner.removeAttribute(node.getName());
    end
end

% remove the node from the idMap alltogether?
if 1 == numel(nodePath)
    idMap.remove(nodePath{1});
end