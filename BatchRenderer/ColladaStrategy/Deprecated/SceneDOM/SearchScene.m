%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Find an element or attribute in an XML document.
%   @param idMap "id map" that represents an XML document
%   @param nodePath Scene DOM path within the XML document
%   @param isCreate whether to create new document nodes (optional)
%
% @details
% Traverse the XML document represented by the given @a idMap, following
% the given @a nodePath Scene DOM path.
%
% @details
% @a idMap must be an "id map" that represents an XML document, as returned
% from ReadSceneDOM().
%
% @details
% @a nodePath must be a Scene DOM path as returned from GetNodePath().
%
% @details
% Returns the first document element or attribute that matches @a nodePath.
% By default, if there is no such element or attribute, returns [].  If @a
% isCreate is provided and true, creates element or attribute as necessary
% to satisfy @a nodePath.
%
% @details
% Usage:
%   node = SearchScene(idMap, nodePath, isCreate)
%
% @ingroup SceneDOM
function node = SearchScene(idMap, nodePath, isCreate)

if nargin < 3
    isCreate = false;
end

% the first node comes directly from the path id
nodePath = PathStringToCell(nodePath);
id = nodePath{1};
if idMap.isKey(id)
    node = idMap(id);
    
else
    % create the new node on demand, at the top of the document
    doc = idMap('document');
    root = doc.getDocumentElement();
    node = CreateElementChild(root, 'element', id);
    idMap(id) = node;
end


% follow the rest of the path one part at a time
nParts = numel(nodePath);
for ii = 2:nParts
    pathPart = nodePath{ii};
    [operator, name, checkName, checkValue] = ScanPathPart(pathPart);
    switch operator
        case '.'
            % get an attribute
            attribute = GetElementAttributes(node, name);
            if isempty(attribute)
                if isCreate
                    % fill in the missing attribute
                    doc = node.getOwnerDocument();
                    attribute = doc.createAttribute(name);
                    node.setAttributeNode(attribute);
                    
                else
                    % path does not exist
                    node = [];
                    break;
                end
            end
            
            % attribute is always last in the path
            node = attribute;
            break;
            
        case ':'
            % get a child element
            child = GetElementChildren(node, name, checkName, checkValue);
            if isempty(child)
                if isCreate
                    % fill in the missing child
                    child = CreateElementChild(node, name, [], isCreate);
                    
                    if ~isempty(checkName) && ~isempty(checkValue)
                        % add a "check" attribute to the child
                        doc = child.getOwnerDocument();
                        check = doc.createAttribute(checkName);
                        check.setValue(checkValue);
                        child.setAttributeNode(check);
                    end
                    
                else
                    % path does not exist
                    node = [];
                    break;
                end
            end
            
            % pick only the first of multiple matches
            if iscell(child)
                child = child{1};
            end
            
            % OK to continue
            node = child;
            
        case '$'
            % node name operator is always last in the path
            %   don't need to get a new node
            break;
            
        otherwise
            warning('nodePath contains unknown operator "%s".', operator);
            node = [];
            return;
    end
end