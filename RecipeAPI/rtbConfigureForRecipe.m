%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Configure RenderToolbox4 to run the given recipe.
%   @param recipe a recipe struct
%
% @details
% Attempts to configure RenderToolbox4 for rendering the given @a recipe
% using @a recipe.input.configureScript.
%
% @details
% Sets the "current recipe" so that @a recipe.input.configureScript may
% access and modify the given @a recipe using rtbCurrentRecipe();
%
% @details
% Returns the given @a recipe, possibly updated by @a
% recipe.input.configureScript, possibly with a new error appended.
%
% @details
% Usage:
%   recipe = rtbConfigureForRecipe(recipe)
%
% @ingroup RecipeAPI
function recipe = rtbConfigureForRecipe(recipe)

parser = inputParser();
parser.addRequired('recipe', @isstruct);
parser.parse(recipe);
recipe = parser.Results.recipe;

recipe = rtbChangeToRecipeFolder(recipe);

errorData = [];
try
    % set the current recipe so that configureScript can access it
    rtbCurrentRecipe(recipe);
    run(recipe.input.configureScript);
    
catch errorData
    % fills in placeholder above, log it below
end

% get the current recipe in case configureScript modified it
recipe = rtbCurrentRecipe();

% put this execution in the log with any error data
recipe = rtbAppendRecipeLog(recipe, ...
    'comment', ['run automatically by ' mfilename()], ...
    'executed', recipe.input.configureScript, ...
    'errorData', errorData);
