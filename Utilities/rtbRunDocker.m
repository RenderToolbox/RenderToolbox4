function [status, result] = rtbRunDocker(command, imageName, varargin)
%% Run a command in a Docker container with "docker run".
%
% [status, result] = rtbRunDocker(command, imageName)
% executes the given command inside a Docker container with image from the
% given imageName.
%
% rtbRunDocker( ... 'user', user) specify the user who should run inside
% the Docker container.  The default is from the system whoami.
%
% rtbRunDocker( ... 'workingFolder', workingFolder) the working folder to
% use inside the Docker container.  The default is none, don't change
% folder inside the container.
%
% rtbRunDocker( ... 'volumes', volumes) cell array of strings of folder
% paths to mount as volumes inside the container.  Each folder name on the
% host will match the folder name inside the container.
%
% rtbRunDocker( ... 'hints', hints) struct of RenderToolbox4 options, as
% from rtbDefaultHints().
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('command', @ischar);
parser.addRequired('imageName', @ischar);
parser.addParameter('user', getUserId(), @ischar);
parser.addParameter('workingFolder', '', @ischar);
parser.addParameter('volumes', {}, @iscellstr);
parser.addParameter('hints', rtbDefaultHints(), @isstruct);
parser.parse(command, imageName, varargin{:});
command = parser.Results.command;
imageName = parser.Results.imageName;
user = parser.Results.user;
workingFolder = parser.Results.workingFolder;
volumes = parser.Results.volumes;
hints = rtbDefaultHints(parser.Results.hints);

%% Build the command.
dockerCommand = 'docker run -ti --rm';

if ~isempty(user)
    dockerCommand = sprintf('%s --user="%s":"%s"', dockerCommand, user, user);
end

if ~isempty(workingFolder)
    dockerCommand = sprintf('%s --workdir="%s"', dockerCommand, workingFolder);
end

for vv = 1:numel(volumes)
    volume = volumes{vv};
    dockerCommand = sprintf('%s --volume="%s":"%s"', dockerCommand, volume, volume);
end

dockerCommand = sprintf('%s %s %s', dockerCommand, imageName, command);


%% Invoke the Docker command with or without capturing results.
[status, result] = rtbRunCommand(dockerCommand, 'hints', hints);


%% Ask the system for the current user id.
function uid = getUserId()
[~, uid] = system('id -u `whoami`');
uid = strtrim(uid);
