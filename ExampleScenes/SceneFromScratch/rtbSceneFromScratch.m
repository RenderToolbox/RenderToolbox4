%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Make a scene from scratch!  Use some utilities to build up a well-formed
% mexximp scene struct.  Pass this scene into the RenderToolbox4 pipeline
% for spectral rendering with Mitsuba.
%

%% Generate a scene in Matlab.
clear;
clc;

wallImage = 'stone_wall.exr';
%wallImage = 'brick_wall.jpg';
scene = rtbMakeTestScene('wallImage', wallImage);

%% Export the new scene to Collada so we can sanity check it.
%   ~/render/blender-2.77a-linux-glibc211-x86_64/blender-softwaregl
format = 'collada';
pathHere = fileparts(which('rtbSceneFromScratch'));
colladaFile = fullfile(pathHere, 'rtbSceneFromScratch.dae');
status = mexximpExport(scene, format, colladaFile, []);

%% Choose batch processing options.
hints.imageWidth = 320;
hints.imageHeight = 240;
hints.fov = 60 * pi() / 180;
hints.recipeName = 'rtbSceneFromScratch';
hints.renderer = 'Mitsuba';
hints.batchRenderStrategy = RtbAssimpStrategy(hints);

%% Convert to Mitsuba scene file as-is.
nativeSceneFiles = rtbMakeSceneFiles(colladaFile, ...
    'hints', hints);

%% Use JSON mappings to specify light and reflectance spectra.
mappings{1}.name = 'yellowLight';
mappings{1}.broadType = 'lights';
mappings{1}.specificType = 'spot';
mappings{1}.operation = 'update';
mappings{1}.properties(1).name = 'intensity';
mappings{1}.properties(1).valueType = 'spectrum';
mappings{1}.properties(1).value = 'D65.spd';

mappings{2}.name = 'redLight';
mappings{2}.broadType = 'lights';
mappings{2}.specificType = 'spot';
mappings{2}.operation = 'update';
mappings{2}.properties(1).name = 'intensity';
mappings{2}.properties(1).valueType = 'spectrum';
mappings{2}.properties(1).value = 'D65.spd';

mappings{3}.name = 'greenLight';
mappings{3}.broadType = 'lights';
mappings{3}.specificType = 'spot';
mappings{3}.operation = 'update';
mappings{3}.properties(1).name = 'intensity';
mappings{3}.properties(1).valueType = 'spectrum';
mappings{3}.properties(1).value = 'D65.spd';

mappings{4}.name = 'distantLight';
mappings{4}.broadType = 'lights';
mappings{4}.specificType = 'directional';
mappings{4}.operation = 'update';
mappings{4}.properties(1).name = 'intensity';
mappings{4}.properties(1).valueType = 'spectrum';
mappings{4}.properties(1).value = '300:0.01 800:0.01';

mappings{5}.name = 'whiteShiny';
mappings{5}.broadType = 'materials';
mappings{5}.specificType = 'matte';
mappings{5}.operation = 'update';
mappings{5}.properties(1).name = 'diffuseReflectance';
mappings{5}.properties(1).valueType = 'spectrum';
mappings{5}.properties(1).value = 'mccBabel-14.spd';

% save a JSON mappings file
mappingsFile = fullfile(pathHere, 'rtbScratchMappings.json');
rtbWriteJson('', mappings, ...
    'FileName', mappingsFile, ...
    'ArrayIndent', 1, ...
    'ArrayToStrut', 0);

% make scene files
nativeSceneFiles = rtbMakeSceneFiles(scene, ...
    'hints', hints, ...
    'mappingsFile', mappingsFile);

%% Render with Mitsuba.
radianceDataFiles = rtbBatchRender(nativeSceneFiles, 'hints', hints);

%% Convert to sRGB for viewing.
toneMapFactor = 100;
isScale = true;

montageName = sprintf('rtbSceneFromScratch (%s)', hints.renderer);
montageFile = [montageName '.png'];
sRgb = rtbMakeMontage(radianceDataFiles, ...
    'outFile', montageFile, ...
    'toneMapFactor', toneMapFactor, ...
    'isScale', isScale, ...
    'hints', hints);
rtbShowXYZAndSRGB([], sRgb, montageName);
