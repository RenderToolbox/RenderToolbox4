%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Move some environment path entries to the end of the path.
%   @param variable name of an environment variable that contains a path
%   @param matching regular expression to match path entries
%
% @details
% @a variable should be the name of an environment variable that contains a
% path, such as "PATH" or "LD_LIBRARY_PATH".  Modifies the value of the
% named @a variable so that path entries matching  the given @a matching
% regular expression appear last.  @a variable is acceessed with Matlab's
% built-in getenv() function and modified with the built-in setenv()
% function.
%
% @details
% Returns the new value for the named path @a variable, sorted so that
% path entires that match the given @a matching expression appear last.
% Also returns the original value for the named @a variable.
%
% @details
% Usage:
%   [sortedPath, originalPath] = DemoteEnvPathEntries(variable, matching)
%
% @details
% Example usage:
% @code
% % put "matlab" entries last for the OS X "DYLD_LIBRARY_PATH"
% variable = 'DYLD_LIBRARY_PATH';
% matching = 'matlab|MATLAB';
% [sortedPath, originalPath] = DemoteEnvPathEntries(variable, matching);
%
% % restore the original library path
% setenv(variable, originalPath);
% @endcode
%
% @ingroup Utilities
function [sortedPath, originalPath] = DemoteEnvPathEntries(variable, matching)

sortedPath = '';
originalPath = '';

% get the original environment path variable
originalPath = getenv(variable);
if isempty(originalPath)
    return;
end

% break the path into separate entries
envPathParts = textscan(originalPath, '%s', 'Delimiter', pathsep());
nPathParts = length(envPathParts{1});
if nPathParts < 2
    return;
end

% check which path parts match the given expression
isMatch = false(1, nPathParts);
for ii = 1:nPathParts
    isMatch(ii) = ~isempty(regexp(envPathParts{1}{ii}, matching, 'once'));
end

% make a new path with matching parts last
matchedParts = envPathParts{1}(isMatch);
unmatchedParts = envPathParts{1}(~isMatch);
sortedPathParts = cat(1, unmatchedParts, matchedParts);
sortedPath = sprintf(['%s' pathsep()], sortedPathParts{:});

% apply the new path
setenv(variable, sortedPath);