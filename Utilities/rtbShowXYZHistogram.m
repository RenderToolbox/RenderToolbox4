function [nX, nY, nZ, edges, fig] = rtbShowXYZHistogram(image, varargin)
%% Plot histograms for XYZ image components.
%
% [nX, nY, nZ, edges] = rtbShowXYZHistogram(image) plots
% histograms of X, Y, and Z components of the given XYZ image, in a
% new figure.  image should be in Psychtoolbox "Image" format (as
% opposed to "Calibration" format), with size [nY, nX, 3].
%
% Bin edges will range from the image non-zero min to the image max.  0
% values will be ignored.
%
% rtbShowXYZHistogram( ... 'nEdges', nEdges) specifies the number of
% histogram bin edges.  The default is 100.
%
% Returns the counts for each bin, for each XYZ component, as nX, nY, and
% nZ.  Also returns the bin edges that were used.
%
% Also returns the handle to the new figure.
%
%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

parser = inputParser();
parser.addRequired('image', @isnumeric);
parser.addParameter('nEdges', 100, @isnumeric);
parser.parse(image, varargin);
image = parser.Results.image;
nEdges = parser.Results.nEdges;

%% Compute bin edges.
grandMax = max(image(:));
grandMin = min(image(image(:)~=0));
edges = linspace(grandMin, grandMax, nEdges);

%% "Calibration" format is more natural for histograms
XYZCalFormat = ImageToCalFormat(image);
N = histc(XYZCalFormat, edges, 2);
nX = N(1,:);
meanX = mean(XYZCalFormat(1,:));
nY = N(2,:);
meanY = mean(XYZCalFormat(2,:));
nZ = N(3,:);
meanZ = mean(XYZCalFormat(3,:));

%% plot the three histograms
%   with markers at the mean
fig = figure();

subplot(3,1,1, 'Parent', fig)
bar(edges, nX)
line(meanX*[1 1], [0, max(nX)], 'Marker', '+', 'LineStyle', '-')
xlim([0, grandMax])
ylabel('X')

subplot(3,1,2, 'Parent', fig);
bar(edges, nY)
line(meanY*[1 1], [0, max(nY)], 'Marker', '+', 'LineStyle', '-')
xlim([0, grandMax])
ylabel('Y')

subplot(3,1,3, 'Parent', fig);
bar(edges, nZ)
line(meanZ*[1 1], [0, max(nZ)], 'Marker', '+', 'LineStyle', '-')
xlim([0, grandMax])
ylabel('Z')
