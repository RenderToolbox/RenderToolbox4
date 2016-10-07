%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Get the value of an element or attribute in an XML document.
%   @param idMap "id map" that represents an XML document
%   @param nodePath Scene DOM path within the XML document
%
% @details
% Gets the value of the element or attribute within the XML document
% represented by @a idMap, at the given @a nodePath.
%
% @details
% @a idMap must be an "id map" that represents an XML document, as
% returned from ReadSceneDOM().
%
% @details
% @a nodePath must be a scene DOM path as returned from GetNodePath().
%
% @details
% Returns the string value of the element or attribute, or '' if there is
% no such element or attribute.
%
% @details
% Usage:
%   value = GetSceneValue(idMap, nodePath)
%
% @ingroup SceneDOM
function value = GetSceneValue(idMap, nodePath)

% resolve the node at the given path
nodePath = PathStringToCell(nodePath);
node = SearchScene(idMap, nodePath, false);
if isempty(node)
    value = '';
    return;
end

% getting for node value or name?
pathType = ScanPathPart(nodePath{end});

% dig out element or attribute value or name
ELEMENT_NODE = 1;
ATTRIBUTE_NODE = 2;
switch node.getNodeType();
    case ELEMENT_NODE
        if strcmp('$', pathType)
            % get the element name
            value = char(node.getNodeName());
            
        else
            textNodes = GetElementChildren(node, '#text');
            if 1 == numel(textNodes)
                % get value under a leaf element
                value = char(node.getTextContent());
                
            else
                % non-leaf elements don't have their own value
                value = [];
            end
        end
        
    case ATTRIBUTE_NODE
        if strcmp('$', pathType)
            % get the attribute name
            value = char(node.getName());
            
        else
            
            % get the attribute value
            value = char(node.getValue());
        end
end