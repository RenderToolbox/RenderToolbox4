%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
%% Render a Ward sphere under point light and orthogonal camera.
%
% This renders a sphere using Matlab code writted from scratch as part of
% Render Toolbox version 2.  It is a sanity check on the "correct" way to
% render a sphere under a point light and orthogonal projection.
%
% Sets sphere rendering parameters and executes rendering according to
% SphereRenderer rendering algorithm, which is implemented all in Matlab.
%
% This script is based on DoMatlabSphereRender.m from Render Toolbox
% version 2, by Dan Lichtman and David Brainard.

%% Check whether the Matalb Sphere Renderer is installed.
checkFile = 'SphereRender_BatchRender.m';
if exist(checkFile, 'file')
    sphereRenderPath = fileparts(which(checkFile));
    fprintf('Using Matlab Sphere Renderer found here: \n  %s\n', ...
        sphereRenderPath);
    
else
    wikiLink = 'https://github.com/DavidBrainard/SphereRendererToolbox/wiki';
    fprintf('Matlab Sphere Renderer not found.  Get it here:\n  %s\n', ...
        wikiLink);
end

%% Create new files in a subfolder next to renderer outputs.
hints.recipeName = 'rtbMakeSimpleSphere';
hints.renderer = 'SphereRenderer';
renderings = GetWorkingFolder('renderings', true, hints);
ChangeToFolder(renderings);

%% Choose rendering and scene parameters.

% spectral sampling
S = [400 10 31];
params.sampleVec = S;
params.numSamples = S(3);

% tone mapping
params.toneMapName = 'cutOff';
params.cutOff.meanMultiplier = 10;
params.toneMapLock = 0;

% view down the z-axis
params.viewPoint = [0 0 1000];

% sphere size -> image size
params.radius = 100;

% glossy Ward sphere with orange Color Checker color
[sphereWls, sphereMags] = ReadSpectrum('mccBabel-2.spd');
params.diffuseConst = SplineSrf(sphereWls, sphereMags, S)';
params.specularConst = 0.07 * ones(1,S(3));
params.specularBlurConst = 0.05 * ones(S(3),1);

% distant point light with daylight spectrum
[lightWls, lightMags] = ReadSpectrum('D65.spd');
params.lightIntensity = SplineSpd(lightWls, lightMags, S);
params.ambientLightIntensity = zeros(size(params.lightIntensity));
params.lightCoords = 1e3 * [1 1 1];
params.numLights = 1;

%% Render the sphere.

% Matlab sphere renderer creates 3 files:
% - sphereRenderer_imageData.mat
% - sphereRenderer_imageRGBtoneMapped.mat
% - sphereRendererimageRGBtoneMapped.jpg
toneMapProfile = render(params);

% save multi-spectral data in RenderToolbox4 format
dataFile = 'SimpleSphere.mat';
sphereData = load('sphereRenderer_imageData.mat');
multispectralImage = sphereData.imageData;
save(dataFile, 'multispectralImage', 'S');
