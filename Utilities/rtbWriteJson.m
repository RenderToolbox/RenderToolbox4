function jsonString = rtbWriteJson(data)
%% Convert a Matlab struct or array to a JSON string.
%
% jsonString = rtbWriteJson(data) takes the given Matlab data, which may be
% a struct, numeric array, or cell array, and converts it to a JSON string.
%
% jsonString = rtbWriteJson(data)
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

parser = rdtInputParser();
parser.addRequired('data', @(data) isstruct(data) || iscell(data) || isnumeric(data));
parser.parse(data);
data = parser.Results.data;

jsonString = savejson('', data, ...
    'FloatFormat', '%.16g', ...
    'ArrayToStruct', 0, ...
    'ParseLogical', 1);
