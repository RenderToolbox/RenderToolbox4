%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Get a Matlab struct representation of an XML element.
%   @param element XML element object
%
% @details
% Builds a Matlab struct based on an XML element.  The fields of the struct
% will have the same names as the element's child elements, and will
% contain nested structs that represent the children.  A special "text"
% field will contain the text content of each element.  A special
% "attributes" field will contain a struct with the attribute names and
% values for each element.
%
% @details
% ElementToStruct() makes a "reasonable effort" to represent XML notes as
% Matlab structs, but it does not handle all cases.  For example:
%   - Child elements named "text" or "attributes" will be overwritten by
%  special fields.
%   - Child elements with duplicate names will be overwritten.
%   - Child elements with names that are not valid struct field names will
%   be ignored, for example "#comment" of "#text".
%   - There's no StructToElement() function to convert a struct back to
%   XML.
%   - It might perform badly for elements with many children (i.e. large
%   documents).
% .
%
% @details
% Returns a Matlab struct that represents the given XML @a element.
%
% @details
% Usage:
%   elementStruct = ElementToStruct(element)
%
% @ingroup SceneDOM
function elementStruct = ElementToStruct(element)

% raw text to matlab char
text = char(element.getTextContent());

% struct with attribute names and values
attributeStruct = struct();
[attributes, names, values] = GetElementAttributes(element);
for ii = 1:numel(names)
    attributeStruct.(names{ii}) = values{ii};
end

% nested struct for each child element
elementStruct = struct('text', text, 'attributes', attributeStruct);
[children, names] = GetElementChildren(element);
for ii = 1:numel(names)
    if isvarname(names{ii})
        elementStruct.(names{ii}) = ElementToStruct(children{ii});
    end
end