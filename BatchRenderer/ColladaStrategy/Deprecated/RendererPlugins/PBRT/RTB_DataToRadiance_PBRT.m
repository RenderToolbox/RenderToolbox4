%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Convert PBRT data to units of radiance.
%   @param multispectralImage numeric rendering data from a Render function
%   @param scene description of the scene from an ImportCollada function
%   @param hints struct of RenderToolbox4 options
%
% @details
% This the RenderToolbox4 "DataToRadiance" function for PBRT.
%
% @details
% For more about DataToRadiance functions see
% RTB_DataToRadiance_SampleRenderer().
%
% @details
% Usage:
%   [radianceImage, scaleFactor] = RTB_DataToRadiance_PBRT(multispectralImage, scene, hints)
function [radianceImage, scaleFactor] = RTB_DataToRadiance_PBRT(multispectralImage, scene, hints)

% get the PBRT radiometric scale factor
if ispref('PBRT', 'radiometricScaleFactor')
    scaleFactor = getpref('PBRT', 'radiometricScaleFactor');
else
    scaleFactor = 1;
end

%% Compare pixel reconstruction filter to default.
defaultAdjustments = 'PBRTDefaultAdjustments.xml';
[defaultDoc, defaultIdMap] = ReadSceneDOM(defaultAdjustments);
pbrtXMLFile = rtbWorkingAbsolutePath(scene.pbrtXMLFile, 'hints', hints);
[pbrtDoc, pbrtIdMap] = ReadSceneDOM(pbrtXMLFile);

nodePath = 'filter.type';
sceneFilterType = GetSceneValue(pbrtIdMap, nodePath);
if ~isempty(sceneFilterType)
    defaultFilterType = GetSceneValue(defaultIdMap, nodePath);
    checkSceneParameter('Pixel Filter type', ...
        sceneFilterType, defaultFilterType);
end

nodePath = 'filter:parameter|name=alpha';
sceneAlpha = GetSceneValue(pbrtIdMap, nodePath);
if ~isempty(sceneAlpha)
    defaultAlpha = GetSceneValue(defaultIdMap, nodePath);
    checkSceneParameter('Pixel Filter alpha', sceneAlpha, defaultAlpha);
end

nodePath = 'filter:parameter|name=xwidth';
sceneXWidth = GetSceneValue(pbrtIdMap, nodePath);
if ~isempty(sceneXWidth)
    defaultXWidth = GetSceneValue(defaultIdMap, nodePath);
    factor = StringToVector(defaultXWidth) / StringToVector(sceneXWidth);
    checkSceneParameter('Pixel Filter xwidth', ...
        sceneXWidth, defaultXWidth, factor);
end

nodePath = 'filter:parameter|name=ywidth';
sceneYWidth = GetSceneValue(pbrtIdMap, nodePath);
if ~isempty(sceneYWidth)
    defaultYWidth = GetSceneValue(defaultIdMap, nodePath);
    factor = StringToVector(defaultYWidth) / StringToVector(sceneYWidth);
    checkSceneParameter('Pixel Filter ywidth', ...
        sceneYWidth, defaultYWidth, factor);
end

% TODO: apply non-radiometric scale corrections for filter

%% Compare scene ray sampler to default.
nodePath = 'sampler.type';
sceneSamplerType = GetSceneValue(pbrtIdMap, nodePath);
if ~isempty(sceneSamplerType)
    defaultSamplerType = GetSceneValue(defaultIdMap, nodePath);
    checkSceneParameter('Sampler type', sceneSamplerType, defaultSamplerType);
end

nodePath = 'sampler:parameter|name=pixelsamples';
sceneSamplesPerPixel = GetSceneValue(pbrtIdMap, nodePath);
if ~isempty(sceneSamplesPerPixel)
    defaultSamplesPerPixel = GetSceneValue(defaultIdMap, nodePath);
    factor = StringToVector(defaultSamplesPerPixel) / StringToVector(sceneSamplesPerPixel);
    checkSceneParameter('Sampler samples per pixel', ...
        sceneSamplesPerPixel, defaultSamplesPerPixel, factor);
end

% TODO: apply non-radiometric scale corrections for sampler

%% Scale the rendered data to physical radiance units.
radianceImage = multispectralImage .* scaleFactor;


%% Warn if scene and default properties don't match.
function checkSceneParameter(paramName, sceneValue, defaultValue, scale)

if ~strcmp(sceneValue, defaultValue)
    warningMessage = sprintf('%s (%s) does not match default (%s).', ...
        paramName, sceneValue, defaultValue);
    if nargin >= 4 && ~isempty(scale)
        warningMessage = sprintf('%s\n Radiance data might need to be scaled by a factor of %f.', ...
            warningMessage, scale);
    else
        warningMessage = sprintf('%s\n Radiance data might be incorrectly scaled.', ...
            warningMessage);
    end
    warning('RenderToolbox4:DefaultParamsIncorrectlyScaled',warningMessage);
end