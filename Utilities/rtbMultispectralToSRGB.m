function [sRGBImage, XYZImage, rawRGBImage, scaleFactor] = rtbMultispectralToSRGB(multispectralImage, S, varargin)
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
% sRGBImage = rtbMultispectralToSRGB( ... 'toneMapThreshold', toneMapThreshold)
% specifies a simple tone mapping threshold.  Truncates lumininces above
% the given toneMapThreshold.  The default is 0, don't truncate luminances.
%
% If toneMapFactor and toneMapThreshold are both supplied, toneMapThreshold
% is used and toneMapFactor is ignored.
%
% sRGBImage = rtbMultispectralToSRGB( ... 'isScale', isScale)
% specifies whether to scale the gamma-corrected image to the display
% maximum (true) or not (false).  The default is false, don't scale the
% image.
%
% sRGBImage = rtbMultispectralToSRGB( ... 'scaleFactor', scaleFactor)
% specifies a constant to scale the sRGB image.  The default is 0, don't
% scale the image.
%
% If isScale and scaleFactor are both supplied, scaleFactor
% is used and isScale is ignored.
%
% Returns a gamma-corrected sRGB image of size [height width 3].  Also
% returns the intermediate XYZ image and the uncorrected RGB image, which
% have the same size.  Also returns the scale factor that was used to
% scale the sRGB image, if any.
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('multispectralImage', @isnumeric);
parser.addRequired('S', @isnumeric);
parser.addParameter('toneMapFactor', 0, @isnumeric);
parser.addParameter('toneMapThreshold', 0, @isnumeric);
parser.addParameter('isScale', false, @islogical);
parser.addParameter('scaleFactor', 0, @isnumeric);
parser.parse(multispectralImage, S, varargin{:});
multispectralImage = parser.Results.multispectralImage;
S = parser.Results.S;
toneMapFactor = parser.Results.toneMapFactor;
toneMapThreshold = parser.Results.toneMapThreshold;
isScale = parser.Results.isScale;
scaleFactor = parser.Results.scaleFactor;

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
[sRGBImage, rawRGBImage, scaleFactor] = rtbXYZToSRGB(XYZImage, ...
    'toneMapFactor', toneMapFactor, ...
    'toneMapThreshold', toneMapThreshold, ...
    'isScale', isScale, ...
    'scaleFactor', scaleFactor);
