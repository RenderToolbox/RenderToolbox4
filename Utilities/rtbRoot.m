function rootPath = rtbRoot()
%% Get the path to RenderToolbox4.
%
% rootPath = rtbRoot() returns the absolute path to RenderToolbox4, based
% on the location of this file, rtbRoot.m.
%
%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

filePath = mfilename('fullpath');
lastSeps = find(filesep() == filePath, 2, 'last');
rootPath = filePath(1:(lastSeps(1) - 1));
