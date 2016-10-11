function [outName, isLocated, info] = rtbResourcePath(inName, varargin)
%% Build a reference to a resource file mentioned in a scene.
%
% The idea here is to resolve file references and clean up those
% reference so that they point to existing local files.  This is
% useful because "wild" scenes from the web often contain:
%   - renferences to non-existent files
%   - absolute file paths from another computer
%   - truncated file names
%   - file names with the wrong CASE
%   - file names with non-ASCII characters
%   - etc.
% These are all a pain in the neck, but many of these can be resolved
% automatically.
%
% [outName, info] = rtbResourcePath(inName) attempts to do fuzzy
% matching between the given fileName and the files found in pwd().
% When a match is found, the fileName will be updated.
%
% rtbResourcePath( ... 'strictMatching', strictMatching) whether to perform
% exact file name matching (true) or fuzzy matching, which is more
% permissive and less accurate (false).  The default is false, do
% permissive fuzzy matching.
%
% rtbResourcePath( ... 'resourceFolder', resourceFolder) specifies
% a folder to search for local existing files.  The default is pwd().
%
% rtbResourcePath( ... 'writeFullPaths', writeFullPaths) choose
% whether to update the given fileName with a full absolute paths (true),
% or to write just file names without any leading path (false).  The
% default is true, write full, absolute paths.
%
% rtbResourcePath( ... 'relativePath', relativePath) specify
% a prefix to add to updated file name, when writeFullPaths is false.
% This is useful in case the located resource file is in a subfolder
% relative to a scene file.  The default is '', don't prepend any relative
% path.
%
% rtbResourcePath( ... 'toReplace', toReplace)
% specifies a string containing characters to be replaced in resource file
% names.  When found, these characters will be replaced with "_"
% underscores.  This is useful to prevent Assimp from transcoding non-ASCII
% characters.  For example, Assimp transcodes "-" as "%2d", which is good
% for UTF-8, but breaks some downstream programs like PBRT and Mitsuba.
% The default is '-:', replace hyphens and colons with underscores.
%
% rtbResourcePath( ... 'copyOnReplace', copyOnReplace) choose
% whether to copy files when their names contain replaced characters (true)
% or not (false).  This is useful so that renamed resources will point to
% existing files.  The default is true, make new copies or resource files
% as their names are replaced.
%
% rtbResourcePath( ... 'useMatlabPath', useMatlabPath) specifies whether
% to search the Matlab path for resource files, after searching the given
% resourceFolder.  The default is true, do search the Matlab path.
%
% Returns the given fileName, with modifications.  Also returns a logical
% flag, true when the resource was located.  Also returns a struct
% of information about what happened.
%
% [outName, isLocated, info] = rtbResourcePath(inName, varargin)
%
% Copyright (c) 2016 mexximp Teame

parser = inputParser();
parser.addRequired('inName', @ischar);
parser.addParameter('strictMatching', false, @islogical);
parser.addParameter('resourceFolder', pwd(), @ischar);
parser.addParameter('writeFullPaths', true, @islogical);
parser.addParameter('relativePath', '', @ischar);
parser.addParameter('toReplace', '-:', @ischar);
parser.addParameter('copyOnReplace', true, @islogical);
parser.addParameter('useMatlabPath', true, @islogical);
parser.parse(inName, varargin{:});
inName = parser.Results.inName;
strictMatching = parser.Results.strictMatching;
resourceFolder = parser.Results.resourceFolder;
writeFullPaths = parser.Results.writeFullPaths;
relativePath = parser.Results.relativePath;
toReplace = parser.Results.toReplace;
copyOnReplace = parser.Results.copyOnReplace;
useMatlabPath = parser.Results.useMatlabPath;

if strictMatching
    matchFunction = @strictMatch;
else
    matchFunction = @fuzzyMatch;
end

isLocated = false;


%% Collect files in the resourceFolder.
resourceDir = dir(resourceFolder);
isDir = [resourceDir.isdir];
resources = {resourceDir(~isDir).name};


%% Try to find a the file in the given resources folder or Matlab path.
resourceMatch = matchResource(inName, resources, matchFunction);
if isempty(resourceMatch) && useMatlabPath && 2 == exist(inName, 'file')
    % copy into resources folder and proceed like it was always there
    fullPathName = which(inName);
    resourceCopy = fullfile(resourceFolder, inName);
    copyfile(fullPathName, resourceCopy, 'f');
    resourceMatch = inName;
end


%% Did we find it?
if isempty(resourceMatch)
    % report an unmatched file
    info.verbatimName = inName;
    info.writtenName = inName;
    info.isMatched = false;
    info.matchName = '';
    info.matchFullPath = '';
    outName = inName;
    return;
end


%% Replace unwanted characters in the file name.
newName = replaceCharacters(resourceMatch, toReplace);
if copyOnReplace && ~isempty(newName)
    source = fullfile(resourceFolder, resourceMatch);
    destination = fullfile(resourceFolder, newName);
    copyfile(source, destination, 'f');
    resourceMatch = newName;
end


%% Choose a new file name.
isLocated = true;
resourceFullPath = fullfile(resourceFolder, resourceMatch);
resourceRelativePath = fullfile(relativePath, resourceMatch);
if writeFullPaths
    outName = resourceFullPath;
else
    outName = resourceRelativePath;
end


%% Report a successful update.
info.verbatimName = inName;
info.writtenName = outName;
info.isMatched = true;
info.matchName = resourceMatch;
info.matchFullPath = resourceFullPath;


%% Find unwanted characters and replace with underscores.
function newName = replaceCharacters(name, toReplace)
newName = '';
needsReplacement = false(1, numel(name));
for ii = 1:numel(toReplace)
    needsReplacement = needsReplacement | toReplace(ii) == name;
end
if any(needsReplacement)
    newName = name;
    newName(needsReplacement) = '_';
end


%% Iterate resources and try to match against a given file.
function resourceMatch = matchResource(fileName, resources, matchFunction)
resourceMatch = '';
nResources = numel(resources);
for ii = 1:nResources
    resource = resources{ii};
    if feval(matchFunction, fileName, resource)
        resourceMatch = resource;
        return;
    end
end


%% Fuzzy matching for file names: is b probably a good substitute for a?
%   case insensitive
%   4851-nor.jpg matches 4851-normal.jpg
%   C:\foo\bar\baz.jpg matches baz.jpg
function isMatch = fuzzyMatch(a, b)
a = lower(a);
b = lower(b);

[~, aBase, aExt] = fileparts(a);
[~, bBase, bExt] = fileparts(b);

% one extension is a substring of the other,
%   and the base names match
isMatch = (~isempty(strfind(aExt, bExt)) || ~isempty(strfind(bExt, aExt))) ...
    && (~isempty(strfind(aBase, bBase)) || ~isempty(strfind(bBase, aBase)));


%% Strict matching for file names: b is the same as a, within reason.
%   case insensitive
%   4851-nor.jpg does not match 4851-normal.jpg
%   C:\foo\bar\baz.jpg matches baz.jpg
function isMatch = strictMatch(a, b)
a = lower(a);
b = lower(b);

[~, aBase, aExt] = fileparts(a);
[~, bBase, bExt] = fileparts(b);

isMatch = strcmp(aBase, bBase) && strcmp(aExt, bExt);
