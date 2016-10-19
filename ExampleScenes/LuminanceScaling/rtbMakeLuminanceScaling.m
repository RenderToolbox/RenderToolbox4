%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team{1}.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
%% Render the LuminanceScaling scene.
clear;

%% Choose example file.
parentSceneFile = 'LuminanceScaling.blend';

%% Choose batch renderer options.
hints.imageWidth = 320;
hints.imageHeight = 240;
hints.fov = deg2rad(36);
hints.recipeName = 'rtbMakeLuminanceScaling';
hints.renderer = 'Mitsuba';

recipeFolder = rtbWorkingFolder('hints', hints);


%% Mappings to turn spheres into area lights.
m{1}.broadType = 'meshes';
m{1}.name = 'LeftSphere';
m{1}.operation = 'blessAsAreaLight';
m{1}.properties = rtbMappingProperty( ...
    'name', 'intensity', ...
    'valueType', 'spectrum', ...
    'value', '300:0 800:(intensity)');

m{2}.broadType = 'meshes';
m{2}.name = 'RightSphere';
m{2}.operation = 'blessAsAreaLight';
m{2}.properties = rtbMappingProperty( ...
    'name', 'intensity', ...
    'valueType', 'spectrum', ...
    'value', '300:100 800:0');

m{3}.broadType = 'materials';
m{3}.specificType = 'matte';
m{3}.name = 'Backdrop';
m{3}.operation = 'update';
m{3}.properties = rtbMappingProperty( ...
    'name', 'diffuseReflectance', ...
    'valueType', 'spectrum', ...
    'value', 'mccBabel-1.spd');

mappingsFile = fullfile(recipeFolder, 'LuminanceScalingMappings.json');
rtbWriteJson(m, 'fileName', mappingsFile);


%% Conditions to vary the intensity of one light.
names = {'intensity'};
intensities = {1, 10, 100, 1000}';
conditionsFile = fullfile(recipeFolder, 'LuminanceScalingConditions.txt');
rtbWriteConditionsFile(conditionsFile, names, intensities);


%% Render.
nativeSceneFiles = rtbMakeSceneFiles(parentSceneFile, ...
    'mappingsFile', mappingsFile, ...
    'conditionsFile', conditionsFile, ...
    'hints', hints);
radianceDataFiles = rtbBatchRender(nativeSceneFiles, 'hints', hints);


%% Choose scaling and tone mapping based on the last rendering.
calibrationRendering = load(radianceDataFiles{end});

% convert to sRGB with scaling by max luminance
% obtain the XYZ image and scaling facotr used internally
[~, XYZImage, ~, scaleFactor] = rtbMultispectralToSRGB( ...
    calibrationRendering.multispectralImage, ...
    calibrationRendering.S, ...
    'isScale', true);

% choose a tone mapping threshold from the returned XYZ image
luminance = XYZImage(:,:,2);
toneMapThreshold = 100 * mean(luminance(:));


%% Convert each rendering to sRGB with constant scaling and tone mapping.
nRenderings = numel(radianceDataFiles);
nRows = 2;
nColumns = ceil(nRenderings / nRows);
for rr = 1:nRenderings
    rendering = load(radianceDataFiles{rr});
    
    sRGBImage = rtbMultispectralToSRGB( ...
        rendering.multispectralImage, ...
        rendering.S, ...
        'scaleFactor', scaleFactor, ...
        'toneMapThreshold', toneMapThreshold);
    
    subplot(nRows, nColumns, rr);
    imshow(uint8(sRGBImage));
    title(sprintf('left %d, right 100', intensities{rr}))
end
