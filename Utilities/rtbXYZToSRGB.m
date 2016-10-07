function [gammaImage, rawImage, scaleFactor] = rtbXYZToSRGB(image, varargin)
%% Convert an image in XYZ space to sRGB color space.
%
% [gammaImage, rawImage, scaleFactor] = rtbXYZToSRGB(XYZImage) converts an
% image in XYZ colors to sRGB colors, using a few Psychtoolbox functions.
% The given XYZ image must be a matrix of size [height width 3] containing
% XYZ color data.
%
% rtbXYZToSRGB( ... 'toneMapFactor', toneMapFactor) specifies a threshold
% for simple tone mapping -- luminance will be trncated above this factor
% times the mean luminance.  The default is 0, don't do this tone mapping.
%
% rtbXYZToSRGB( ... 'toneMapMax', toneMapMax) specifies a threshold for an
% even simpler tone mapping -- truncate luminance above this value.  The
% default is 0, don't do this tone mapping.
%
% rtbXYZToSRGB( ... 'isScale', isScale) specifies whether to scale the
% gamma-corrected image.  If isScale is logical and true, the image will be
% scaled by its maximum.  If isScale is a number, the image will be scaled
% by this number.  The default is false, don't do any scaling.
%
% Returns a matrix of size [height width n] with gamma corrected sRGB color
% data.  Also returns a matrix of the same size with uncorrected sRGB color
% data.  Also returns a scalar, the amount by which the gamma-corrected
% image was scaled.  This may have been calculated or it may be equal to
% the given isScale.
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('image', @isnumeric);
parser.addParameter('toneMapFactor', 0, @isnumeric);
parser.addParameter('toneMapMax', 0, @isnumeric);
parser.addParameter('isScale', false);
parser.parse(image, varargin{:});
image = parser.Results.image;
toneMapFactor = parser.Results.toneMapFactor;
toneMapMax = parser.Results.toneMapMax;
isScale = parser.Results.isScale;

%% Convert XYZ to sRGB
%
% This is a standard color conversion given that one started in XYZ.
% All of the PTB color correction machinary wants 3 by nPixels matrices
% as input. This format is what I call calibration format.  It's convenient
% because it allows certain operations to be done as one big matrix
% multiply. Thus the conversion from image plane to calibration format at
% the start of the sequence, and the back converstion at the end.

% Convert to calibration format.
[XYZCalFormat,m,n] = ImageToCalFormat(image);

% Tone map.  This is a very simple algorithm that truncates
% luminance above a factor times the mean luminance.
if (toneMapFactor > 0)
    meanLuminance = mean(XYZCalFormat(2,:));
    maxLum = toneMapFactor * meanLuminance;
    XYZCalFormat = BasicToneMapCalFormat(XYZCalFormat, maxLum);
end

% Tone map again.  This is an even simpler algorithm
% that truncates luminance above a fixed value.
if (toneMapMax > 0)
    XYZCalFormat = BasicToneMapCalFormat(XYZCalFormat, toneMapMax);
end

% Convert to sRGB
%   may allow code to scale input max to output max.
SRGBPrimaryCalFormat = XYZToSRGBPrimary(XYZCalFormat);

if islogical(isScale)
    scaleFactor = 1/max(SRGBPrimaryCalFormat(:));
    SRGBCalFormat = SRGBGammaCorrect(SRGBPrimaryCalFormat, isScale);
else
    scaleFactor = isScale;
    SRGBPrimaryCalFormat = SRGBPrimaryCalFormat .* scaleFactor;
    SRGBCalFormat = SRGBGammaCorrect(SRGBPrimaryCalFormat, false);
end

% Back to image plane format
rawImage = CalFormatToImage(SRGBPrimaryCalFormat, m, n);
gammaImage = CalFormatToImage(SRGBCalFormat, m, n);
