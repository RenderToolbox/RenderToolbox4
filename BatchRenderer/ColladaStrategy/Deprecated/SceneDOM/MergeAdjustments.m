%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Merge an XML scene document with an adjustments document.
%   @param sceneDoc document node that represents a scene file
%   @param adjustmentsDoc document node that represents an adjustments file
%   @param excludePattern regular expression to filter adjustments elements
%
% @details
% Merge scene node values from the document represented by @a
% adjustmentsDoc into the document represented by @a sceneDoc.  Nodes
% that exist in both documents will have their values set to the values in
% the adjustments document.  Nodes that don't exist in the scene document
% will be created as needed.
%
% @details
% @a sceneDoc @a adjustmentsDoc must be XML document nodes as returned from
% ReadSceneDOM().  @a sceneDoc may be a Collada parent scene file, a
% Mitsuba-native xml-file, or a RenderToolbox4 PBRT-XML file.  @a
% adjustmentsSoc shouls use the same format as @a sceneDoc, and should
% contain elements that supplement or replace elements in @a sceneDoc.
%
% @details
% Nodes in the adjustment file are matched with nodes in the scene file
% using the id attribute.  A node in the adjustments file with the node
% name "merge" will merge values and attributes with the matching nodes in
% the scene file, with the adjustments nodes taking precidence.  Other
% nodes will replace the matching node in the scene file.
%
% @details
% By default, merges all nodes from @a adjustmentsDoc, in depth first
% order.  If @a excludePattern is provided, it must be a regular expression
% to match against element node names (node names are not the same as id
% attributes). Elements whose node names match @a excludePattern will not
% be merged. 
%
% @details
% Usage:
%   MergeAdjustments(sceneDoc, adjustmentsDoc, excludePattern)
%
% @ingroup SceneDOM
function MergeAdjustments(sceneDoc, adjustmentsDoc, excludePattern)

if nargin < 3
    excludePattern = '';
end

% represent documents by id
[sceneIDMap, sceneSorted] = GenerateSceneIDMap(sceneDoc, excludePattern);
[adjustIDMap, adjustSorted] = GenerateSceneIDMap(adjustmentsDoc, excludePattern);

% create "id" elements in the scene document
%   as needed to accommodate the adjustments document elements
for ii = 1:numel(adjustSorted)
    % get an adjustment node, id, and name
    id = adjustSorted{ii};
    adjustNode = adjustIDMap(id);
    name = char(adjustNode.getNodeName());
    
    % ignore the top-level document node
    if strcmp('document', id)
        continue;
    end
    
    % add a new node to the document if needed
    if sceneIDMap.isKey(id)
        
        if ~strcmp('merge', name)
            % replace an existing node
            toReplace = sceneIDMap(id);
            docRoot = sceneDoc.getDocumentElement();
            idNode = CreateElementChild(docRoot, name, id, toReplace);
            sceneIDMap(id) = idNode;
        end
        
    else
        % create a brand new node
        %   let the adjustments DOM path dicatate the new DOM path
        %   disambiguate similar nodes using the "id" attribute
        %   force nodes with the "ref" nodename to behave like children
        newPath = GetNodePath(adjustNode, 'id', name);
        isCreate = 'first';
        idNode = SearchScene(sceneIDMap, newPath, isCreate);
        sceneIDMap(id) = idNode;
        
        % set the id of the new node
        idPath = newPath;
        idPath{end+1} = PrintPathPart('.', 'id');
        SetSceneValue(sceneIDMap, idPath, id, true, '=');
    end
end

% get paths to all nodes in the adjustments document
%   disambiguate similar nodes using the "name" attribute
%   force "ref" nodes to behave as children, despide "id" attributes
adjustDoc = adjustIDMap('document');
adjustRoot = adjustDoc.getDocumentElement();
adjustPathMap = GenerateScenePathMap(adjustRoot, 'name', '', '^ref$');

% copy the value from each adjustment path into the scene document
%   create scene document nodes as needed
adjustPaths = adjustPathMap.keys();
for ii = 1:numel(adjustPaths)
    % get the scene path for the next adjustment
    pathCell = PathStringToCell(adjustPaths{ii});
    id = pathCell{1};
    
    % ignore paths that refer to the top-level document
    if strcmp('document', id)
        continue;
    end
    
    % set the adjustment node value to the scene node
    adjustValue = GetSceneValue(adjustIDMap, pathCell);
    if ~isempty(adjustValue)
        SetSceneValue(sceneIDMap, pathCell, adjustValue, true);
    end
end
