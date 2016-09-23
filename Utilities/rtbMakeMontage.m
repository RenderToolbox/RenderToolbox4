function [SRGBMontage, XYZMontage, luminanceScale] = rtbMakeMontage(inFiles, varargin)
%% Combine several multi-spectral renderings into one sRGB montage.
%
% SRGBMontage = rtbMakeMontage(inFiles)
% Condenses several multi-spectral renderings stored in mat-files into a
% single sRGB montage.  inFiles must be a cell array of mat-file names,
% each of which must contain multi-spectral renderer output, as returned
% from rtbBatchRender().
%
% By default, tiles the input images so that the montage has roughly the
% same aspect ratio as the input images.  If inFiles has size other than
% 1xn, the shape of inFiles determine the shape of the montage.
%
% Attempts to conserve system memory by loading only one multi-spectral
% image at a time.
%
% SRGBMontage = rtbMakeMontage( ... 'outFile', outFile) specify the file name
% of the new montage.  The file extension determines the file format:
%   - If the extension is '.mat', the montage XYZ and sRGB matrices
%   will be saved to a .mat data file.
%   - If the extension matches a standard image format, like '.tiff' or
%   '.png' (default), the sRGB image will be saved in that format, using
%   Matlab's built-in imwrite().
%
% sRGBImage = rtbMakeMontage( ... 'toneMapFactor', toneMapFactor)
% specifies a simple tone mapping threshold.  Truncates lumininces above
% this factor times the mean luminance.  The default is 0, don't truncate
% luminances.
%
% sRGBImage = rtbMakeMontage( ... 'isScale', isScale)
% specifies whether to scale the gamma-corrected image to the display
% maximum (true) or not (false).  The default is false, don't scale the
% image.
%
% outFiles = rtbMakeSensorImages( ... 'hints', hints)
% Specifies RenderToolbox4 "hints" to control things like the working
% folder where output should be written.  The default is rtbDefaultHints().
%
% Returns a matrix containing the sRGB montage image with size [height
% width 3].  Also returns a matrix containing XYZ  image data with the same
% size.  Also returns a scalar, the amount by which montage luminances were
% scaled.
%
% [SRGBMontage, XYZMontage, luminanceScale] = rtbMakeMontage(inFiles, varargin)
%
%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

parser = inputParser();
parser.addRequired('inFiles', @iscellstr);
parser.addParameter('outFile', '', @ischar);
parser.addParameter('toneMapFactor', 0, @isnumeric);
parser.addParameter('isScale', false, @islogical);
parser.addParameter('hints', rtbDefaultHints(), @isstruct);
parser.parse(inFiles, varargin{:});
inFiles = parser.Results.inFiles;
outFile = parser.Results.outFile;
toneMapFactor = parser.Results.toneMapFactor;
isScale = parser.Results.isScale;
hints = rtbDefaultHints(parser.Results.hints);

if isempty(outFile)
    montageName = sprintf('%s-%s', hints.recipeName, hints.renderer);
    outFile = [montageName '.png'];
end
[outPath, outBase, outExt] = fileparts(outFile);

if isempty(outPath)
    outPath = rtbWorkingFolder( ...
        'folderName', 'images', ...
        'rendererSpecific', true, ...
        'hints', hints);
end

SRGBMontage = [];
XYZMontage = [];

%% Pick the montage dimensions.
nIns = numel(inFiles);
dims = size(inFiles);
if 1 == dims(1)
    % default to roughly square
    nRows = floor(sqrt(nIns));
else
    % use given dimensions
    nRows = dims(1);
end
nCols = ceil(nIns / nRows);

%% Assemble the montage.
for ii = 1:nIns
    % get multispectral data from disk
    inData = load(inFiles{ii});
    multiImage = inData.multispectralImage;
    S = inData.S;
    
    % convert down to XYZ representation
    XYZImage = rtbMultispectralToSensorImage(multiImage, S, 'T_xyz1931', []);
    
    % first image, allocate a big XYZ montage
    if ii == 1
        h = size(XYZImage, 1);
        w = size(XYZImage, 2);
        XYZMontage = zeros(h*nRows, w*nCols, 3);
    end
    
    % insert the XYZ image into a cell of the montage
    row = 1 + mod(ii-1, nRows);
    col = 1 + floor((ii-1)/nRows);
    x = (col-1) * w;
    y = (row-1) * h;
    XYZMontage(y+(1:h), x+(1:w),:) = XYZImage(1:h, 1:w,:);
end

%% Convert the whole big XYZ montage to SRGB.
[SRGBMontage, ~, luminanceScale] = ...
    rtbXYZToSRGB(XYZMontage, 'toneMapFactor', toneMapFactor, 'isScale', isScale);

%% Save to disk.
if ~isempty(outPath) && 7 ~= exist(outPath, 'dir')
    mkdir(outPath);
end

outFullPath = fullfile(outPath, [outBase outExt]);
if strcmp(outExt, '.mat')
    % write multi-spectral data
    save(outFullPath, 'SRGBMontage', 'XYZMontage');
else
    % write RGB image
    imwrite(uint8(SRGBMontage), outFullPath, outExt(2:end));
end
