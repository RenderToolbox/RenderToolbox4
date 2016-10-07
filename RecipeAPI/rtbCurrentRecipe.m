function recipe = rtbCurrentRecipe(recipe)
%% Get or set the RenderToolbox4 "current recipe".
%
% rtbCurrentRecipe() controls acceses to a Matlab persistent variable that
% holds the RenderToolbox4 "current recipe".  There can be only one current
% recipe at a time.  The current recipe is a central point of contact
% allowing various scripts that make up a recipe to interact.
%
% In general it's better to work with functions, where we can pass the
% current recipe as an explicit argument.  This function is available in
% case it's not possible to work with functions for some reason.
%
% rtbCurrentRecipe(recipe) sets the current recipe to the given recipe.
%
% recipe = rtbCurrentRecipe() gets the current recipe.
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

persistent CURRENT_RECIPE

if nargin > 0
    CURRENT_RECIPE = recipe;
end
recipe = CURRENT_RECIPE;
