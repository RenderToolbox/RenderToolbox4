%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
%% Import Macbeth ColorChecker colorimetric from Psychtoolbox format. 

% convert Psychtoolbox colorimetric mat-files to spd-files expected by PBRT
% and Mitsuba
[macbethPath, macbethName] = fileparts(mfilename('fullpath'));
matFile = fullfile(macbethPath, 'sur_mccBabel.mat');
outFiles = rtbImportPsychColorimetricMatFile(matFile);