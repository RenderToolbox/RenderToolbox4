function recipe = rtbMakeRecipeRenderings(recipe)
%% Make renderings from a recipe's native scene files.
%
% recipe = rtbMakeRecipeRenderings(recipe) Uses the given recipe's renderer
% native scene descriptions to produce renderings, using the given
% recipe.input.hints.renderer.
%
% Returns the given recipe, with recipe.rendering.radianceDataFiles
% filled in.
%
% recipe = rtbMakeRecipeRenderings(recipe)
%
%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

parser = inputParser();
parser.addRequired('recipe', @isstruct);
parser.parse(recipe);
recipe = parser.Results.recipe;

recipe = rtbChangeToRecipeFolder(recipe);

recipe.rendering.radianceDataFiles = {};
errorData = [];
try
    recipe.rendering.radianceDataFiles = rtbBatchRender( ...
        recipe.rendering.scenes, 'hints', recipe.input.hints);
    
catch errorData
    % fills in placeholder above, log it below
end

% put this execution in the log with any error data
recipe = rtbAppendRecipeLog(recipe, ...
    'comment', ['run automatically by ' mfilename()], ...
    'executed', @BatchRender, ...
    'errorData', errorData);
