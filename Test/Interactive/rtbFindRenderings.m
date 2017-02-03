function renderings = rtbFindRenderings(rootFolder, varargin)
%% Locate rendering data files in the given folder.
%
% renderings = rtbFindRenderings(rootFolder) scans the given rootFolder
% recursively for rendering data files.  Returns a struct array of
% rendering records, one for each data file found.
%
% rtbFindRenderings( ... 'filter', filter) uses the given regular
% expression to filter the results.  Only data files whose full paths match
% the expression will be compared.  The default is '\.mat$', look for any
% .mat files.
%
% rtbFindRenderings( ... 'renderingsFolderName', renderingsFolderName) uses
% the given renderingsFolderName to locate renderings withing various
% subfolders of the given rootFolder.  The default is "renderings", which
% is conisitent with the conventions established by rtbWorkingFolder() and
% rtbBatchRender().
%
% Typical subfolders of rootFolder would look like these:
%   rootFolder/rtbMakeMaterialSphereBumps/renderings/Mitsuba/materialSphereMetal.mat
%   rootFolder/rtbMakeCoordinatesTest/renderings/PBRT/scene-003.mat
%
% These paths are parsed, starting with the renderingsFolderName, in this
% case "renderings".  The folder above "renderings" is treated as the name
% of the example or recipe that produced the rendering.  The folder below
% "renderings" is treated as the name of the renderer.  The file name is
% scanned for either a name, like "materialSphereMetal", or a sequence
% number, like 3.
%
%%% RenderToolbox4 Copyright (c) 2012-2017 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('rootFolder', @ischar);
parser.addParameter('filter', '\.mat$', @ischar);
parser.addParameter('renderingsFolderName', 'renderings', @ischar);
parser.parse(rootFolder, varargin{:});
rootFolder = parser.Results.rootFolder;
filter = parser.Results.filter;
renderingsFolderName = parser.Results.renderingsFolderName;

files = rtbFindFiles('root', rootFolder, 'filter', filter);
nFiles = numel(files);
renderingsCell = cell(1, nFiles);
for ff = 1:nFiles
    fileName = files{ff};
    
    % break off the file name
    [parentPath, imageName] = fileparts(fileName);
    if numel(imageName) > 3
        imageNumber = sscanf(imageName(end-3:end), '-%d');
    end
    
    % look for the renderingsFolderName, like "renderings"
    scanResult = textscan(parentPath, '%s', 'Delimiter', filesep());
    pathParts = scanResult{1};
    nPathParts = numel(pathParts);
    isRenderingsFolder = strcmp(pathParts, renderingsFolderName);
    if ~any(isRenderingsFolder)
        continue;
    end
    renderingsFolderIndex = find(isRenderingsFolder, 1, 'last');
    
    % recipe name comes just before renderingsFolderName
    recipeName = pathParts{renderingsFolderIndex - 1};
    
    % renderer name comes just after renderingsFolderName, if any
    if nPathParts > renderingsFolderIndex
        rendererName = pathParts{renderingsFolderIndex + 1};
    else
        rendererName = '';
    end
    
    renderingsCell{ff} = rtbRenderingRecord( ...
        'recipeName', recipeName, ...
        'rendererName', rendererName, ...
        'imageNumber', imageNumber, ...
        'imageName', imageName, ...
        'fileName', files{ff});
end
renderings = [renderingsCell{:}];
