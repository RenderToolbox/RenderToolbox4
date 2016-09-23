function fig = rtbPlotSlices(sliceInfo, data)
%% View each slice from a multi-spectral exr-file.
%
% fig = rtbPlotSlices(sliceInfo, data) Plots each slice from the given data
% as a grayscale image, along with the slice name and pixelType from the
% give sliceInfo.  Returns the new plot figure.
%
%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

parser = inputParser();
parser.addRequired('sliceInfo', @isstruct);
parser.addRequired('data', @isnumeric);
parser.parse(sliceInfo, data);
sliceInfo = parser.Results.sliceInfo;
data = parser.Results.data;

fig = figure();

nSlices = numel(sliceInfo);
rows = round(sqrt(nSlices));
cols = ceil(nSlices/rows);
for ii = 1:nSlices
    subplot(rows, cols, ii)
    imshow(255 * data(:,:,ii))
    title(sliceInfo(ii).name)
    xlabel(sliceInfo(ii).pixelType)
end
