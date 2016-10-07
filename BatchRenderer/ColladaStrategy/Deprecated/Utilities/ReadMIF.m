%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Get multispectral image data out of a .mif file from Stanford.
%   @param filename string file name (path optional) of the .mif file
%
% @details
% Reads the given multispectral .mif file from @a filename.  The .mif
% format is described by Andy Lin on the Stanford Vision and Imaging
% Science and Technology wiki:
% http://white.stanford.edu/pdcwiki/index.php/PBRTFileFormat
%
% @details
% Returns a matrix of multispectral image data, with size [height width n],
% where height and width are image size in pixels, and n is the number of
% spectral planes.
%
% @details
% Also returns the multispectral image dimensions [height width n].  Also
% returns a matrix of length n that lists the wavelengths of all spectral
% planes in nanometers.
%
% @details
% Usage:
%   [imageData, imageSize, wavelengths] = ReadMIF(filename)
%
% @ingroup Readers
function [imageData, imageSize, wavelengths] = ReadMIF(filename)

imageData = [];
imageSize = [];
wavelengths = [];

%% Try to open the file
fprintf('Opening file "%s".\n', filename);
[fid, message] = fopen(filename, 'r');
if fid < 0
    error(message);
end

%% Read header lines
sizeLine = fgetl(fid);
[mifSize, count, err] = lineToMat(sizeLine);
if count <= 0
    fclose(fid);
    error('Could not read image size: %s', err);
end
wSize = mifSize(1);
hSize = mifSize(2);
nPlanes = mifSize(3);
imageSize = [hSize, wSize, nPlanes];

wavelengthLine = fgetl(fid);
[wavelengths, count, err] = lineToMat(wavelengthLine);
if count <= 0
    fclose(fid);
    error('Could not read image wavelengths: %s', err);
end
wavelengths = wavelengths(:);

% seems to be a bug in the pbrt-v2-multi .mif ouput
wavelengths = wavelengths + 10;

%% Read image data
imageData = zeros(imageSize);
fprintf('Reading spectral planes for image (h=%d x w=%d pixels).\n', ...
    hSize, wSize);
for p = 1:nPlanes
    fprintf('  reading plane %d of %d (%dnm).\n', ...
        p, nPlanes, wavelengths(p));

    % read in the next plane of image data
    imageLine = fgetl(fid);
    [imagePlane, count, err] = lineToMat(imageLine);
    if count <= 0
        fclose(fid);
        error('Could not read image plane from file: %s', err);
    end
    
    % is the next plane the correct size?
    if numel(imagePlane) ~= hSize*wSize
        fclose(fid);
        error('Image plane has the wrong pixel count: %d should be %d.', ...
            numel(imagePlane), hSize*wSize);
    end
    
    % insert the next plane into the output image
    imageData(:,:,p) = reshape(imagePlane, wSize, hSize)';
end
fprintf('OK.\n');

fclose(fid);

function [mat, count, err] = lineToMat(line)
% is it an actual line?
if isempty(line) || (isscalar(line) && line < 0)
    mat = [];
    count = -1;
    err = 'Invalid line.';
    return;
end

% scan line for numbers
[mat, count, err] = sscanf(line, '%f', inf);