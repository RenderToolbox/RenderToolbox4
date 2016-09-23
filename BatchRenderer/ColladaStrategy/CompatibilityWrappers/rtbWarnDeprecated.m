function rtbWarnDeprecated(varargin)
%% Print an irritating warning about calling a deprecated function.
%
% rtbWarnDeprecated('oldName', oldName, 'newName', newName) prints an
% irritating warning that a function with the given oldName has been
% called, and that the user should update their code to use a function with
% the given newName, instead.
%
% rtbWarnDeprecated() attempts to discover the name of the calling
% function, and uses that as the oldName.  It prepends 'rtb' to this
% oldName and uses the result for newName.
%
%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

callStack = dbstack();
if numel(callStack) > 1
    callerName = callStack(2).name;
else
    callerName = '';
end

parser = inputParser();
parser.addParameter('oldName', callerName, @ischar);
parser.addParameter('newName', '', @ischar);
parser.parse(varargin{:});
oldName = parser.Results.oldName;
newName = parser.Results.newName;

if isempty(newName)
    newName = ['rtb' oldName];
end

fprintf('\nWarning: %s is deprecated and will be removed.\n', oldName);
fprintf('Please use %s instead.\n\n', newName);
