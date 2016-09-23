function [numbers, nNums] = rtbReadStringNumbers(string, varargin)
%% Read numbers from a string, with optional grouping.
%
% [numbers, nNums] = rtbReadStringNumbers(string) reads decimal number
% representations from the given string.
%
% Returns numbers as separate elements of a cell array of strings.  Also
% returns the total count of numbers found in in the given string.
%
% rtbReadStringNumbers( ... 'nGrouping', nGrouping) specifies how to group
% numbers in the output.  The default is 1, each element of the cell array
% of strings will contain 1 number.
%
%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

parser = inputParser();
parser.addRequired('string', @ischar);
parser.addParameter('nGrouping', 1, @isnumeric);
parser.parse(string, varargin{:});
string = parser.Results.string;
nGrouping = parser.Results.nGrouping;

% convert to double array
valueNum = StringToVector(string);
nNums = numel(valueNum);

% convert back to individual or grouped strings
nValues = floor(nNums/nGrouping);
numbers = cell(1, nValues);
for ii = 1:nValues
    numIndices = (1:nGrouping) + (ii-1) * nGrouping;
    numbers{ii} = VectorToString(valueNum(numIndices));
end
