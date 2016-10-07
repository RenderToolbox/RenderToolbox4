function recipe = rtbExecuteRecipe(recipe, varargin)
%% Execute the given recipe and make long entries.
%
% recipe = rtbExecuteRecipe(recipe) First calls rtbConfigureForRecipe(), then
% executes each of the scripts or functions in the given
% recipe.input.executive, and makes a log entry for each.  If a
% corresponding log entry already exists, skips that script or funciton and
% moves on to the next.
%
% To make sure that no executive scripts or functions are skipped, first
% call rtbCleanRecipe() or supply whichExecutives explicitly.
%
% recipe = rtbExecuteRecipe( ... 'whichExecutives', whichExecutives) specify
% an array of indices used to select specific scripts or functions from
% recipe.input.executive.  All and only these will be executed, regardless
% of whether corresponding log entries exist.
%
% recipe = rtbExecuteRecipe( ... 'throwException', throwException) specify
% what to do if an error is encountered during execution.  If
% throwException is true, exceptions will be caught and logged, and then
% re-thrown to the caller.  This is the default.  If throwException is
% false, exceptions will be logged and execution will continue.
%
% Returns the given recipe, with recipe.log filled in.
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('recipe', @isstruct);
parser.addParameter('whichExecutives', [], @isnumeric);
parser.addParameter('throwException', true, @islogical);
parser.parse(recipe, varargin{:});
recipe = parser.Results.recipe;
whichExecutives = parser.Results.whichExecutives;
throwException = parser.Results.throwException;

if isempty(whichExecutives)
    skipAlreadyLogged = true;
    whichExecutives = 1:numel(recipe.input.executive);
else
    skipAlreadyLogged = false;
end

%% Run the execvutive functions/scripts in order.
recipe = rtbConfigureForRecipe(recipe);

for ii = whichExecutives
    errorData = [];
    
    try
        executive = recipe.input.executive{ii};
        
        if skipAlreadyLogged
            alreadyExecuted = [recipe.log.executiveIndex];
            if any(ii == alreadyExecuted)
                continue;
            end
        end
        
        if isa(executive, 'function_handle')
            recipe = feval(executive, recipe);
        elseif ischar(executive)
            rtbCurrentRecipe(recipe);
            run(executive);
            recipe = rtbCurrentRecipe();
        end
        
    catch errorData
        % fills in placeholder above, log it below
    end
    
    % put this execution in the log with any error data
    recipe = rtbAppendRecipeLog(recipe, ...
        'comment', ['run automatically by ' mfilename()], ...
        'executed', executive, ...
        'errorData', errorData, ...
        'executiveIndex', ii);
    
    errorData = rtbGetFirstRecipeError(recipe, throwException);
    if ~isempty(errorData)
        break;
    end
end
