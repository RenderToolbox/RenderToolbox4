function [wavelengths, magnitudes, sRGB] = rtbGetPixelSpectrum(image, spectrum, x, y)
%% Get wavelengths and magnitudes from a multi-spectral image pixel.
%
% [wavelengths, magnitudes, sRGB] = rtbGetPixelSpectrum(image, spectrum, x, y)
% Gets the spectral magnitude distribution of one pixel in the given
% multi-spectral image.
%
% The image must be a multi-spectral image matrix, with size [height width
% n], where height and width are the image pixel dimensions, and n is the
% number of spectrum bands in the image.
%
% spectrum must be a description of the n spectrum bands in image.
% spectrum may be a 1 x n list of wavelengths, or it may be an "S"
% description of the form [start delta n].
%
% x and y must be the coordinates of the pixel of interest.
%
% Returns a 1 x n matrix of n wavelengths, and a corresponding 1 x n matrix
% of magnitudes, for the pixel of interest.  Also returns an sRGB
% approximation of the spectrum of the pixel of interest.
%
%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

parser = inputParser();
parser.addRequired('image', @isnumeric);
parser.addRequired('spectrum', @isnumeric);
parser.addRequired('x', @isnumeric);
parser.addRequired('y', @isnumeric);
parser.parse(image, spectrum, x, y);
image = parser.Results.image;
spectrum = parser.Results.spectrum;
x = parser.Results.x;
y = parser.Results.y;

% determine the wavelength of each spectrum band
wavelengths = MakeItWls(spectrum);

% probe the pixel of interest
magnitudes = squeeze(image(y, x, :));

% make an sRGB approximation
sRGB = squeeze( ...
    rtbMultispectralToSRGB(reshape(magnitudes, 1, 1, []), wavelengths, ...
    'toneMapFactor', 0, ...
    'isScale', false));
