function recipe = rtbUnpackRecipe(archiveName, varargin)
%% Load a recipe and its file dependencies from an archive file.
%
% recipe = rtbUnpackRecipe(archiveName) Creates a new recipe struct based
% on the given archiveName, as produced by rtbPackUpRecipe().  Also unpacks
% recipe file dependencies that were saved in the archive, to the current
% working folder.
%
% Returns a new recipe struct that was contained in the given archiveName.
%
% rtbUnpackRecipe( ... 'hints', hints) specifies a struct of RenderToolbox4
% options to use with the new recipe.  In particular, the given
% hints.workingFolder will be used for unpacking the recipe.
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('archiveName', @ischar);
parser.addParameter('hints', rtbDefaultHints(), @isstruct);
parser.parse(archiveName, varargin{:});
archiveName = parser.Results.archiveName;
hints = rtbDefaultHints(parser.Results.hints);

[~, archiveBase] = fileparts(archiveName);

%% Set up a clean, temporary folder.
tempFolder = fullfile(tempdir(), 'RenderToolbox4', 'UnpackRecipe', archiveBase);
if exist(tempFolder, 'dir')
    rmdir(tempFolder, 's');
end
mkdir(tempFolder);

%% Unpack the archive to the temporary folder.
unzip(archiveName, tempFolder);

% extract the recipe struct
recipeFiles = rtbFindFiles('root', tempFolder, 'filter', 'recipe\.mat');
if 1 == numel(recipeFiles)
    recipeFileName = recipeFiles{1};
else
    error('RenderToolbox4:UnpackRecipeNotFound', ...
        ['Could not find recipe.mat in the given archive ' archiveName]);
end
matData = load(recipeFileName);
recipe = matData.recipe;

%% Update recipe hints with local configuration.
recipe.input.hints.workingFolder = hints.workingFolder;

%% Copy dependencies from the temp folder to the local working folder.
dependencies = rtbFindFiles('root', tempFolder);
dependencyBasePath = fullfile(tempFolder, archiveBase);
for ii = 1:numel(dependencies)
    tempPath = dependencies{ii};
    if strfind(tempPath, 'recipe.mat')
        continue;
    end
    
    [~, relativePath] = rtbIsPathPrefix(dependencyBasePath, tempPath);
    localPath = rtbWorkingAbsolutePath(relativePath, 'hints', recipe.input.hints);
    
    localPrefix = fileparts(localPath);
    if ~exist(localPrefix, 'dir')
        mkdir(localPrefix);
    end
    
    [isSuccess, message] = copyfile(tempPath, localPath);
    if ~isSuccess
        warning('RenderToolbox4:UnpackRecipeCopyError', ...
            ['Error unpacking recipe file: ' message]);
    end
end

%% Clean up.
rmdir(tempFolder, 's');
