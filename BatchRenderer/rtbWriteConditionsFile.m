function conditionsFile = rtbWriteConditionsFile(conditionsFile, names, values)
%% Write conditions data to a text file.
%
% rtbWriteConditionsFile(conditionsFile, names, values)
% Writes batch renderer condition variables with the given names and
% values to a new text file with the given conditionsFile name.  See the
% RenderToolbox4 wiki for more about conditions files:
%   https://github.com/DavidBrainard/RenderToolbox4/wiki/Conditions-File-Format
%
% Names will appear in the first line of the new file, separated by
% tabs.  Each of the m rows of values will appear in a separate line,
% with elements separated by tabs.  So, the values for each variable will
% appear in a tab-separated column.
%
% Attempts to convert numeric values to string, as needed.
%
% Returns the given conditionsFile file name, for convenience.
%
% conditionsFile = rtbWriteConditionsFile(conditionsFile, names, values)
%
%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

parser = inputParser();
parser.addRequired('conditionsFile', @ischar);
parser.addRequired('names', @iscellstr);
parser.addRequired('values', @iscell);
parser.parse(conditionsFile, names, values);
conditionsFile = parser.Results.conditionsFile;
names = parser.Results.names;
values = parser.Results.values;

%% Create a new file.
conditionsFolder = fileparts(conditionsFile);
if ~isempty(conditionsFolder) && 7 ~= exist(conditionsFolder, 'dir')
    mkdir(conditionsFolder);
end

fid = fopen(conditionsFile, 'w');
if -1 == fid
    warning('Cannot create conditions file "%s".', conditionsFile);
    return;
end

%% Write variable names.
nNames = numel(names);
for ii = 1:nNames
    fprintf(fid, '%s\t', names{ii});
end
fprintf(fid, '\n');

%% Write variable values.
nCols = size(values, 2);
if nCols ~= nNames;
    warning('Number of variable names %d must match number of variable columns %d', ...
        nNames, nCols);
end

nConditions = size(values, 1);
for jj = 1:nConditions
    for ii = 1:nCols
        fprintf(fid, '%s\t', VectorToString(values{jj,ii}));
    end
    fprintf(fid, '\n');
end
fprintf(fid, '\n');

fclose(fid);
