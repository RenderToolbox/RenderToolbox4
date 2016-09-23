function [value, property] = rtbGetMappingProperty(mapping, name, defaultValue)
%% Get a property value nested within a mapping struct.
%
% value = rtbGetMappingProperty(mapping, name, defaultValue) selects a
% property nested in the given mapping.properties based on the given name
% and returns the selected property.value.  If no such property is found,
% returns the given defaultValue.
%
% Also returns the type associated with the value, if found.
%
% [value, property] = rtbGetMappingProperty(mapping, name, defaultValue)
%
% Copyright (c) 2016 mexximp Team

parser = inputParser();
parser.addRequired('mapping', @isstruct);
parser.addRequired('name', @ischar);
parser.addRequired('defaultValue');
parser.parse(mapping, name, defaultValue);
mapping = parser.Results.mapping;
name = parser.Results.name;
defaultValue = parser.Results.defaultValue;

%% Locate the nested adjustment by name.
propertyNames = {mapping.properties.name};
propertyIndex = find(strcmp(propertyNames, name), 1, 'first');
if isempty(propertyIndex)
    value = defaultValue;
    property = [];
    return;
end
value = mapping.properties(propertyIndex).value;
property = mapping.properties(propertyIndex);
