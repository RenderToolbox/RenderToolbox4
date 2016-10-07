%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Create a new document element.
%   @param element document element to be the parent of the new element
%   @param name string node name for the new element
%   @param id string unique identifier for the new element (optional)
%   @param where 'first', 'last', or child element to replace (optional)
%
% @details
% Create a new document element that is a child of the given @a element.
% @a element must be an element node from an scene document, as returned
% from SearchScene().  @a name must be the string node name for the new
% element.
%
% @details
% If @a id is provided, the new element will have an "id" attribute with
% the value of @a id.
%
% @details
% By default, appends the new element to the list of children of the given
% @a element.  If @a toReplace is provided, it may be the string 'first',
% the string 'last', or an element object that is an existing shild of the
% given @a element.  The new element will be located as follows:
%   - 'first' - new element will be prepended before other child elements
%   - 'last' - new element will be appended after other child elements
%   - existing child - new element will replace the given child element
%   .
%
% @details
% Returns the new document element.
%
% @details
% Usage:
%   newElement = CreateElementChild(element, name, id, where)
%
% @ingroup SceneDOM
function newElement = CreateElementChild(element, name, id, where)

if nargin < 3
    id = '';
end

if nargin < 4
    where = 'last';
end

% make a new node with the given name
doc = element.getOwnerDocument();
newElement = doc.createElement(name);
if isjava(where)
    % new element replaces the given child
    parent = where.getParentNode();
    parent.replaceChild(newElement, where);
    
elseif ischar(where) && strcmp('first', where)
    % new element is the first child
    element.insertBefore(newElement, element.getFirstChild());
    
else
    %if strcmp('last', where)
    % new element is the last child
    element.appendChild(newElement);
end

% add id attribute to the new node
if ~isempty(id)
    idAttribute = doc.createAttribute('id');
    idAttribute.setValue(id);
    newElement.setAttributeNode(idAttribute);
end