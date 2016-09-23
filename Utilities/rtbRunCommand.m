function [status, result, exception] = rtbRunCommand(command, varargin)
%% Run a system command, capture results or display them live.
%
% [status, result, exception] = rtbRunCommand(command, 'hints', hints)
% executes the given command string using Matlab's built-in
% system() function, and attempts to capture status codes and messages that
% result.  Attempts to never throw an exception.  Instead, captures and
% returns any exception thrown.
%
% If the given hints.isCaptureCommandResults is false, allows Matlab to
% print command results to the Command Window immediately as they happen,
% instead of capturing them.
%
% Returns the numeric status code and string result from the system()
% function.  The result may be empty, if hints.isCaptureCommandResults is
% false.  Also returns any exception that was thrown during command
% execution, or empty [] if no exception was thrown.
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

parser = inputParser();
parser.addRequired('command', @ischar);
parser.addParameter('hints', rtbDefaultHints(), @isstruct);
parser.parse(command, varargin{:});
command = parser.Results.command;
hints = rtbDefaultHints(parser.Results.hints);

status = [];
result = '';
exception = [];

fprintf('%s\n', command);

if hints.isCaptureCommandResults
    try
        [status, result] = system(command);
    catch exception
    end
else
    try
        status = system(command);
    catch exception
    end
end
