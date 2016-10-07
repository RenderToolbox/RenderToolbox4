%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Get the attributes owned by an XML document element.
%   @param element XML document element object
%   @param name string name of an attribute (optional)
%
% @details
% Get the attributes owned by an XML document element, if any.
%
% @details
% @a element must be an element node from an XML document, as returned
% from GetSceneNode().
%
% @details
% By default, returns a cell array of all attribute nodes, a cell array
% of strings of corresponding attribute names, and a cell array of strings
% of corresponding attribute values.
%
% @details
% If @a name is provided, searches for a single attribute with the given @a
% name.  If such an attribute is found, returns the single attribute
% object, string name, and string value.  If no such attribute attribute is
% fouund, returns empty arrays.
%
% @details
% Usage:
%   [attributes, names, values] = GetElementAttributes(element, name)
%
% @ingroup SceneDOM
function [attributes, names, values] = GetElementAttributes(element, name)

if nargin < 2
    name = '';
end

attributes = {};
names = {};
values = {};
ELEMENT_NODE = 1;
if isjava(element) ...
        && ELEMENT_NODE == element.getNodeType() ...
        && element.hasAttributes()
    % iterate all attributes
    attribArray = element.getAttributes();
    nAttributes = attribArray.getLength();
    attributes = cell(1, nAttributes);
    names = cell(1, nAttributes);
    values = cell(1, nAttributes);
    isMatch = false(1, nAttributes);
    for ii = 1:nAttributes
        % convert the next attribute from Java to Matlab types
        attrib = attribArray.item(ii-1);
        attribName = char(attrib.getName());
        attribValue = char(attrib.getValue());
        
        if isempty(name)
            % get all attributes
            attributes{ii} = attrib;
            names{ii} = attribName;
            values{ii} = attribValue;
            isMatch(ii) = true;
            
        elseif strcmp(name, attribName)
            % found one named attribute
            attributes = attrib;
            names = attribName;
            values = attribValue;
            return;
        end
    end
    
    % squeeeze out attributes that did not match the given name
    attributes = attributes(isMatch);
    names = names(isMatch);
end