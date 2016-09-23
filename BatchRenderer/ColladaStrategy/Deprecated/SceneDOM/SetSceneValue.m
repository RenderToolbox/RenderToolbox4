%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Set the value of a document element or attribute.
%   @param idMap "id map" that represents an XML document
%   @param nodePath Scene DOM path within the XML document
%   @param value string value to assign to an element or attribute
%   @param isCreate whether to create new document nodes (optional)
%   @param operator how to apply @a value (optional
%
% @details
% Sets the value of the element or attribute within the XML document
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
% @A value must be a string value to assign to the element or attribute.
%
% @details
% By default, if there is no element or attribute at the given @a nodePath,
% prints a warning.  If @a isCreate is provided and true, creates missing
% elements and attributes as needed to satisfy @a nodePath, then sets the
% given @a value.
%
% @details
% By default, assigns @a value to the element or attribute at @a nodePath.
% If @a operator is provided, it may specify a different way to apply @a
% value:
%   - '=' - assign @a value to the element or attribute
%   - '+=' - add @a value to the element or attribute value
%   - '-=' - subtract @a value from the element or attribute value
%   - '*=' - multiply @a value with the element or attribute value
%   - '/=' - divide the element or attribute value by @a value
%   .
% Attempts to convert between string and numeric values as necessary.
%
% @details
% Returns the old value at the given @a nodePath, if any.
%
% @details
% Usage:
%   oldValue = SetSceneValue(idMap, nodePath, value, isCreate, operator)
%
% @ingroup SceneDOM
function oldValue = SetSceneValue(idMap, nodePath, value, isCreate, operator)

%% Parameters
if nargin < 4 || isempty(isCreate)
    isCreate = false;
end

if nargin < 5 || isempty(operator)
    operator = '=';
end

%% Set the scene node value
% resolve the node and value at the given path.
nodePath = PathStringToCell(nodePath);
node = SearchScene(idMap, nodePath, isCreate);
if isempty(node)
    pathString = PathCellToString(nodePath);
    warning('No node at the given path:\n  %s\n', pathString);
    return;
end
oldValue = GetSceneValue(idMap, nodePath);

% figure out the new value, based on the operator
if strcmp('=', operator)
    % assignment works with any value
    newValue = value;
    
else
    % other operators require numeric conversion
    
    % convert old value to numeric
    oldNum = StringToVector(oldValue);
    if isempty(oldNum)
        oldNum = 0;
    end
    
    % convert new value to numeric
    newNum = StringToVector(value);
    if isempty(newNum)
        newNum = 0;
    end
    
    % calculate the new value
    switch operator
        case '+='
            newNum = oldNum + newNum;
            
        case '-='
            newNum = oldNum - newNum;
            
        case '*='
            newNum = oldNum .* newNum;
            
        case '/='
            newNum = oldNum ./ newNum;
    end
    
    % convert new value back to string
    newValue = VectorToString(newNum);
end

% setting for node value or name?
pathType = ScanPathPart(nodePath{end});

% dig out element or attribute value or name
ELEMENT_NODE = 1;
ATTRIBUTE_NODE = 2;
switch node.getNodeType();
    case ELEMENT_NODE
        if strcmp('$', pathType)
            % set the element name
            doc = node.getOwnerDocument();
            node = doc.renameNode(node, [], newValue);
            
        else
            % set the element value
            node.setTextContent(newValue);
        end
        
    case ATTRIBUTE_NODE
        if strcmp('$', pathType)
            % set the attribute name
            doc = node.getOwnerDocument();
            node = doc.renameNode(node, [], newValue);
            
        else
            
            % set the attribute value
            node.setValue(newValue);
        end
end
