%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Get uniquely identified XML document elements, and Scene DOM paths.
%   @param docNode XML document node object
%   @param excludePattern regular expression to filter document elements
%
% @details
% Traverses the XML DOM document represented by @a docNode, and builds a
% map to elements that have an "id" attribute.
%
% @details
% Returns an "id map" that represents the same document as @a docNode.  An
% id map is a containers.Map of document elements that have "id"
% attributes, with the id values as map keys.  Nodes with id attributes
% often correspond to intuitive parts of a scene, like the camera, lights,
% shapes, and materials.
%
% @details
% Also returns a cell array of element ids in depth first order.  This is
% the order in which elements are encountered during document traversal.
% This should also be the top-down order of elements as the appear in the
% XML text file.
%
% @details
% By default, returns all elements with id attributes.  If @a
% excludePattern is provided, it must be a regular expression to match
% against element node names (note names are not the same as id
% attributes).  Elements whose node names match @a excludePattern will not
% be added to the id map, even if they have an id attribute.
%
% @details
% Usage:
%   [idMap, sortedKeys] = GenerateSceneIDMap(docNode, excludePattern)
%
% @ingroup SceneDOM
function [idMap, sortedKeys] = GenerateSceneIDMap(docNode, excludePattern)

if nargin < 2
    excludePattern = '';
end

% create the containers for ids and elements
idMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
depthMap = containers.Map('KeyType', 'uint64', 'ValueType', 'char');

% let the top-level element use the id 'document'
idMap('document') = docNode;

% traverse the DOM!
traverseElements(docNode, idMap, depthMap, excludePattern);

% return sorted keys as a cell array
sortedKeys = depthMap.values();


%% Check for "id" and iterate child elements
function traverseElements(element, idMap, depthMap, excludePattern)
% does this element have an 'id' attribute?
[attribute, name, id] = GetElementAttributes(element, 'id');
if ~isempty(attribute)
    % should it be excluded by name?
    name = char(element.getNodeName());
    if isempty(excludePattern) || isempty(regexp(name, excludePattern, 'once'))
        % add element to the idMap
        idMap(id) = element;
        
        % add key to the sorded keys
        depthMap(depthMap.Count + 1) = id;
    end
end

% recur: get paths for each child
children = GetElementChildren(element);
for ii = 1:numel(children)
    traverseElements(children{ii}, idMap, depthMap, excludePattern);
end