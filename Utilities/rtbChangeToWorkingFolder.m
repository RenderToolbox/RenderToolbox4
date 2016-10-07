function wasCreated = rtbChangeToWorkingFolder(varargin)
%% Change to the working folder for a recipe, create it if necessary.
%
% wasCreated = rtbChangeToWorkingFolder('hints', hints) will cd() to the
% working folder for the given hints, used by a recipe, creating the
% working folder if it doesn't exist yet.
%
% Returns true if @a folder had to be created.
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addParameter('hints', rtbDefaultHints(), @isstruct);
parser.parse(varargin{:});
hints = rtbDefaultHints(parser.Results.hints);

workingFolder = rtbWorkingFolder('hints', hints);
wasCreated = rtbChangeToFolder(workingFolder);
