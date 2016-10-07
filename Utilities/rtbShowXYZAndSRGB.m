function [xyzFig, srgbFig] = rtbShowXYZAndSRGB(XYZImage, SRGBImage, name)
%% Plot XYZ and sRGB images.
%
% [xyzFig, rgbFig] = rtbShowXYZAndSRGB(XYZImage, SRGBImage, name) is a
% one-liner to make two plots for XYZ and sRGB images.  The given XYZImage
% and SRGBImage will be plotted in new figures.  The gven name will appear
% as the image title in each plot.
%
% Returns handles to the new figures.
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('XYZImage', @isnumeric);
parser.addRequired('SRGBImage', @isnumeric);
parser.addRequired('name', @ischar);
parser.parse(XYZImage, SRGBImage, name);
XYZImage = parser.Results.XYZImage;
SRGBImage = parser.Results.SRGBImage;
name = parser.Results.name;

xyzFig = [];
if nargin > 0 && ~isempty(XYZImage)
    xyzFig = figure();
    ax = axes('Parent', xyzFig);
    
    % assume XYZ image is full range floating point
    imshow(XYZImage, 'Parent', ax);
    ylabel(ax, 'XYZ')
    title(ax, name)
    drawnow();
end

srgbFig = [];
if nargin > 1 && ~isempty(SRGBImage)
    srgbFig = figure();
    ax = axes('Parent', srgbFig);
    
    % assume SRGB is gamma corrected unsigned bytes
    imshow(uint8(SRGBImage), 'Parent', ax);
    ylabel(ax, 'SRGB')
    title(ax, name)
    drawnow();
end
