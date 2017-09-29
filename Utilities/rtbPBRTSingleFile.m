function [oi, outFile] = rtbPBRTSingleFile(sceneFile,varargin)
% Read a PBRT V2 scene file, run the docker cmd, return the oi.
%
%    oi = rtbPBRTSingleFile(sceneFile,varargin)
%
% Examples:
%  Scene files are in pbrt-v2-spectral on wandell's home account.
%
%   sceneFile = '/home/wandell/pbrt-v2-spectral/pbrt-scenes/bunny.pbrt';
%   sceneFile = '/home/wandell/pbrt-v2-spectral/pbrt-scenes/bump-sphere.pbrt';
%   sceneFile = '/home/wandell/pbrt-v2-spectral/pbrt-scenes/sanmiguel_cam3.pbrt';
%
%{
   % Example 1 - run the docker container
   sceneFile = '/home/wandell/pbrt-v2-spectral/pbrt-scenes/bunny.pbrt';
   [oi, outFile] = rtbPBRTSingleFile(sceneFile);
   ieAddObject(oi); oiWindow;

   % Try just reading from previously written radiance file
   photons = rtbReadDAT(outFile, 'maxPlanes', 31);
   oi = rtbOICreate(photons);
   ieAddObject(oi); oiWindow;
%}
% TL/BW/AJ Scienstanford 2017
%
%% PROGRAMMING TODO
%
%  We should write a routine to append the required text for a Realistic Camera
%  and then run with a lens file
%
%  Should have an option to create the depth map
%

%%
p = inputParser;
p.addRequired('sceneFile');

%% Set up the scene.  We need the absolute path.
[workingFolder, name, ~] = fileparts(sceneFile);

%% Build the docker command
dockerCommand   = 'docker run -ti --rm';
dockerImageName = ' vistalab/pbrt-v2-spectral';

outFile = fullfile(workingFolder,[name,'.dat']);
renderCommand = sprintf('pbrt --outfile %s %s', ...
                outFile, ...
                sceneFile);
    
% Not sure why this is not needed here, or it is needed in RtbPBRTRenderer.
% if ~isempty(user)
%     dockerCommand = sprintf('%s --user="%s":"%s"', dockerCommand, user, user);
% end

if ~isempty(workingFolder)
    if ~exist(workingFolder,'dir'), error('Need full path to %s\n',workingFolder); end
    dockerCommand = sprintf('%s --workdir="%s"', dockerCommand, workingFolder);
end

dockerCommand = sprintf('%s --volume="%s":"%s"', dockerCommand, workingFolder, workingFolder);

cmd = sprintf('%s %s %s', dockerCommand, dockerImageName, renderCommand);

% Do we need quotes around the strings?

%% Invoke the Docker command with or without capturing results.
[status, result] = rtbRunCommand(cmd);
if status
    disp(result)
    pause;
end

%% Convert the dat to an OI
photons = rtbReadDAT(outFile, 'maxPlanes', 31);

% Be nice if there were a real depth map.  Maybe create one with a flag.
% [r,c] = size(photons(:,:,1)); depthMap = ones(r,c);

% You can set fov or filmDiag here.  You can also set fNumber and focalLength
% here
oi = rtbOICreate(photons);

end

%% Ask the system for the current user id.
% function uid = getUserId()
% [~, uid] = system('id -u `whoami`');
% uid = strtrim(uid);
% rtbRunDocker(cmd)
