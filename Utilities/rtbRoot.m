function rootPath = rtbRoot()
%% Get the path to RenderToolbox4.
%
% rootPath = rtbRoot() returns the absolute path to RenderToolbox4, based
% on the location of this file, rtbRoot.m.
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

filePath = mfilename('fullpath');
lastSeps = find(filesep() == filePath, 2, 'last');
rootPath = filePath(1:(lastSeps(1) - 1));
