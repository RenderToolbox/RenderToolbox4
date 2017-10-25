function [ieObject, outFile] = rtbPBRTSingleFile(sceneFile,varargin)
% Read a PBRT V2 scene file, run the docker cmd locally, return the oi.
%
%    [oi or scene] = rtbPBRTSingleFile(sceneFile,varargin)
%
% Examples:
%  Scene files are in pbrt-v2-spectral on wandell's home account.
%
%   sceneFile = '/home/wandell/pbrt-v2-spectral/pbrt-scenes/bunny.pbrt';
%   sceneFile = '/home/wandell/pbrt-v2-spectral/pbrt-scenes/bump-sphere.pbrt';
%   sceneFile = '/home/wandell/pbrt-v2-spectral/pbrt-scenes/rtbSanmiguel.pbrt';
%   sceneFile = '/home/wandell/pbrt-v2-spectral/pbrt-scenes/rtbTeapot-metal.pbrt';
%   sceneFile = '/home/wandell/pbrt-v2-spectral/pbrt-scenes/rtbVilla-daylight.pbrt';
%
% Example code
%{
   % Example 1 - run the docker container
   sceneFile = '/home/wandell/pbrt-v2-spectral/pbrt-scenes/rtbVilla-daylight.pbrt';
   [scene, outFile] = rtbPBRTSingleFile(sceneFile,'opticsType','pinhole');
   ieAddObject(scene); sceneWindow;

   % Example 2 - read the radiance file into an ieObject
   % We are pretending in this case that it was created with a lens
   radianceFile = '/home/wandell/pbrt-v2-spectral/pbrt-scenes/bunny.dat';
   photons = rtbReadDAT(radianceFile, 'maxPlanes', 31);
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

%%  Name of the pbrt scene file and whether we use a pinhole or lens model

p = inputParser;
p.addRequired('sceneFile',@(x)(exist(x,'file')));
p.addParameter('opticsType','pinhole',@ischar);

p.parse(sceneFile,varargin{:});
opticsType = p.Results.opticsType;

%% Set up the working folder.  We need the absolute path.

[workingFolder, name, ~] = fileparts(sceneFile);
if(isempty(workingFolder))
    error('We need an absolute path for the working folder.');
end


%% Build the docker command
dockerCommand   = 'docker run -ti --rm';
dockerImageName = 'vistalab/pbrt-v2-spectral';

outName = [name,'.dat'];
outFile = fullfile(workingFolder,outName);
renderCommand = sprintf('pbrt --outfile %s %s', ...
    outFile, sceneFile);
            
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

%% Invoke the Docker command with or without capturing results.
tic
[status, result] = rtbRunCommand(cmd);
toc

%% Check the return

if status
    warning('Docker did not run correctly');
    disp(result)
    pause;
else
    fprintf('Docker run status %d, seems OK.\n',status);
    fprintf('Outfile file was set to %s.\n',outFile);
end

%% Convert the radiance dat to an ieObject
%
% params.opticsType = 'pinhole;
% ieObject = rtbDAT2ISET(outFile,params)
if ~exist(outFile,'file')
    error('No output file %s\n',outFile);
end

photons = rtbReadDAT(outFile, 'maxPlanes', 31);

switch opticsType
    case 'lens'
        % If we used a lens, then the ieObject should be the optical image
        % (irradiance data).
        %
        % You can set fov or filmDiag here.  You can also set fNumber and focalLength
        % here.  We are using defaults for now, but we will find those numbers in
        % the future from inside the radiance.dat file and put them in here.
        ieObject = rtbOICreate(photons);
        ieObject = oiSet(ieObject,'name',outName);
    case 'pinhole'
        % In this case, we the radiance really describe the scene, not an oi
        ieObject = rtbSceneCreate(photons,'mean luminance',100);
        ieObject = sceneSet(ieObject,'name',outName);
        % ieAddObject(ieObject); sceneWindow;

end

end

%% Ask the system for the current user id.
% function uid = getUserId()
% [~, uid] = system('id -u `whoami`');
% uid = strtrim(uid);
% rtbRunDocker(cmd)
