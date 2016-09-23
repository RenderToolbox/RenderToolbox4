function fileList = rtbFindFiles(varargin)
% Locate files by recursively searching a folder and subfolders.
%
% fileList = rtbFindFiles() searches the current folder (pwd()) for files and
% returns a cell array of files found.  Excludes files that start with '.',
% or end with '~' or '.asv'.
%
% fileList = rtbFindFiles( ... 'root',  root) searches the given rood folder
% instead of pwd().
%
% fileList = rtbFindFiles( ... 'filter', filter) uses the given filter regular
% expression to filter out files.  The regular expression is applied to the
% full, absolute path of each file encountered.  Only files that match the
% regular expression are returned.
%
% fileList = rtbFindFiles( ... 'exactMatch', exactMatch) specify whether the
% given filter should be treated as an exact pattern to match with literal
% string comparison (true), or treated as a regular expression (false).
% The default is false, treat filder as a regular expression.
%
% fileList = rtbFindFiles( ... 'allowFolders', allowFolders) specify whether
% to return only file names (false), or to reutrn a mix of file and folder
% names (true).  The default is false, only return file names.
%
% Returns a cell array of strings which are the full, absolute path names
% of files that were found and matched.
%
% fileList = rtbFindFiles(varargin)
%
%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

parser = inputParser();
parser.addParameter('root', pwd(), @ischar);
parser.addParameter('filter', '', @ischar);
parser.addParameter('exactMatch', false, @islogical);
parser.addParameter('allowFolders', false, @islogical);
parser.parse(varargin{:});
root = parser.Results.root;
filter = parser.Results.filter;
exactMatch = parser.Results.exactMatch;
allowFolders = parser.Results.allowFolders;

%% Convert the root folder to an absolute path.

if 7 ~= exist(root, 'dir')
    fileList = {};
    return;
end

% oddly enough, pwd() doesn't always exist
initalFolder = pwd();
if exist(initalFolder, 'dir')
    cd(root)
    root = pwd();
    cd(initalFolder);
end

%% Find all files in the present folder.
d = dir(root);
isSubfolder = [d.isdir];
files = {d(~isSubfolder).name};
subfolders = {d(isSubfolder).name};

nFiles = numel(files);
fileList = cell(1, nFiles);
isMatch = false(1, nFiles);
for ii = 1:nFiles
    f = files{ii};
    if ~isempty(f) ...
            && f(1) ~= '.' ...
            && f(end) ~= '~' ...
            && isempty(regexpi(f, '.*\.asv'))
        
        absPathFile = fullfile(root, f);
        if checkMatch(absPathFile, filter, exactMatch)
            fileList{ii} = absPathFile;
            isMatch(ii) = true;
        end
    end
end
fileList = fileList(isMatch);

%% Include the present folder itself?
if allowFolders && checkMatch(root, filter, exactMatch)
    fileList = cat(2, {root}, fileList);
end

%% Descend recursively into subfolders.
for ii = 1:numel(subfolders)
    sf = subfolders{ii};
    if ~isempty(sf) && ~any(sf=='.')
        absSubfolder = fullfile(root, sf);
        fileList = cat(2, fileList, ...
            rtbFindFiles('root', absSubfolder, ...
            'filter', filter, ...
            'allowFolders', allowFolders, ...
            'exactMatch', exactMatch));
    end
end

%% Check a file name against a filter pattern.
function isMatch = checkMatch(filePath, filter, exactMatch)
if exactMatch
    [~, baseName, extension] = fileparts(filePath);
    isMatch = strcmp(filter, [baseName, extension]) ...
        || strcmp(filter, filePath);
else
    isMatch = isempty(filter) || ~isempty(regexp(filePath, filter, 'once'));
end
