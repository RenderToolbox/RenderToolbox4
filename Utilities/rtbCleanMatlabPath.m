function rtbCleanMatlabPath()
% Remove '.svn' and '.git' folders from the Matlab path.
%
% rtbCleanMatlabPath() Modifies the Matlab path, removing path entries that
% contain '.git' or '.svn'.  You might want to call savepath() afterwards.
%
% You can use this function while the Matlab "Set Path" dialog is open!
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

% get the Matlab path
pathString = path();

% remove .svn and .git folders
pathString = rtbRemoveMatchingPaths(pathString, '.svn');
pathString = rtbRemoveMatchingPaths(pathString, '.git');

% set the cleaned-up path
path(pathString);