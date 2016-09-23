%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
%% Render MaterialSphere in a portable fashion using the Recipe API.

%% Top Half.
clear;

%% Choose inputs for a new recipe.

parentSceneFile = 'MaterialSphere.blend';
conditionsFile = 'MaterialSphereConditions.txt';
mappingsFile = 'MaterialSphereMappings.json';

% choose the order of operations for rendering the recipe
executive = { ...
    @rtbMakeRecipeSceneFiles, ...
    @rtbMakeRecipeRenderings, ...
    @rtbMakeRecipeMontage, ...
    };

%% Choose RenderToolbox4 options.
hints.imageWidth = 200;
hints.imageHeight = 160;
hints.fov = 49.13434 * pi() / 180;
hints.recipeName = mfilename();

% use a temporary working folder, which will be deleted below
workingPortable = fullfile(rtbWorkingFolder(), 'portable');
hints.workingFolder = workingPortable;

% put output files in a subfolder named like this script
hints.recipeName = 'rtbMakeMaterialSpherePortable';

% choose the renderer
hints.renderer = 'Mitsuba';


%% Make a new recipe that contains all of the above choices.
recipe = rtbNewRecipe( ...
    'executive', executive, ...
    'parentSceneFile', parentSceneFile, ...
    'conditionsFile', conditionsFile, ...
    'mappingsFile', mappingsFile, ...
    'hints', hints);

% add a log message about creating this new recipe
recipe = rtbAppendRecipeLog(recipe, 'comment', 'Portable recipe for Material Sphere');

%% Move resource files inside the workingFolder, so they can be detected.
resourceFiles = { ...
    fullfile(rtbRoot(), 'RenderData/Macbeth-ColorChecker/mccBabel-11.spd'), ...
    fullfile(rtbRoot(), 'RenderData/Macbeth-ColorChecker/mccBabel-7.spd'), ...
    fullfile(rtbRoot(), 'RenderData/PBRTMetals/Au.eta.spd'), ...
    fullfile(rtbRoot(), 'RenderData/PBRTMetals/Au.k.spd'), ...
    fullfile(rtbRoot(), 'ExampleScenes/MaterialSphere/earthbump1k-stretch-rgb.exr')};

resources = rtbWorkingFolder( ...
    'folderName', 'resources', ...
    'rendererSpecific', false, ...
    'hints', hints);
for ii = 1:numel(resourceFiles)
    copyfile(resourceFiles{ii}, resources);
end

%% Generate scene files and pack up the recipe.
% generate all the scene files for the recipe
recipe = rtbExecuteRecipe(recipe, 'whichExecutives', 1);

% pack up the recipe with resources and pre-generated scene files
%   don't pack up boring temp files
archiveName = fullfile(rtbWorkingFolder(), 'MaterialSpherePortable.zip');
rtbPackUpRecipe(recipe, archiveName, 'ignoreFolders', {'temp'});

% boldly delete the working folder, now that the recie is packed up
rmdir(workingPortable, 's');

%% Bottom Half.
clear;

%% Un-pack and render in a new location -- could be on another computer.
% locate the packed-up recipe
% change this archiveName if you moved to another computer
archiveName = fullfile(rtbWorkingFolder(), 'MaterialSpherePortable.zip');

% un-pack the recipe into the new folder
hints = rtbDefaultHints();
recipe = rtbUnpackRecipe(archiveName, 'hints', hints);

% render the recipe from pre-generated scene files
recipe = rtbExecuteRecipe(recipe);
