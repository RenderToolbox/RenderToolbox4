%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Get many XML document nodes and Scene DOM paths.
%   @param docNode XML document node object
%   @param checkName name of attribute to include in the path
%   @param filterPattern regular expression to filter document nodes
%   @param childPattern regular expression to force child node behavior
%
% @details
% Traverses the XML document represented by @a docNode, finding elements
% and attributes, and recording Scene DOM paths to each element or
% attribute.
%
% @details
% Returns a "path map" that represents the same document as @a docNode.  A
% path map is a containers.Map of all document elements and attributtes,
% with Scene DOM path strings as map keys.
%
% @details
% Also returns a cell array of path strings in depth first order.  This is
% the order in which elements and attributes are encountered during
% document traversal.  This should also be the top-down order of elements
% as the appear in the XML text file.
%
% @details
% By default, the Scene DOM paths refer only to element node names.
% Therefore, the paths may not be unique and some nodes will be ignored.
% If @a checkName is provided, it should be the name of an attribute that
% can disambiguate elements by its value.  The attribute name and value
% will be included in the paths, for all objects that have the attribute.
%
% @details
% A useful value for @a checkName might be 'id', 'sid', 'name', or
% 'semantic'.  These attributes often distinguish similar nodes in Collada
% scene files and renderer adjustments files.
%
% @details
% Also by default, all elements and attributes are included in the path
% map.  If @a filterPattern is provided, it must be a regular expression to
% compare to each Scene DOM path string.  Only nodes whose path strings
% match the @a filterPattern will be included in the path map.
%
% @details
% Also by default, stops creating each Scene DOM path at the first node
% that has an "id" attribute.  If @a childPattern is provided, it must be a
% regular expression to compare to node names (note names are not the samd
% as id attributes).  Nodes whose node names match @a childPattern will
% allow path creation to continue, even if they have an id attribute.
%
% @details
% Usage:
%   [pathMap, sortedKeys] = GenerateScenePathMap(docNode, checkName, filterPattern, childPattern)
%
% @ingroup SceneDOM
function [pathMap, sortedKeys] = GenerateScenePathMap(docNode, checkName, filterPattern, childPattern)

if nargin < 2
    checkName = '';
end

if nargin < 3
    filterPattern = '';
end

if nargin < 4
    childPattern = '';
end

% create the container for path strings and nodes
pathMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
depthMap = containers.Map('KeyType', 'uint64', 'ValueType', 'char');

% traverse the DOM!
traverseElements(docNode, pathMap, depthMap, checkName, filterPattern, childPattern);

% return sorted keys as a cell array
sortedKeys = depthMap.values();

%% Iterate attributes and child elements
function traverseElements(element, pathMap, depthMap, checkName, filterPattern, childPattern)
% get a path for the element itself
%   add this element to the path map
elementPath = GetNodePath(element, checkName, childPattern);
if ~isempty(elementPath)
    pathString = PathCellToString(elementPath);
    if isempty(filterPattern) || ~isempty(regexp(pathString, filterPattern))
        % add element to the path map
        pathMap(pathString) = element;
        
        % add key to the sorded keys
        depthMap(depthMap.Count + 1) = pathString;
    end
end

% get a path for each attribute
%   add each attribute to the path map
[attributes, names, values] = GetElementAttributes(element);
nAttributes = numel(attributes);
for ii = 1:nAttributes
    attribPath = GetNodePath(attributes{ii}, checkName, childPattern);
    pathString = PathCellToString(attribPath);
    if isempty(filterPattern) || ~isempty(regexp(pathString, filterPattern))
        % add attribute to the path map
        pathMap(pathString) = attributes{ii};
        
        % add key to the sorded keys
        depthMap(depthMap.Count + 1) = pathString;
    end
end

% recur: get paths for each child element
children = GetElementChildren(element);
for ii = 1:numel(children)
    traverseElements(children{ii}, pathMap, depthMap, checkName, filterPattern, childPattern);
end