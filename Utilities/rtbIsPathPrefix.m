function [isPrefix, remainder] = rtbIsPathPrefix(pathA, pathB)
%% Is the first path a prefix (i.e. parent) of the second?
%
% isPrefix = rtbIsPathPrefix(pathA, pathB)
% Checks whether the given pathA is a parent of pathB, or if pathA
% and pathB are equivalent.  If so, pathA can be treated as a prefix
% of pathB.
%
% Only compares leading folder paths, and not file names.  For example, in
% both of the following eamples, pathA is considered a prefix of pathB.
%
%   % folder paths
%   pathA = '/foo/bar/';
%   pathB = '/foo/bar/baz';
%   shouldBeTrue = rtbIsPathPrefix(pathA, pathB);
%
%   % full file paths
%   pathA = '/foo/bar/fileA.txt';
%   pathB = '/foo/bar/baz/fileB.png';
%   alsoShouldBeTrue = rtbIsPathPrefix(pathA, pathB);
%
% If pathA can be considered a prefix of pathB, returns true.  Otherwise
% returns false.  Also returns the remainder of pathB that follows pathA,
% if any.  For example,
%
%   pathA = '/foo/bar/';
%   pathB = '/foo/bar/baz/thing.txt';
%   [isPrefix, remainder] = rtbIsPathPrefix(pathA, pathB);
%   % remainder == 'baz/thing.txt';
%
%   % reproduce pathB
%   pathB = fullfile(pathA, remainder);
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('pathA', @ischar);
parser.addRequired('pathB', @ischar);
parser.parse(pathA, pathB);
pathA = parser.Results.pathA;
pathB = parser.Results.pathB;

isPrefix = false;
remainder = '';

%% Break the paths into tokens, based on the file separator.
tokensA = pathTokens(pathA);
[tokensB, baseB, extB] = pathTokens(pathB);
nA = numel(tokensA);
nB = numel(tokensB);

%% Match up corresponding tokens.
if nA > nB
    % A cannot be a prefix because it's longer than B
    return;
end

nCompare = min(nA, nB);
for ii = 1:nCompare
    % A and B disagree about this parent folder
    if ~strcmp(tokensA{ii}, tokensB{ii})
        return;
    end
end

isPrefix = true;
remainder = fullfile(tokensB{nCompare+1:end}, [baseB, extB]);


%% Break a full path into separate tokens.
function [tokens, base, ext] = pathTokens(path)
[folder, base, ext] = fileparts(path);

if isempty(ext)
    % treat whole thing as a path
    tokens = folderTokens(fullfile(folder, base));
    base = '';
else
    % take off trailing file name
    tokens = folderTokens(fullfile(folder));
end


%% Break a folder path into folder tokens.
function tokens = folderTokens(path)
if isempty(path)
    tokens = {};
    return;
end
scanResult = textscan(path, '%s', 'Delimiter', filesep());
tokens = scanResult{1};
