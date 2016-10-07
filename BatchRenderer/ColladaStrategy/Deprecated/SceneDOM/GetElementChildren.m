%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Get the child elements of an XML document element.
%   @param element XML document element object
%   @param name string name of child elements (optional)
%   @param checkName child attribute name to check (optional)
%   @param checkValue child attribute value to check (optional)
%
% @details
% Gets the children an XML document element, if any.
%
% @details
% @a element must be an element from an XML document, as returned from
% GetSceneNode().
%
% @details
% By default, returns a cell array of all the document elements that are
% children of the given @a element.  Also returns a cell array of strings
% of all child element names.
%
% @details
% If @a name is provided, searches only for child elements that have the
% node name @a name.
%
% @details
% If @a name, @a checkName and @a checkValue are provided, searches for a
% single child element that has the node name @a name, and has an attribute
% with the name @a checkName and value equal to @a checkValue.  If such a
% child element is found, returns the single child element and string name.
% Otherwise, returns empty values.
%
% @details
% Usage:
%   [children, names] = GetElementChildren(element, name, checkName, checkValue)
%
% @ingroup SceneDOM
function [children, names] = GetElementChildren(element, name, checkName, checkValue)

%% Parameters
if nargin < 2
    name = '';
end

if nargin < 4
    checkName = '';
    checkValue = '';
end

%% Search for child nodes
children = {};
names = {};
if isjava(element) && element.hasChildNodes()
    % iterate all children
    childArray = element.getChildNodes();
    nChildren = childArray.getLength();
    children = cell(1, nChildren);
    names = cell(1, nChildren);
    isMatch = false(1, nChildren);
    for ii = 1:nChildren
        % convert the next child from Java to Matlab types
        child = childArray.item(ii-1);
        childName = char(child.getNodeName());
        
        if isempty(name)
            % get all children
            %   except XML comments
            children{ii} = child;
            names{ii} = childName;
            isMatch(ii) = ~strcmp(name, '#comment');
            
        elseif strcmp(name, childName)
            % get matching children
            if isempty(checkName) || isempty(checkValue)
                % match any child by name
                %   except XML comments
                children{ii} = child;
                names{ii} = childName;
                isMatch(ii) = ~strcmp(name, '#comment');;
                
            else
                % match one child by name and attribute value
                [attrib, attribName, attribValue] = ...
                    GetElementAttributes(child, checkName);
                if ~isempty(attrib) && strcmp(checkValue, attribValue)
                    children = child;
                    names = childName;
                    return;
                end
            end
        end
    end
    % squeeeze out children that did not match the given name
    children = children(isMatch);
    names = names(isMatch);
end

