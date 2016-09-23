function userFolder = rtbGetUserFolder()
%% Locate the user's writable "MATLAB" folder.
%
% userFolder = rtbGetUserFolder() Uses the built-in userpath() to find the
% user's "MATLAB" folder.  This folder is usually located in a
% "Documents" folder inside a user's home folder.  This is usually a
% location where Matlab will have permission to write files.
%
% Users can change their path configuration using userpath().  If for some
% reason userpath() does not return a valid location, returns ''.
%
%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

% get the user's folder from Matlab
userFolder = userpath();

% want a regular path, not a "path string" with colon delimiters
colon = find(pathsep() == userFolder, 1, 'first');
if ~isempty(colon)
    userFolder = userFolder(1:colon-1);
end

% user folder root should not be empty for RenderToolbox4
if isempty(userFolder)
    warning('RenderToolbox4:EmptyUserFolder', ...
        ['Your Matlab user folder is empty!  ' ...
        'Please set one with the userpath() function.']);
end

% can we write into this folder?
[~, info] = fileattrib(userFolder);
if ~info.UserWrite
    warning('User does not have write permission for %s.', userFolder);
    userFolder = '';
end
