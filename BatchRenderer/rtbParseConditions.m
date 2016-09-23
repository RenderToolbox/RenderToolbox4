function [names, values] = rtbParseConditions(conditionsFile)
%% Read conditions data from a text file.
%
% [names, values] = rtbParseConditions(conditionsFile)
% Reads batch renderer condition variables from the given conditionsFile.
% See the RenderToolbox4 wiki for more about conditions files:
%   https://github.com/DavidBrainard/RenderToolbox4/wiki/Conditions-File-Format
%
% Returns a 1 x n cell array of string variable names from the first line
% of conditionsFile.  Also returns an m x n cell array
% of varible values, with m values per variable, from subsequent lines.
%
% [names, values] = rtbParseConditions(conditionsFile)
%
%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

parser = inputParser();
parser.addRequired('conditionsFile', @ischar);
parser.parse(conditionsFile);
conditionsFile = parser.Results.conditionsFile;

%% Prepare to read conditions file.
if 2 ~= exist(conditionsFile, 'file')
    names = {};
    values = {};
    return;
end

fid = fopen(conditionsFile, 'r');
if -1 == fid
    names = {};
    values = {};
    warning('Cannot open conditions file "%s".', conditionsFile);
    return;
end

columnPattern = '([\S ]+)[\t,]*';
commentPattern = '^\s*\%';

%% Read variable names from the first line.
nextLine = fgetl(fid);
nameTokens = regexp(nextLine, columnPattern, 'tokens');
nNames = numel(nameTokens);
names = cell(1, nNames);
% dig out individual names
for ii = 1:nNames
    names(ii) = nameTokens{ii}(1);
end

%% Read values from subsequent lines.
nValues = 0;
values = cell(nValues,nNames);
nextLine = fgetl(fid);
while ischar(nextLine)
    % skip comment lines
    if isempty(regexp(nextLine, commentPattern, 'once'))
        valueTokens = regexp(nextLine, columnPattern, 'tokens');
        if numel(valueTokens) == nNames
            nValues = nValues + 1;
            % dig out individual names
            for ii = 1:nNames
                values(nValues,ii) = valueTokens{ii}(1);
            end
        end
    end
    nextLine = fgetl(fid);
end

%% Done with file.
fclose(fid);
