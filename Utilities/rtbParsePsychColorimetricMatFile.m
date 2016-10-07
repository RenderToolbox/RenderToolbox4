function [data, S, category, name] = rtbParsePsychColorimetricMatFile(dataFile)
% Read data and metadata from a Psychtoolbox colorimetric .mat file.
%
% data = rtbParsePsychColorimetricMatFile(dataFile)
% Reads the colorimetric data and associated spectral sampling from the
% given dataFile, which should be a Psychtoolbox colorimetric mat-file.
% Also parses the name of dataFile according to Pyschtoolox conventions.
%
% For more about Psychtooblox colorimetric mat-files and conventions, see
% the Psychtoolbox web documentation:
%   http://docs.psychtoolbox.org/PsychColorimetricMatFiles
%
% Returns colorimetric data matrix from the given dataFile, the "S"
% description of the data's spectral sampling, the category prefix from the
% file name, and the descriptive base file name.
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
% parse the file name for its category and descriptive name

parser = inputParser();
parser.addRequired('dataFile', @ischar);
parser.parse(dataFile);
dataFile = parser.Results.dataFile;

%% Parse the file name by convention.
[~, matBase, ~] = fileparts(dataFile);
nameBreak = find('_' == matBase, 1, 'first');
category = matBase(1:nameBreak-1);
name = matBase(nameBreak+1:end);

%% Read colorimetric data and sampling from conventional variable names.
matData = load(dataFile);
data = matData.(matBase);
samplingName = sprintf('S_%s', name);
S = matData.(samplingName);
