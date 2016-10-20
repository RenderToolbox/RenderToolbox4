function [value, isMatched] = rtbGetNamedNumericValue(names, values, name, defaultValue)
%% Find a numeric value by name, or use a default.
%
% value = rtbGetNamedNumericValue(names, values, name, defaultValue)
% Locates the given name among the cell array of given names, and returns
% the corresponding value from the cell array of given values, as a numeric
% matrix.  If no such name is found, returns the given defaultValue.
%
% This is a convenience function to make it a one-liner to access names and
% numeric values from parallel cell arrays.
%
% [value, isMatched] = rtbGetNamedNumericValue(names, values, name, defaultValue)
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('names', @iscellstr);
parser.addRequired('values', @iscell);
parser.addRequired('name', @ischar);
parser.addRequired('defaultValue', @isnumeric);
parser.parse(names, values, name, defaultValue);
names = parser.Results.names;
values = parser.Results.values;
name = parser.Results.name;
defaultValue = parser.Results.defaultValue;

[rawValue, isMatched]  = rtbGetNamedValue(names, values, name, defaultValue);
value = sscanf(rawValue, '%f');
