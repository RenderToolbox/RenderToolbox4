function recipe = rtbAppendRecipeLog(recipe, varargin)
%% Add an entry to the recipe's execution log.
%
% recipe = rtbAppendRecipeLog(recipe)
% Appends an entry to the ececution log of the given recipe.  The log entry
% will contain the current date and time, current user name, and current
% computer's host name.
%
% rtbAppendRecipeLog( ... name, value) adds additional named values to the
% log entry.  Acceptable name-value pairs include:
%   - comment -- any user-supplied comment
%   - executed -- the name or handle of a script or function
%   - errorData -- any error data or exception associated with executed
%   - executiveIndex -- any index associated with executed
%
% Returns the updated recipe.
%
%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

parser = inputParser();
parser.addRequired('recipe', @isstruct);
parser.addParameter('comment', '', @ischar);
parser.addParameter('executed', []);
parser.addParameter('errorData', []);
parser.addParameter('executiveIndex', 0, @isnumeric);
parser.parse(recipe, varargin{:});
recipe = parser.Results.recipe;
comment = parser.Results.comment;
executed = parser.Results.executed;
errorData = parser.Results.errorData;
executiveIndex = parser.Results.executiveIndex;

%% Build the new log entry.
logData.comment = comment;
logData.executed = executed;
logData.when = datestr(now());
logData.errorData = errorData;
logData.userName = char(java.lang.System.getProperty('user.name'));
logData.hostName = char(java.net.InetAddress.getLocalHost.getHostName);
logData.executiveIndex = executiveIndex;


%% Append entry to the recipe log.
if rtbIsStructFieldPresent(recipe, 'log')
    recipe.log(end+1) = logData;
else
    recipe.log = logData;
end
