function [imageData, wls, S] = rtbReadMultispectralEXR(exrFile, varargin)
%% Read an OpenEXR image with multiple spectral slices.
%
% [imageData, wls, S] = rtbReadMultispectralEXR(exrFile)
% Reads data from the given OpenEXR multi-spectral data file.  The data
% should be stored as evenly spaced slices through the spectrum, not as
% RGB or RGBA.  Each slice must have a name that identifies the wavelengths
% of that particular slice, such as '12.34-56.78nm'.
%
% rtbReadMultispectralEXR( ... 'namePattern', namePattern) specifies the
% matching pattern to use when scanning slice names.  The default is
% '%f-%f'.
%
% Returns an array of image data with size [height width n], where height
% and width are image sizes in pixels, and n is the number of spectral
% slices.  The n slices will be sorted from low to high wavelength.
%
% Also returns the list of n wavelengths, one for each spectral slice.  The
% wavelength for each slice is taken as the mean of the low and high bounds
% The list of wavelengths will be sorted from low to high.  See the
% RenderToolbox4 wiki for more about spectrum bands:
%   https://github.com/DavidBrainard/RenderToolbox4/wiki/Spectrum-Bands
%
% Also returns a summary of the list of wavelengths in "S" format.  This is
% an array with elements [start delta n].
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('exrFile', @ischar);
parser.addParameter('namePattern', '%f-%f', @ischar);
parser.parse(exrFile, varargin{:});
exrFile = parser.Results.exrFile;
namePattern = parser.Results.namePattern;

% read all channels from the OpenEXR image
[sliceInfo, imageData] = rtbReadMultichannelEXR(exrFile);

% scan channel names for wavelength info
sliceNames = {sliceInfo.name};
[wls, S, order] = rtbWlsFromSliceNames(sliceNames, 'namePattern', namePattern);

% sort data slices by wavelength
imageData = imageData(:,:,order);
