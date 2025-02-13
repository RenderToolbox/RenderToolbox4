function jsonString = rtbWriteJson(data, varargin)
%% Convert a Matlab struct or array to a JSON string.
%
% jsonString = rtbWriteJson(data) takes the given Matlab data, which may be
% a struct, numeric array, or cell array, and converts it to a JSON string.
%
% rtbWriteJson( ... 'fileName', fileName) specifies the file name to write
% to.  The default is no file, just return the JSON string.
%
% jsonString = rtbWriteJson(data)
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('data', @(data) isstruct(data) || iscell(data) || isnumeric(data));
parser.addParameter('fileName', '', @ischar);
parser.parse(data, varargin{:});
data = parser.Results.data;
fileName = parser.Results.fileName;

jsonString = savejson('', data, ...
    'FloatFormat', '%.16g', ...
    'ArrayToStruct', 0, ...
    'ParseLogical', 1, ...
    'FileName', fileName);
