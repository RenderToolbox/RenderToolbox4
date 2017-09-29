%% rtbPBRTSingleFile(sceneFile,varargin)
%
%  oiParameters
%    for ii=1:length(oiParameters), oiSet(oi,'oiparameters{i})
%
%  For PBRT V2, take a <>.pbrt file as input and produce an OI as output.
%
% TL/BW/AJ Scienstanford 2017

%% Set up the scene.  We need the absolute path.
% sceneFile = '/home/wandell/pbrt-v2-spectral/pbrt-scenes/bunny.pbrt';
% sceneFile = '/home/wandell/pbrt-v2-spectral/pbrt-scenes/bump-sphere.pbrt';
sceneFile = '/home/wandell/pbrt-v2-spectral/pbrt-scenes/sanmiguel.pbrt';

[workingFolder, name,ext] = fileparts(sceneFile);
imageName = [name,ext];

%% Build the docker command
dockerCommand = 'docker run -ti --rm';
dockerImageName = ' vistalab/pbrt-v2-spectral';

outFile = fullfile(workingFolder,[name,'.dat']);
renderCommand = sprintf('pbrt --outfile %s %s', ...
                outFile, ...
                sceneFile);
            
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

%% Convert the dat to an OI
photons = rtbReadDAT(outFile, 'maxPlanes', 31);
[r,c] = size(photons(:,:,1)); depthMap = ones(r,c);

oi = oiCreate;
oi = oiSet(oi,'wave',400:10:700);
oi = oiSet(oi,'photons',photons);
oi = setOIParams(oi,6,2,10);
%
ieAddObject(oi); oiWindow;
%% Set other parameters from somewhere.


%% Ask the system for the current user id.
% function uid = getUserId()
% [~, uid] = system('id -u `whoami`');
% uid = strtrim(uid);
% rtbRunDocker(cmd)
