function [sRGBImage, XYZImage, rawRGBImage] = rtbMultispectralToSRGB(multispectralImage, S, varargin)
% Convert multi-spectral image data to XYZ and sRGB.
%
% sRGBImage = rtbMultispectralToSRGB(multispectralImage, S)
% Convert the given multispectralImage of size [height width n] to an
% sRGB image of size [height width 3], for viewing on a standard monitor,
% using the CIE 1931 standard weighting functions.  The given S must
% describe the n spectral planes of the multispectralImage.  It should have
% the form [start delta n], where start and delta are wavelengths in
% nanometers, and n is the number of spectral planes.
%
% sRGBImage = rtbMultispectralToSRGB( ... 'toneMapFactor', toneMapFactor)
% specifies a simple tone mapping threshold.  Truncates lumininces above
% this factor times the mean luminance.  The default is 0, don't truncate
% luminances.
%
% sRGBImage = rtbMultispectralToSRGB( ... 'isScale', isScale)
% specifies whether to scale the gamma-corrected image to the display
% maximum (true) or not (false).  The default is false, don't scale the
% image.
%
% Returns a gamma-corrected sRGB image of size [height width 3].  Also
% returns the intermediate XYZ image and the uncorrected RGB image, which
% have the same size.
%
%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

parser = inputParser();
parser.addRequired('multispectralImage', @isnumeric);
parser.addRequired('S', @isnumeric);
parser.addParameter('toneMapFactor', 0, @isnumeric);
parser.addParameter('isScale', false, @islogical);
parser.parse(multispectralImage, S, varargin{:});
multispectralImage = parser.Results.multispectralImage;
S = parser.Results.S;
toneMapFactor = parser.Results.toneMapFactor;
isScale = parser.Results.isScale;

% convert to CIE XYZ image using CIE 1931 standard weighting functions
%   683 converts watt-valued spectra to lumen-valued luminances (Y-values)
wattsToLumens = 683;
matchingData = load('T_xyz1931');
matchingFunction = wattsToLumens*matchingData.T_xyz1931;
matchingS = matchingData.S_xyz1931;
XYZImage = rtbMultispectralToSensorImage(multispectralImage, S, ...
    matchingFunction, matchingS);

% convert to sRGB with a very simple tone mapping algorithm that truncates
% luminance above a factor times the mean luminance
[sRGBImage, rawRGBImage] = rtbXYZToSRGB(XYZImage, ...
    'toneMapFactor', toneMapFactor, ...
    'isScale', isScale);
