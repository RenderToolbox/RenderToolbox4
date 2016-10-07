function summary = rtbPrintRecipeLog(recipe, varargin)
%% Print a recipe's log as formatted text.
%
% summary = rtbPrintRecipeLog(recipe) prints a compact summary of the log
% data for the given as nicely formatted text.
%
% rtbPrintRecipeLog( ... 'verbose', verbose) specify whether to print
% verbose log data (true) or a compact log summary (false).  The default is
% false, print a compact summary.
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('recipe', @isstruct);
parser.addParameter('verbose', false, @islogical);
parser.parse(recipe, varargin{:});
recipe = parser.Results.recipe;
verbose = parser.Results.verbose;


%% Print a paragraph for each log entry.
summary = '';
for ii = 1:numel(recipe.log)
    log = recipe.log(ii);
    
    % what was executed
    exec = getString(log.executed, 'nothing', 'unknown');
    index = getString(log.executiveIndex, 'none', 'unknown');
    line = ['executed: ' exec ' (index: ' index ')'];
    summary = appendLogLine(summary, line);
    
    % when it was executed
    when = getString(log.when, 'never', 'unknown');
    line = ['at: ' when];
    summary = appendLogLine(summary, line);
    
    if verbose
        % who executed it
        user = getString(log.userName, 'nobody', 'unknown');
        host = getString(log.hostName, 'none', 'unknown');
        line = ['by user: ' user ', on host: ' host];
        summary = appendLogLine(summary, line);
    end
    
    % arbitrary comment
    comment = getString(log.comment, 'none', 'unknown');
    line = ['comment: ' comment];
    summary = appendLogLine(summary, line);
    
    % error info
    err = getString(log.errorData, 'none', 'unknown');
    line = ['with error: ' err];
    summary = appendLogLine(summary, line);
    
    if verbose && isa(log.errorData, 'MException')
        trace = log.errorData.getReport();
        line = 'stack trace:';
        summary = appendLogLine(summary, line);
        summary = appendLogLine(summary, trace);
    end
    
    summary = appendLogLine(summary, '');
end

if 0 == nargout
    disp(summary)
end


function summary = appendLogLine(summary, line)
summary = sprintf('%s\n%s', summary, line);


function string = getString(value, emptyName, unknownName)
if isempty(value)
    string = emptyName;
elseif isnumeric(value)
    string = num2str(value);
elseif isa(value, 'function_handle')
    string = func2str(value);
elseif ischar(value)
    string = value;
elseif isa(value, 'MException')
    string = [value.identifier ', ' value.message];
else
    string = unknownName;
end
