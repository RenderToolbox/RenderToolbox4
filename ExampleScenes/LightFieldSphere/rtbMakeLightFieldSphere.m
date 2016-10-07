%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% This demo was generously contributed by Gizem Kucukoglu in March 2015.
%
% The demo renders a sphere using a light field.  The light probe was
% generously supplied by Bernhard Vogl and downloaded from:
%   http://dativ.at/lightprobes/
%
% Usage notes:
%	- The .dae file needs to have a hemi-light.
%	- The light field needs to be in rectangular format.
%	- The conditions file has various values for alpha parameter. To make
%	the sphere a mirror, set alpha to be very small. But do not set it to
%   zero.
%   .
%
%   Currently this example only works with Mitsuba.
%
%% Render the Light Field Sphere Scene.

%% Choose example files.

parentSceneFile = 'LightFieldSphere.blend';
mappingsFile = 'LightFieldSphereMappings.json';
conditionsFile = 'LightFieldSphereConditions.txt';

%% Choose batch renderer options.
hints.fov = 49.13434 * pi() / 180;
hints.imageWidth = 320;
hints.imageHeight = 240;
hints.recipeName = 'rtbMakeLightFieldSphere';

%% Render with Mitsuba.

% how to convert multi-spectral images to sRGB
toneMapFactor = 100;
isScale = true;

hints.renderer = 'Mitsuba';

nativeSceneFiles = rtbMakeSceneFiles(parentSceneFile, ...
    'conditionsFile', conditionsFile, ...
    'mappingsFile', mappingsFile, ...
    'hints', hints);
radianceDataFiles = rtbBatchRender(nativeSceneFiles, 'hints', hints);

[SRGBMontage, XYZMontage] = ...
    rtbMakeMontage(radianceDataFiles, ...
    'toneMapFactor', toneMapFactor, ...
    'isScale', isScale, ...
    'hints', hints);
rtbShowXYZAndSRGB([], SRGBMontage, sprintf('%s (%s)', hints.recipeName, hints.renderer));

