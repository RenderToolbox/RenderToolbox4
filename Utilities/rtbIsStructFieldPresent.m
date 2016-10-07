function isPresent = rtbIsStructFieldPresent(s, fieldName)
%% Does a struct have a particular field?
%
% isPresent = rtbIsStructFieldPresent(s, fieldName) returns true if the
% given struct s has a field with the given name fieldName,
% and if that field is not empty.  Otherwise returns false.
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('s', @isstruct);
parser.addRequired('fieldName', @ischar);
parser.parse(s, fieldName);
s = parser.Results.s;
fieldName = parser.Results.fieldName;

isPresent = isstruct(s) ...
    && isfield(s, fieldName) ...
    && ~isempty(s.(fieldName));

