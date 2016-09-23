function archiveName = rtbPackUpRecipe(recipe, archiveName, varargin)
%% Save a recipe and its file dependencies to a zip file.
%
% archiveName = rtbPackUpRecipe(recipe, archiveName) Creates a new zip
% archive named archiveName which contains the given recipe (in a mat-file)
% along with its file dependencies from the current working folder.  See
% rtbWorkingFolder().
%
% rtbPackUpRecipe( ... 'ignoreFolders', ignoreFolders) specifiy a cell
% array of subfolder names to ignore when saving the working folder.  For
% example, {'temp'} would omit the temp folder from the saved archive.  The
% default is to save all subfolders of the working folder.
%
% Returns the name of the zip archive that was created, which may be the
% same as the given archiveName.
%
%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

parser = inputParser();
parser.addRequired('recipe', @isstruct);
parser.addRequired('archiveName', @ischar);
parser.addParameter('ignoreFolders', {}, @iscellstr);
parser.parse(recipe, archiveName, varargin{:});
recipe = parser.Results.recipe;
archiveName = parser.Results.archiveName;
ignoreFolders = parser.Results.ignoreFolders;

[archivePath, archiveBase] = fileparts(archiveName);

%% Set up a clean, temporary folder.
tempFolder = fullfile(tempdir(), 'RenderToolbox4', 'PackUpRecipe', archiveBase);
if exist(tempFolder, 'dir')
    rmdir(tempFolder, 's');
end
mkdir(tempFolder);

%% Save the recipe itself to the working folder.
recipeFileName = fullfile(tempFolder, 'recipe.mat');
save(recipeFileName, 'recipe');

%% Resolve named ignored folders to local file paths.
ignorePaths = cell(size(ignoreFolders));
for ii = 1:numel(ignoreFolders)
    ignorePaths{ii} = rtbWorkingFolder( ...
        'folderName', ignoreFolders{ii}, ...
        'rendererSpecific', false, ...
        'hints', recipe.input.hints);
end

%% Copy dependencies from the working folder to the temp folder.
workingRoot = rtbWorkingFolder('hints', recipe.input.hints);
dependencies = rtbFindFiles('root', workingRoot);
for ii = 1:numel(dependencies)
    localPath = dependencies{ii};
    
    % ignore some files
    if shouldBeIgnored(localPath, ignorePaths);
        continue;
    end
    
    relativePath = rtbGetWorkingRelativePath(localPath, 'hints', recipe.input.hints);
    tempPath = fullfile(tempFolder, relativePath);
    
    % don't try to copy a file to itself
    if exist(tempPath, 'file')
        continue;
    end
    
    % make sure destination exists
    tempPrefix = fileparts(tempPath);
    if ~exist(tempPrefix, 'dir')
        mkdir(tempPrefix);
    end
    
    [isSuccess, message] = copyfile(localPath, tempPath);
    if ~isSuccess
        warning('RenderToolbox4:PackUpRecipeCopyError', ...
            ['Error packing up recipe file: ' message]);
    end
end

%% Zip up the whole temp folder with recipe and dependencies.
if ~exist(archivePath, 'dir')
    mkdir(archivePath);
end
zip(archiveName, tempFolder);

%% Clean up.
rmdir(tempFolder, 's');


%% Is the given file in an ignored folder?
function isIgnore = shouldBeIgnored(filePath, ignorePaths)
isIgnore = false;
for ii = 1:numel(ignorePaths)
    isIgnore = rtbIsPathPrefix(ignorePaths{ii}, filePath);
    if (isIgnore)
        return;
    end
end
