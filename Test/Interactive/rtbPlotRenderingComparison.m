function fig = rtbPlotRenderingComparison(comparison, varargin)
%% Plot a rendering comparison from rtbCompareRenderings().
%
% fig = rtbPlotRenderingComparison(comparison) makes a plot to visualize
% the given struct of comparison results, as produced by
% rtbCompareRenderings().
%
%%% RenderToolbox4 Copyright (c) 2012-2017 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.KeepUnmatched = true;
parser.addRequired('comparison', @isstruct);
parser.addParameter('isScale', true, @islogical);
parser.addParameter('toneMapFactor', 0, @isnumeric);
parser.addParameter('fig', figure());
parser.parse(comparison, varargin{:});
comparison = parser.Results.comparison;
isScale = parser.Results.isScale;
toneMapFactor = parser.Results.toneMapFactor;
fig = parser.Results.fig;


%% Compute RGB images for viewing.
S = comparison.samplingA;
rgbA = rtbMultispectralToSRGB(comparison.A, S, ...
    'toneMapFactor', toneMapFactor, 'isScale', isScale);
rgbB = rtbMultispectralToSRGB(comparison.B, S, ...
    'toneMapFactor', toneMapFactor, 'isScale', isScale);
rgbAminusB = rtbMultispectralToSRGB(comparison.aMinusB, S, ...
    'toneMapFactor', toneMapFactor, 'isScale', isScale);
rgbBminusA = rtbMultispectralToSRGB(comparison.bMinusA, S, ...
    'toneMapFactor', toneMapFactor, 'isScale', isScale);


%% Make the plot.
name = sprintf('%s isScale %d toneMapFactor %.2f', ...
    comparison.renderingA.identifier, ...
    isScale, ...
    toneMapFactor);
set(fig, ...
    'Name', name, ...
    'NumberTitle', 'off');

ax = subplot(2, 2, 2, 'Parent', fig);
imshow(uint8(rgbA), 'Parent', ax);
title(ax, 'A');

ax = subplot(2, 2, 3, 'Parent', fig);
imshow(uint8(rgbB), 'Parent', ax);
title(ax, 'B');

ax = subplot(2, 2, 1, 'Parent', fig);
imshow(uint8(rgbAminusB), 'Parent', ax);
title(ax, 'A - B');

ax = subplot(2, 2, 4, 'Parent', fig);
imshow(uint8(rgbBminusA), 'Parent', ax);
title(ax, 'B - A');
