%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Get multi-spectral image data out of some .exr files in a folder.
%   @param imageDir string folder name containing .exr files
%   @param imageBase string prefix that all .exr file names start with
%   @param S matrix specifying spectral plane wavelengths [start delta n]
%
% @details
% Reads .exr files from the given @a imageDir.  Each .exr file should
% contain a grayscale image.  Each file should be named like
% "@a imageBase-LOW-HIGH.ext", where @a imageBase is a common prefix for
% all images, and LOW and HIGH are wavelengths that define a spectral band.
%
% @details
% The @a S determines what file names to look for.  S must be a [start
% delta n] description of a list of wavelengths.
%
% @details
% Returns a matrix of multispectral image data, with size [height width n],
% where height and width are image size in pixels, and n is the number of
% spectral planes.
%
% @details
% Also returns the multi-spectral image dimensions [height width n].  Also
% returns a matrix of length n that lists the wavelengths of all spectral
% planes in nanometers.
%
% @details
% Usage:
%   [imageData, imageSize, wls] = ReadEXRs(imageDir, imageBase, S)
%
% @ingroup Readers
function [imageData, imageSize, wls] = ReadEXRs(imageDir, imageBase, S)

%% get explicit list of wavelengths
wls = SToWls(S);

%% Read in the image data.
fprintf('Reading %d images from %s.\n', S(3), imageDir);
for w = 1:length(wls)
    bandLow = wls(w)-(S(2)/2);
    bandHigh = bandLow+S(2);
    imageName = sprintf('%s-%d-%d.exr', imageBase, bandLow, bandHigh);
    imagePath = fullfile(imageDir,imageName);
    
    % Read.  Throw away the A channel.  And make into an image array.
    tmpImage = ReadEXR(imagePath);
    tmpImage = tmpImage(:,:,1:3);
    if (w == 1)
        [imageSize] = size(tmpImage);
        imageData = zeros(imageSize(1),imageSize(2),length(wls));
    end
    
    % We think all three planes of tmpImage should be the same as each
    % other.
    diffCheck = tmpImage(:,:,1)-tmpImage(:,:,2);
    if (max(abs(diffCheck(:))) ~= 0)
        error('Image %s RGB channels should be identical.', imageName);
    end
    diffCheck = tmpImage(:,:,1)-tmpImage(:,:,3);
    if (max(abs(diffCheck(:))) ~= 0)
        error('Image %s RGB channels should be identical.', imageName);
    end
    
    % Tuck the plane into the multi-spectral image
    imageData(:,:,w) = tmpImage(:,:,1);
end