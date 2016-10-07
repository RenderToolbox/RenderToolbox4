function errorData = rtbGetFirstRecipeError(recipe, throwException)
%% Get the first logged recipe error, if any.
%
% errorData = rtbGetFirstRecipeError(recipe, throwException) searches the
% given recipe.log for errors and returns the first one found, if any.
%
% If throwException is true, and the first error is a Matlab MException,
% rethrows the exception (which gives a handy stack trace in the command
% window).  Otherwise, returns the first error found, if any.
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('recipe', @isstruct);
parser.addRequired('throwException', @islogical);
parser.parse(recipe, throwException);
recipe = parser.Results.recipe;
throwException = parser.Results.throwException;

errorData = [];

if rtbIsStructFieldPresent(recipe, 'log')
    for ii = 1:numel(recipe.log)
        errorData = recipe.log(ii).errorData;
        if ~isempty(errorData)
            break;
        end
    end
end

if throwException && isa(errorData, 'MException')
    rethrow(errorData)
end
