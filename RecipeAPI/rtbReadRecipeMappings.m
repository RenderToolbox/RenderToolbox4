function recipe = rtbReadRecipeMappings(recipe)
%% Parse mappings from file and save in recipe struct
%
% recipe = rtbReadRecipeMappings(recipe) reads RenderToolbox4 mappings from
% recipe.input.mappingsFile and saves the results in
% recipe.rendering.mappings.
%
% Returns the given recipe, with parsed mappings.
%
% recipe = rtbReadRecipeMappings(recipe)
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('recipe', @isstruct);
parser.parse(recipe);
recipe = parser.Results.recipe;

recipe.rendering.mappings = [];
if rtbIsStructFieldPresent(recipe.input, 'mappingsFile')
    strategy = rtbChooseStrategy('hints', recipe.input.hints);
    recipe.rendering.mappings = ...
        strategy.loadMappings(recipe.input.mappingsFile);
end
