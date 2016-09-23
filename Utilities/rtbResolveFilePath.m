function fileInfo = rtbResolveFilePath(fileName, rootFolder)
%% Resolve a path to the given file.
%
% fileInfo = rtbResolveFilePath(fileName, rootFolder)
%
% Searches for the given fileName, which might be a plain file name, or
% a relative or absolute path to a file.  First searches within the given
% rootFolder and its subfolders for a file that matches fileName.  If no
% match is found within rootFolder, searches for a matching file on the
% Matlab path.
%
% Returns a struct of info about the given fileName, with the following
% fields:
%   - verbatimName - fileName exactly as given
%   - rootFolder - rootFolder exactly as given
%   - isRootFolderMatch - true only if fileName was found within rootFolder
%   - resolvedPath - unambiguous path to the given fileName
%   - absolutePath - full absolute path to the given fileName, if found
%
% resolvedPath will be an unambiguous path to the first file that
% matches fileName.   If the match was found within rootFolder,
% resolvedPath is the relative path to the matched file, starting from
% rootFolder.  If the match was found on the Matlab path, but not in
% rootFolder, resolvedPath is the full absolute path to the matched
% file.  If no match was found, resolvedPath is the empty string ''.
%
% In all cases isRootFolderMatch indicates whether or not a match was
% found within rootFolder.  When isRootFolderMatch is true, resolvedPath
% should be treated as a relative path.
%
%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

parser = inputParser();
parser.addRequired('fileName', @ischar);
parser.addRequired('rootFolder', @ischar);
parser.parse(fileName, rootFolder);
fileName = parser.Results.fileName;
rootFolder = parser.Results.rootFolder;

blank = {[]};
fileInfo = struct( ...
    'verbatimName', blank, ...
    'rootFolder', blank, ...
    'isRootFolderMatch', blank, ...
    'resolvedPath', blank, ...
    'absolutePath', blank);

% basic info as given
fileInfo(1).verbatimName = fileName;
fileInfo(1).rootFolder = rootFolder;

% given a path relative to workingFolder?
rootRelative = fullfile(rootFolder, fileName);
if exist(rootRelative, 'file')
    fileInfo(1).absolutePath = rootRelative;
    [fileInfo(1).isRootFolderMatch, fileInfo(1).resolvedPath] = ...
        checkRootPath(rootRelative, rootFolder);
    return;
end

% given a plain file within workingFolder?
if 7 == exist(rootFolder, 'dir')
    matches = rtbFindFiles('root', rootFolder, ...
        'filter', fileName, ...
        'exactMatch', true);
    if ~isempty(matches)
        fileInfo(1).absolutePath = matches{1};
        [fileInfo(1).isRootFolderMatch, fileInfo(1).resolvedPath] = ...
            checkRootPath(matches{1}, rootFolder);
        return;
    end
end

% given a path relative to pwd()?
pwdRelative = fullfile(pwd(), fileName);
if exist(pwdRelative, 'file')
    fileInfo(1).absolutePath = pwdRelative;
    [fileInfo(1).isRootFolderMatch, fileInfo(1).resolvedPath] = ...
        checkRootPath(pwdRelative, rootFolder);
    return;
end

% given an absolute path or a plain file on the Matlab path?
whichFile = which(fileName);
if ~isempty(whichFile)
    fileInfo(1).absolutePath = whichFile;
    [fileInfo(1).isRootFolderMatch, fileInfo(1).resolvedPath] = ...
        checkRootPath(whichFile, rootFolder);
    return;
end

% file doesn't seem to exist, but try to resolve it based on syntax alone
[matchesRoot, resolvedPath] = checkRootPath(fileName, rootFolder);
if matchesRoot
    fileInfo(1).absolutePath = fullfile(rootFolder, fileName);
    fileInfo(1).isRootFolderMatch = true;
    fileInfo(1).resolvedPath = resolvedPath;
else
    fileInfo(1).absolutePath = '';
    fileInfo(1).isRootFolderMatch = false;
    fileInfo(1).resolvedPath = '';
end


%% Get relative path from rootFolder, if any.
function [isPrefix, resolvedPath] = checkRootPath(path, rootFolder)
[isPrefix, relativePath] = rtbIsPathPrefix(rootFolder, path);
if isPrefix
    resolvedPath = relativePath;
else
    resolvedPath = path;
end
