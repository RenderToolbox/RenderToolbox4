function data = rtbReadJson(jsonString)
%% Convert a JSON string to a Matlab struct or array.
%
% data = rtbReadJson(jsonString) parses the given jsonString into Matlab
% data, which may be a struct, numeric array, or cell array.
%
% data = rtbReadJson(jsonString)
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

parser = inputParser();
parser.addRequired('jsonString', @ischar);
parser.parse(jsonString);
jsonString = parser.Results.jsonString;

data = loadjson(jsonString);
