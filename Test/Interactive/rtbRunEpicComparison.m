function [comparisons, matchInfo, figs] = rtbRunEpicComparison(folderA, folderB, varargin)
%% Compare sets of renderings for similarity.
%
% comparisons = rtbRunEpicComparison(folderA, folderB) locates renderings
% in folderA and folderB, compares pairs of renderings found between the
% two folders, and plots a summary of the comparisons.  Returns a struct
% array of comparison results, one for each pair of renderings.
%
% Also returns a struct array of info about how renderings were matched
% between folderA and folderB, including renderings from each folder that
% were unmatched.
%
% Also returns an array of figure handles for visualizations of the
% comparison results.
%
% rtbRunEpicComparison( ... 'plotSummary', plotSummary) whether to create a
% plot summarizing the overall comparison results.  The default is true,
% make a summary plot.
%
% rtbRunEpicComparison( ... 'closeSummary', closeSummary) whether to create
% a close the overalls summary plot when done.  This is useful when you
% specify a figureFolder, where the summary plot can be saved to disk.  the
% default is false, don't close the summary figure.
%
% rtbRunEpicComparison( ... 'plotImages', plotImages) whether to create a
% plot showing images and difference images for each pair of renderings.
% The default is false, don't show the images for each pair.
%
% rtbRunEpicComparison( ... 'closeImages', closeImages) whether to close
% the image plot for each pair of renderings when done.  This is useful
% when you specify a figureFolder, where the images can be saved to disk.
% The default is true, do close the image figures.
%
% rtbRunEpicComparison( ... 'figureFolder', figureFolder) specify a folder
% where generated plots should be saved to disk, as a .fig file and as a
% .png file.  The default is '', don't save figures to disk.
%
%%% RenderToolbox4 Copyright (c) 2012-2017 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('folderA', @ischar);
parser.addRequired('folderB', @ischar);
parser.addParameter('plotSummary', true, @islogical);
parser.addParameter('closeSummary', false, @islogical);
parser.addParameter('plotImages', false, @islogical);
parser.addParameter('closeImages', true, @islogical);
parser.addParameter('figureFolder', '', @ischar);
parser.parse(folderA, folderB, varargin{:});
folderA = parser.Results.folderA;
folderB = parser.Results.folderB;
plotSummary = parser.Results.plotSummary;
closeSummary = parser.Results.closeSummary;
plotImages = parser.Results.plotImages;
closeImages = parser.Results.closeImages;
figureFolder = parser.Results.figureFolder;

matchInfo = [];
unmatchedA = {};
unmatchedB = {};



%% Save a figure to file, watch out for things like uicontrols.
function saveFigure(fig, fileName)

% flush pending drawing commands
drawnow();

% hide uicontrols, which can't always be saved
controls = findobj(fig, 'Type', 'uicontrol');
set(controls, 'Visible', 'off');

% make sure output location exists
[filePath, fileName] = fileparts(fileName);
if 7 ~= exist(filePath, 'dir')
    mkdir(filePath);
end

% save a png and a figure
figName = fullfile(imageCompPath, [fileName '.fig']);
saveas(fig, figName, 'fig');

pngName = fullfile(imageCompPath, [fileName '.png']);
set(fig, 'PaperPositionMode', 'auto');
saveas(fig, pngName, 'png');

% restore uicontrols
set(controls, 'Visible', 'on');

