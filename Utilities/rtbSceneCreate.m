function scene = rtbSceneCreate(photons,varargin)
% Create a scene from radiance data
%
%    scene = rtbSceneCreate(photons,varargin)
%
% Required
%    photons - row x col x nwave data, computed by PBRT usually
%
% Key/values
%    fov         - horizontal field of view (deg)
%
% Return
%  An ISET scene structure
%
% Example:
%{
   sceneFile = '/home/wandell/pbrt-v2-spectral/pbrt-scenes/bunny.dat';
   photons = rtbReadDAT(outFile, 'maxPlanes', 31);
   scene = rtbSceneCreate(photons);
   ieAddObject(scene); sceneWindow;
%}
% BW, SCIENTSTANFORD, 2017

%% When the PBRT uses a pinhole, we treat the radiance data as a scene

p = inputParser;
p.addRequired('photons',@isnumeric);
p.addParameter('fov',40,@isscalar)               % Horizontal fov, degrees

p.parse(photons,varargin{:});

%% Sometimes ISET is not initiated.  We need at least this for the scene stuff

global vcSESSION
if ~isfield(vcSESSION,'SCENE')
    vcSESSION.SCENE = {};
end

%% Set the photons into the scene

scene = sceneCreate;
scene = sceneSet(scene,'photons',photons);
[r,c] = size(photons(:,:,1)); depthMap = ones(r,c);

scene = sceneSet(scene,'depth map',depthMap);

scene = sceneSet(scene,'fov',p.Results.fov);

% ieAddObject(scene); sceneWindow;

end