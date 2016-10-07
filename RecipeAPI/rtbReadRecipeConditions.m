function recipe = rtbReadRecipeConditions(recipe)
%% Parse conditions from file and save in recipe struct
%
% recipe = rtbReadRecipeConditions(recipe) reads RenderToolbox4 conditions
% from recipe.input.conditionsFile and saves the results in
% recipe.rendering.conditions.
%
% Returns the given recipe, with parsed conditions.
%
% recipe = rtbReadRecipeConditions(recipe)
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('recipe', @isstruct);
parser.parse(recipe);
recipe = parser.Results.recipe;

recipe.rendering.conditions = [];
if rtbIsStructFieldPresent(recipe.input, 'conditionsFile')
    strategy = rtbChooseStrategy('hints', recipe.input.hints);
    [recipe.rendering.conditions.names, ...
        recipe.rendering.conditions.values] = ...
        strategy.loadConditions(recipe.input.conditionsFile);
end
