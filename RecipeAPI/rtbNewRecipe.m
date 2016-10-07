function recipe = rtbNewRecipe(varargin)
%% Start a new recipe from scratch.
%
% recipe = rtbNewRecipe()
% Create a brand new RenderToolbo3 recipe struct with standard fields and
% default values. The default recipe will be not-vert-useful, but will have
% the correct form.
%
% recipe = rtbNewRecipe( ... 'configureScript', configureScript) specify the
% the name of a RenderToolbox4 system configuration script to run before
% executing the recipe.  This might be a locally modified copy of
% rtbLocalConfigTemplate.m.
%
% recipe = rtbNewRecipe( ... 'executive', executive) specify a cell array of
% function_handles or string script names to be executed for this recipe.
% All function_handles must refer to functions that expect a recipe as the
% first argument return the recipe as the first output.  All strings must
% refer to m-files that use rtbCurrentRecipe() to access and modify the
% current recipe.
%
% recipe = rtbNewRecipe( ... 'parentSceneFile', parentSceneFile) specify the
% recipe's parent scene file, such as a Collada file.
%
% recipe = rtbNewRecipe( ... 'conditionsFile', conditionsFile) specify the
% name of a RenderToolbox4 conditions file used to control the number of
% and variables used when generating variations on the parent scene file.
%
% recipe = rtbNewRecipe( ... 'mappingsFile', mappingsFile) specify the name of
% a RenderToolbox4 mappings file used to map constants and conditions file
% variables to the parent scene.
%
% recipe = rtbNewRecipe( ... 'hints', hints) specify a a struct of hints as
% from rtbDefaultHints(), which controls aspects of recuipe execution, like
% where to find and write files and which renderer to use.
%
% recipe = rtbNewRecipe(varargin)
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%

parser = inputParser();
parser.addParameter('configureScript', '', @ischar);
parser.addParameter('executive', {}, @iscell);
parser.addParameter('parentSceneFile', '', @ischar);
parser.addParameter('conditionsFile', '', @ischar);
parser.addParameter('mappingsFile', '', @ischar);
parser.addParameter('hints', rtbDefaultHints(), @isstruct);
parser.parse(varargin{:});
configureScript = parser.Results.configureScript;
executive = parser.Results.executive;
parentSceneFile = parser.Results.parentSceneFile;
conditionsFile = parser.Results.conditionsFile;
mappingsFile = parser.Results.mappingsFile;
hints = rtbDefaultHints(parser.Results.hints);

%% Brand new recipe struct with basic fields filled in.
% note: struct() needs executive cell array to be wrapped in another cell
basic = struct( ...
    'configureScript', configureScript, ...
    'executive', {executive}, ...
    'parentSceneFile', parentSceneFile, ...
    'conditionsFile', conditionsFile, ...
    'mappingsFile', mappingsFile, ...
    'hints', hints);
recipe.input = basic;

%% Derive conditions and mappings from respective files.
recipe = rtbReadRecipeConditions(recipe);
recipe = rtbReadRecipeMappings(recipe);

%% "rtbCleanRecipe" is the origin of all other derived field names.
recipe = rtbCleanRecipe(recipe);
