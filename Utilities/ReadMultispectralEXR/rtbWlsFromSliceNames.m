function [wls, S, order] = rtbWlsFromSliceNames(sliceNames, varargin)
%% Read wavelength info from multi-spectral image slice names.
%
% [wls, S, order] = rtbWlsFromSliceNames(sliceNames) scans the cell array
% of image slice names for wavelength info using sscanf() and the default
% matching pattern '%f-%f'.
%
% For each image slice, if sscanf() returns a single number, this is
% treated as a spectral band center.  If sscanf() returns two numbers, they
% are treated as band edges and averaged to obtain a band center.  If
% sscanf() returns zero or more than two numbers, that band is ignored.
%
% Returns an array of n spectral band centers, one for each image slice.
% The array will be sorted from low to high.  Also returns a summary of the
% list of wavelengths in "S" format.  This is an array with elements [start
% delta n].  Finally, returns an array of indices that may be used to sort
% the given sliceNames or other data from low to high wavelength.
%
% rtbWlsFromSliceNames( ... 'namePattern', namePattern) specifies the
% matching pattern to use when scanning slice names.  The default is
% '%f-%f'.
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('sliceNames', @iscell);
parser.addParameter('namePattern', '%f-%f', @ischar);
parser.parse(sliceNames, varargin{:});
sliceNames = parser.Results.sliceNames;
namePattern = parser.Results.namePattern;

% look for channels that contain wavelengths
nSlices = numel(sliceNames);
wls = zeros(1, nSlices);
isSpectralBand = false(1, nSlices);
for ii = 1:nSlices
    band = sscanf(sliceNames{ii}, namePattern);
    switch numel(band)
        case 1
            wls(ii) = band;
            isSpectralBand(ii) = true;
        case 2
            wls(ii) = mean(band);
            isSpectralBand(ii) = true;
    end
end

% sort slices by wavelength
[wls, order] = sort(wls);
isSpectralBand = isSpectralBand(order);

% summarize the slice wavelengths
wls = wls(isSpectralBand);
S = MakeItS(wls(:));
