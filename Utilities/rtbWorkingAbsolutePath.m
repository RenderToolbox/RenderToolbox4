function absolutePath = rtbWorkingAbsolutePath(originalPath, varargin)
%% Convert a relative working path to an absoute path.
%
% absolutePath = rtbWorkingAbsolutePath(originalPath, 'hints', hints)
% converts the given originalPath to an absolute path.  Assumes
% that originalPath is a relative path relative to the working folder
% specified by the given hints.  See rtbWorkingFolder().
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('originalPath', @ischar);
parser.addParameter('hints', rtbDefaultHints(), @isstruct);
parser.parse(originalPath, varargin{:});
originalPath = parser.Results.originalPath;
hints = rtbDefaultHints(parser.Results.hints);

workingFolder = rtbWorkingFolder('hints', hints);
absolutePath = fullfile(workingFolder, originalPath);
