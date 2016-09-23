%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Make a Scene DOM path for an XML document element or attribute.
%   @param node XML document element or attribute object
%   @param checkName name of attribute to include in the path
%   @param childPattern regular expression to force child node behavior
%
% @details
% Create a Scene DOM path for the given XML document element or attribute.
%
% @details
% By default, creates a Scene DOM path that only uses element names.  If
% @a checkName is provided, it must the string name of an attribute to
% "check".  For elements in the path that have an attribute with the given
% @a checkName, the name and value will be included in the path.
%
% @details
% Also by default, stops creating a Scene DOM path at the first node that
% has an id attribute.  If @a childPattern is provided, it must be a
% regular expression to compare to node names.  Nodes whose names match @a
% childPattern will allow path creation to continue, even if they have an
% id attribute.
%
% @details
% Returns a Scene DOM path cell array for the given node.
%
% @details
% See the RenderToolbox4 wiki for more about <a
% href="https://github.com/DavidBrainard/RenderToolbox4/wiki/Scene-DOM-Paths">Scene
% DOM paths</a>.
%
% @details
% Usage:
%   nodePath = GetNodePath(node, checkName, childPattern)
%
% @ingroup SceneDOM
function nodePath = GetNodePath(node, checkName, childPattern)

if nargin < 2
    checkName = '';
end

if nargin < 3
    childPattern = '';
end

% ignore nodes that store raw node text
if strcmp('#text', char(node.getNodeName()))
    nodePath = {};
    return;
end

% starting with the given node, build a path backwards, by working up the
% DOM graph
backwardsPath = {};

% attribute is always last in the path
ATTRIBUTE_NODE = 2;
if ATTRIBUTE_NODE == node.getNodeType()
    % concatenate name and value
    name = char(node.getName());
    backwardsPath{end+1} = PrintPathPart('.', name);
    
    % get the element above this attribute
    node = node.getOwnerElement();
end

% trace node names up the graph
%   until finding an ancestor with an "id"
%   or reaching the top of the document graph
ancestorID = 'document';
while isjava(node) && ~strcmp('#document', char(node.getNodeName()))
    % convert the node name from Java to Matlab
    name = char(node.getNodeName());
    
    % some nodes must behave like child nodes,
    %   even if they have an "id" attribute, for example referencces
    isForcedChild = ~isempty(childPattern) ...
        && ~isempty(regexp(name, childPattern, 'once'));
    
    % does this node have a proper id?
    [attribute, attribName, value] = GetElementAttributes(node, 'id');
    if ~isForcedChild && ~isempty(attribute)
        ancestorID = value;
        break;
    end
    
    % append a plain or decorated path part
    if isempty(checkName)
        % plain node name
        backwardsPath{end+1} = PrintPathPart(':', name);
        
    else
        % check the given attribute
        [attrib, attribName, attribValue] = ...
            GetElementAttributes(node, checkName);
        if isempty(attrib)
            % no match, plain node name
            backwardsPath{end+1} = PrintPathPart(':', name);
            
        else
            % match, decorate node name with attribute
            backwardsPath{end+1} = ...
                PrintPathPart(':', name, attribName, attribValue);
        end
    end
    
    % continue up the document graph
    node = node.getParentNode();
end

% make a forwards path, starting with ancestorID
backwardsPath{end+1} = ancestorID;
nodePath = backwardsPath(end:-1:1);