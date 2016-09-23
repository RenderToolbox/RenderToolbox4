function [promoted, S, RGB, dataFile] = rtbPromoteRGBReflectance(reflectance, varargin)
%% Promote an RGB reflectance to a full spectrum, using a renderer.
%
% [promoted, S, RGB, dataFile] = rtbPromoteRGBReflectance(reflectance)
% Converts the given RGB reflectance to a full multi-spectral
% representation, by rendering a simple scene that contains a matte
% reflector with the given RGB surface reflectance, illuminated by a
% distant light with a spectrally uniform spectrum.
%
% Returns the estimated, "promoted" reflectance spectrum that the renderer
% used internally.  Also returns the "S" description of the renderer's
% wavelength sampling.  Also returns the down-converted RGB representation
% of the promoted spectrum.  Finally, returns the name of the .mat file
% that contains renderer ouput data and metadata from the simple scene
% rendering.
%
% The given reflectance should have RGB components in the range [0 1].
%
% rtbPromoteRGBReflectance( ... 'illuminant', illuminant) specifies the
% illuminant spectrum to use during rendering.  The default is '300:1
% 800:1', which is spectrally uniform over the range 300-800nm.
%
% rtbPromoteRGBReflectance( ... 'hints', hints) specifies a
% struct with options that affect the rendering process.  hints.renderer
% specifies which renderer to use.
%
% The renderer will "promote" the given RGB @a reflectance to its own
% internal spectral representation, perform rendering, and output some
% pixels that have spectral values that depend a few factors:
%   - the given RGB reflectance
%   - the illuminant spectrum
%   - the geometry of the test scene
%   - the renderer's spectral promotion algorithm
%
% This function estimates the "promoted" reflectance spectrum that the
% renderer used internally:
%   - reads the spectrum from one of the rendered output pixels
%   - "divides out" the spectrum of the illuminant
%   - normalizes the obtained spectrum to have the same max value as the
%   given reflectance.
%
% The obtained "promoted" spectrum will expose the "shape" of the
% renderer's sprctral promotion algorithm, but not scaling effects.
%
% This function also down-converts the "promoted" spectrum to down to an
% RGB representation, for direct comparison with the given reflectance.
% The down-conversion uses the CIE XYZ 1931 color matching functions.  The
% down-converted RGB reflectance will not necessarily match the original
% reflectance, but might nevertheless be of interest.
%
%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

parser = inputParser();
parser.addRequired('reflectance', @isnumeric);
parser.addParameter('illuminant', '300:1 800:1', @ischar);
parser.addParameter('hints', rtbDefaultHints(), @isstruct);
parser.parse(reflectance, varargin{:});
reflectance = parser.Results.reflectance;
illuminant = parser.Results.illuminant;
hints = rtbDefaultHints(parser.Results.hints);


%% Choose internal resources.
scenePath = fullfile(rtbRoot(), 'Utilities', 'SpectralPromotion');
sceneFile = fullfile(scenePath, 'SpectralPromotion.dae');
mappingsFile = fullfile(scenePath, 'SpectralPromotionMappings.json');
calibrationFile = fullfile(scenePath, 'SpectralPromotionCalibration.mat');
conditionsFile = 'SpectralPromotionConditions.txt';

% create a conditions file with given reflectance and illuminant
varNames = {'reflectanceRGB', 'illuminant'};
varValues = {reflectance, illuminant};
conditionsFile = rtbWriteConditionsFile(conditionsFile, varNames, varValues);

% choose batch renderer options
hints.whichConditions = [];
nPixels = 50;
hints.imageWidth = nPixels;
hints.imageHeight = nPixels;

% render and read an output pixel from the middle
sceneFiles = rtbMakeSceneFiles(sceneFile, ...
    'conditionsFile', conditionsFile, ...
    'mappingsFile', mappingsFile, ...
    'hints', hints);
outFiles = rtbBatchRender(sceneFiles, 'hints', hints);
dataFile = outFiles{1};
outData = load(dataFile);
S = outData.S;
outPixel = outData.multispectralImage(nPixels/2, nPixels/2, :);
outPixel = squeeze(outPixel);

% divide out scene specific scale factors related to geometry
%   this should be independent of the renderer
calibrationData = load(calibrationFile);
outPixel = outPixel ./ calibrationData.geometryScale;

% divide out the illuminant
%   SplineRaw(), not SplineSpd(): renderers already assume power/wavelength
[illumWls, illumPower] = rtbReadSpectrum(illuminant);
illumResampled = SplineRaw(illumWls, illumPower, outData.S);
promoted = outPixel ./ illumResampled;

% convert to sRGB
tinyImage = reshape(promoted, 1, 1, []);
[~, ~, rawRGB] = rtbMultispectralToSRGB(tinyImage, outData.S);
RGB = squeeze(rawRGB);

% scale so unit-valued reflectance comes out with unit-valued RGB
RGB = RGB ./ calibrationData.rgbScale;
