function [matchInfo, unmatchedA, unmatchedB] = rtbCompareAllExampleScenes(workingFolderA, workingFolderB, varargin)
%% Compare recipe renderings that were generated at different times.
%
% [matchInfo, unmatchedA, unmatchedB] = rtbCompareAllExampleScenes(workingFolderA, workingFolderB)
% Finds 2 sets of rendering outputs: set A includes renderings located
% under the given workingFolderA, set B includes renderings located
% under workingFolderB.  Attempts to match up data files from both sets,
% based on recipe names and renderer names.  Computes comparison statistics
% and shows difference images for each matched pair.
%
% Data sets must use a particular folder structure, consistent with
% rtbWorkingFolder().  For each rendering data file, the expected path is:
%	workingFolder/recipeName/rendererName/renderings/fileName.mat
%
% where:
%   - workingFolder is either workingFolderA or workingFolderB
%	- recipeName must be the name of a recipe such as "MakeDragon"
%	- rendererName must be the name of a renderer, like "PBRT" or "Mitsuba"
%	- fileName must be the name of a multi-spectral data file, such as "Dragon-001"
%
% rtbCompareAllExampleScenes( ... 'filterExpression', filterExpression)
% uses the given regular expression filterExpr'/home/ben/Desktop/testA'ession to select file paths.
% Only data files whose paths match the expression will be compared.  The
% default is to do no such filtering.
%
% rtbCompareAllExampleScenes( ... 'visualize', visualize) specifies the
% level of visualization to do during comparinsons.  The options are:
%   - 0 -- don't plot anything
%   - 1 -- (default) plot a summary figure at the end
%   - 2 -- plot a summary figure at the end and a detail figure for each comparison
%
% The summary figure will contain two plots:
%
% A "correlation" plot will show this correlation betweeen paired
% multi-spectral images, with each image simply treated as a matrix of
% numbers.
%
% A "relative diff" plot will show the relative differences between paired
% pixel components, where raw diff is
%   diff = |a-b|/a, where a/max(a) > .2
% The diff is only calculated when the "a" value is not small, to avoid
% unfair comparison due to large denominator.  For each pair of images, the
% plot will show the mean and max of the diffs from all pixel components.
%
% rtbCompareAllExampleScenes( ... 'figureFolder', figureFolder) specifies
% an output folder where to save figures used for visualization.  The
% default is rtbWorkingFolder().
%
% This function is intended to help validate RenderToolbox installations
% and detect bugs in the RenderToolbox code.  A potential use would
% compare renderings produced locally with archived renderings located at
% Amazon S3.  For example:
%   % produce renderings locally
%   rtbTestAllExampleScenes('my/local/renderings');
%
%   % download archived renderings to 'my/local/archive'
%
%   % summarize local vs archived renderings
%   workingFolderA = 'my/local/renderings/data';
%   workingFolderA = 'my/local/archive/data';
%   visualize = 1;
%   matchInfo = rtbCompareAllExampleScenes(workingFolderA, workingFolderB, 'visualize', visualize);
%
% Returns a struct array of info about each matched pair, including file
% names and differneces between multispectral images (A minus B).
%
% Also returns a cell array of paths for files in set A that did not match
% any of the files in set B.  Likewise, returns a cell array of paths for
% files in set B that did not match any of the files in set A.
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('workingFolderA', @ischar);
parser.addRequired('workingFolderB', @ischar);
parser.addParameter('filterExpression', '', @ischar);
parser.addParameter('visualize', 1, @isnumeric);
parser.addParameter('figureFolder', fullfile(rtbWorkingFolder(), 'comparisons'), @ischar);
parser.parse(workingFolderA, workingFolderB, varargin{:});
workingFolderA = parser.Results.workingFolderA;
workingFolderB = parser.Results.workingFolderB;
filterExpression = parser.Results.filterExpression;
visualize = parser.Results.visualize;
figureFolder = parser.Results.figureFolder;

matchInfo = [];
unmatchedA = {};
unmatchedB = {};

% find .mat files for sets A and B
fileFilter = [filterExpression '[^\.]*\.mat$'];
filesA = rtbFindFiles('root', workingFolderA, 'filter', fileFilter);
filesB = rtbFindFiles('root', workingFolderB, 'filter', fileFilter);

if isempty(filesA)
    fprintf('Found no files for set A in: %s\n', workingFolderA);
    return;
end

if isempty(filesB)
    fprintf('Found no files for set B in: %s\n', workingFolderB);
    return;
end

% parse out expected path parts for each file
infoA = scanDataPaths(filesA);
infoB = scanDataPaths(filesB);

% report unmatched files
matchTokensA = {infoA.matchToken};
matchTokensB = {infoB.matchToken};
[~, indexA, indexB] = intersect( ...
    matchTokensA, matchTokensB, 'stable');
[~, unmatchedIndex] = setdiff(matchTokensA, matchTokensB);
unmatchedA = filesA(unmatchedIndex);
[~, unmatchedIndex] = setdiff(matchTokensB, matchTokensA);
unmatchedB = filesB(unmatchedIndex);

if isempty(indexA) || isempty(indexB)
    fprintf('Could not find any file matches.\n');
    return;
end

% allocate an info struct for image comparisons
filesA = {infoA.original};
filesB = {infoB.original};
matchInfo = struct( ...
    'fileA', filesA(indexA), ...
    'fileB', filesB(indexB), ...
    'workingFolderA', workingFolderA, ...
    'workingFolderB', workingFolderB, ...
    'relativePathA', {infoA(indexA).relativePath}, ...
    'relativePathB', {infoB(indexB).relativePath}, ...
    'matchTokenA', matchTokensA(indexA), ...
    'matchTokenB', matchTokensB(indexB), ...
    'samplingA', [], ...
    'samplingB', [], ...
    'denominatorThreshold', 0.2, ...
    'subpixelsA', [], ...
    'subpixelsB', [], ...
    'normA', [], ...
    'normB', [], ...
    'normDiff', [], ...
    'absNormDiff', [], ...
    'relNormDiff', [], ...
    'corrcoef', nan, ...
    'isGoodComparison', false, ...
    'detailFigure', nan, ...
    'error', '');

% any comparisons to make?
nMatches = numel(matchInfo);
if nMatches > 0
    fprintf('Found %d matched pairs of data files.\n', nMatches);
    fprintf('Some of these might not contain images and would be skipped.\n');
else
    fprintf('Found no matched pairs.\n');
    return;
end
fprintf('\n')

nUnmatchedA = numel(unmatchedA);
if nUnmatchedA > 0
    fprintf('%d data files in set A had no match in set B:\n', nUnmatchedA);
    for ii = 1:nUnmatchedA
        fprintf('  %s\n', unmatchedA{ii});
    end
end
fprintf('\n')

nUnmatchedB = numel(unmatchedB);
if nUnmatchedB > 0
    fprintf('%d data files in set B had no match in set A:\n', nUnmatchedB);
    for ii = 1:nUnmatchedB
        fprintf('  %s\n', unmatchedB{ii});
    end
end
fprintf('\n')

% compare matched images!
for ii = 1:nMatches
    fprintf('%d of %d: %s\n', ii, nMatches, matchInfo(ii).matchTokenA);
    
    % load data
    dataA = load(matchInfo(ii).fileA);
    dataB = load(matchInfo(ii).fileB);
    
    % do we have images?
    hasImageA = isfield(dataA, 'multispectralImage');
    hasImageB = isfield(dataB, 'multispectralImage');
    if hasImageA
        if hasImageB
            % each has an image -- proceed
        else
            matchInfo(ii).error = ...
                'Data file A has a multispectralImage but B does not!';
            disp(matchInfo(ii).error);
            continue;
        end
    else
        if hasImageB
            matchInfo(ii).error = ...
                'Data file B has a multispectralImage but A does not!';
            disp(matchInfo(ii).error);
            continue;
        else
            matchInfo(ii).error = ...
                'Neither data file A nor B has a multispectralImage -- skipping.';
            continue;
        end
    end
    multispectralA = dataA.multispectralImage;
    multispectralB = dataB.multispectralImage;
    
    % do image dimensions agree?
    if ~isequal(size(multispectralA, 1), size(multispectralB, 1)) ...
            || ~isequal(size(multispectralA, 2), size(multispectralB, 2))
        matchInfo(ii).error = ...
            sprintf('Image A[%s] is not the same size as image B[%s].', ...
            num2str(size(multispectralA)), num2str(size(multispectralB)));
        disp(matchInfo(ii).error);
        continue;
    end
    
    % do we have spectral sampling?
    hasSamplingA = isfield(dataA, 'S');
    hasSamplingB = isfield(dataB, 'S');
    if hasSamplingA
        if hasSamplingB
            % each has a sampling "S" -- proceed
        else
            matchInfo(ii).error = ...
                'Data file A has a spectral sampling "S" but B does not!';
            disp(matchInfo(ii).error);
            continue;
        end
    else
        if hasSamplingB
            matchInfo(ii).error = ...
                'Data file B has a spectral sampling "S" but A does not!';
            disp(matchInfo(ii).error);
            continue;
        else
            matchInfo(ii).error = ...
                'Neither data file A nor B has spectral sampling "S" -- skipping.';
            continue;
        end
    end
    matchInfo(ii).samplingA = dataA.S;
    matchInfo(ii).samplingB = dataB.S;
    
    % do spectral samplings agree?
    if ~isequal(dataA.S, dataB.S)
        matchInfo(ii).error = ...
            sprintf('Spectral sampling A[%s] is not the same as B[%s].', ...
            num2str(dataA.S), num2str(dataB.S));
        disp(matchInfo(ii).error);
        % proceed with comparison, despite sampling mismatch
    end
    
    % tolerate different sectral sampling depths
    [A, B] = truncatePlanes(multispectralA, multispectralB, dataA.S, dataB.S);
    
    % comparison passes all sanity checks
    matchInfo(ii).isGoodComparison = true;
    
    % compute per-pixel component difference stats
    normA = A / max(A(:));
    normB = B / max(B(:));
    normDiff = normA - normB;
    absNormDiff = abs(normDiff);
    relNormDiff = absNormDiff ./ normA;
    cutoff = matchInfo(ii).denominatorThreshold;
    relNormDiff(normA < cutoff) = nan;
    
    % summarize differnece stats
    matchInfo(ii).subpixelsA = summarizeData(A);
    matchInfo(ii).subpixelsB = summarizeData(B);
    matchInfo(ii).normA = summarizeData(normA);
    matchInfo(ii).normB = summarizeData(normB);
    matchInfo(ii).normDiff = summarizeData(normDiff);
    matchInfo(ii).absNormDiff = summarizeData(absNormDiff);
    matchInfo(ii).relNormDiff = summarizeData(relNormDiff);
    
    % compute correlation among pixel components
    r = corrcoef(A(:), B(:));
    matchInfo(ii).corrcoef = r(1, 2);
    
    % plot difference image?
    if visualize > 1
        f = showDifferenceImage(matchInfo(ii), A, B);
        matchInfo(ii).detailFigure = f;
        
        % save detail figure to disk
        drawnow();
        [imagePath, imageName] = fileparts(matchInfo(ii).relativePathA);
        imageCompPath = fullfile(figureFolder, imagePath);
        if ~exist(imageCompPath, 'dir')
            mkdir(imageCompPath);
        end
        figName = fullfile(imageCompPath, [imageName '.fig']);
        saveas(f, figName, 'fig');
        pngName = fullfile(imageCompPath, [imageName '.png']);
        saveas(f, pngName, 'png');
        
        close(f);
    end
end

nComparisons = sum([matchInfo.isGoodComparison]);
nSkipped = nMatches - nComparisons;
fprintf('Compared %d pairs of data files.\n', nComparisons);
fprintf('Skipped %d pairs of data files, which is not necessarily a problem.\n', nSkipped);

% plot a grand summary?
if visualize > 0
    f = showDifferenceSummary(matchInfo);
    
    % save summary figure to disk
    if ~exist(figureFolder, 'dir')
        mkdir(figureFolder);
    end
    imageName = sprintf('%s-summary', mfilename());
    figName = fullfile(figureFolder, [imageName '.fig']);
    saveas(f, figName, 'fig');
    
    % some platforms can't pring uicontrols
    controls = findobj(f, 'Type', 'uicontrol');
    set(controls, 'Visible', 'off');
    pngName = fullfile(figureFolder, [imageName '.png']);
    saveas(f, pngName, 'png');
    set(controls, 'Visible', 'on');
end

if visualize > 1
    fprintf('\nSee comparison images saved in:\n  %s\n', figureFolder);
end


% Scan paths for expected parts:
%   root/recipeName/subfolderName/rendererName/fileName.extension
function info = scanDataPaths(paths)
n = numel(paths);
rootPath = cell(1, n);
relativePath = cell(1, n);
recipeName = cell(1, n);
subfolderName = cell(1, n);
rendererName = cell(1, n);
fileName = cell(1, n);
fileNumber = cell(1, n);
hasNumber = false(1, n);
matchToken = cell(1, n);
for ii = 1:n
    % break off the file name
    [parentPath, baseName, extension] = fileparts(paths{ii});
    fileName{ii} = [baseName extension];
    if numel(baseName) >= 4
        fileNumber{ii} = sscanf(baseName(end-3:end), '-%d');
    end
    hasNumber(ii) = ~isempty(fileNumber{ii});
    
    % break out subfolder names
    scanResult = textscan(parentPath, '%s', 'Delimiter', filesep());
    tokens = scanResult{1};
    
    % is there a renderer folder?
    if any(strcmp(tokens{end}, {'PBRT', 'Mitsuba'}))
        rendererName{ii} = tokens{end};
        subfolderNameIndex = numel(tokens) - 1;
    else
        rendererName{ii} = '';
        subfolderNameIndex = numel(tokens);
    end
    
    % get the named subfolder name
    subfolderName{ii} = tokens{subfolderNameIndex};
    
    % get the recipe name
    recipeName{ii} = tokens{subfolderNameIndex-1};
    
    % get the root path
    rootPath{ii} = fullfile(tokens{1:subfolderNameIndex-2});
    
    % build the rootless relative path
    relativePath{ii} = fullfile(recipeName{ii}, subfolderName{ii}, ...
        rendererName{ii}, fileName{ii});
    
    % build a token for matching across file sets
    if strncmp(recipeName{ii}, 'rtb', 3)
        nameBase = recipeName{ii}(4:end);
    else
        nameBase = recipeName{ii};
    end
    matchTokenBase = [nameBase '-' subfolderName{ii} '-' rendererName{ii} '-'];
    if hasNumber(ii)
        matchToken{ii} = [matchTokenBase sprintf('%03d', fileNumber{ii})];
    else
        matchToken{ii} = [matchTokenBase baseName];
    end
end

info = struct( ...
    'original', paths, ...
    'fileName', fileName, ...
    'fileNumber', fileNumber, ...
    'hasNumber', hasNumber, ...
    'rendererName', rendererName, ...
    'recipeName', recipeName, ...
    'subfolderName', subfolderName, ...
    'rootPath', rootPath, ...
    'relativePath', relativePath, ...
    'matchToken', matchToken);


% Show sRGB images and sRGB difference images
function f = showDifferenceImage(info, A, B)

% make SRGB images
[A, B, S] = truncatePlanes(A, B, info.samplingA, info.samplingB);
isScale = true;
toneMapFactor = 0;
imageA = rtbMultispectralToSRGB(A, S, 'toneMapFactor', toneMapFactor, 'isScale', isScale);
imageB = rtbMultispectralToSRGB(B, S, 'toneMapFactor', toneMapFactor, 'isScale', isScale);
imageAB = rtbMultispectralToSRGB(A-B, S, 'toneMapFactor', toneMapFactor, 'isScale', isScale);
imageBA = rtbMultispectralToSRGB(B-A, S, 'toneMapFactor', toneMapFactor, 'isScale', isScale);

% show images in a new figure
name = sprintf('sRGB scaled: %s', info.matchTokenA);
f = figure('Name', name, 'NumberTitle', 'off');

ax = subplot(2, 2, 2, 'Parent', f);
imshow(uint8(imageA), 'Parent', ax);
title(ax, ['A: ' info.workingFolderA]);

ax = subplot(2, 2, 3, 'Parent', f);
imshow(uint8(imageB), 'Parent', ax);
title(ax, ['B: ' info.workingFolderB]);

ax = subplot(2, 2, 1, 'Parent', f);
imshow(uint8(imageAB), 'Parent', ax);
title(ax, 'Difference: A - B');

ax = subplot(2, 2, 4, 'Parent', f);
imshow(uint8(imageBA), 'Parent', ax);
title(ax, 'Difference: B - A');


% Truncate spectral planes if one image has more planes.
function [truncA, truncB, truncSampling] = truncatePlanes(A, B, samplingA, samplingB)
nPlanes = min(samplingA(3), samplingB(3));
truncSampling = [samplingA(1:2) nPlanes];
truncA = A(:,:,1:nPlanes);
truncB = B(:,:,1:nPlanes);


% Show a summary of all difference images.
function f = showDifferenceSummary(info)
figureName = sprintf('A: %s vs B: %s', ...
    info(1).workingFolderA, info(1).workingFolderB);
f = figure('Name', figureName, 'NumberTitle', 'off');

% summarize only fair comparisions
goodInfo = info([info.isGoodComparison]);

% sort the summary by size of error
diffSummary = [goodInfo.relNormDiff];
errorStat = [diffSummary.max];
[~, order] = sort(errorStat);
goodInfo = goodInfo(order);

% summarize data correlation coefficients
minCorr = 0.85;
peggedCorr = 0.8;
corrTicks = [peggedCorr minCorr:0.05:1];
corrTickLabels = num2cell(corrTicks);
corrTickLabels{1} = sprintf('<%.2f', minCorr);
corr = [goodInfo.corrcoef];
corr(corr < minCorr) = peggedCorr;

names = {goodInfo.matchTokenA};
nLines = numel(names);
ax(1) = subplot(1, 3, 2, ...
    'Parent', f, ...
    'YTick', 1:nLines, ...
    'YTickLabel', names, ...
    'YGrid', 'on', ...
    'XLim', [corrTicks(1), corrTicks(end)], ...
    'XTick', corrTicks, ...
    'XTickLabel', corrTickLabels);
line(corr, 1:nLines, ...
    'Parent', ax(1), ...
    'LineStyle', 'none', ...
    'Marker', 'o', ...
    'Color', [0 0 1])
title(ax(1), 'correlation');

% summarize mean and max subpixel differences
maxDiff = 2.5;
peggedDiff = 3;
diffTicks = [0:0.5:maxDiff peggedDiff];
diffTickLabels = num2cell(diffTicks);
diffTickLabels{end} = sprintf('>%.2f', maxDiff);

diffSummary = [goodInfo.relNormDiff];
maxes = [diffSummary.max];
means = [diffSummary.mean];
maxes(maxes > maxDiff) = peggedDiff;
means(means > maxDiff) = peggedDiff;
ax(2) = subplot(1, 3, 3, ...
    'Parent', f, ...
    'YTick', 1:nLines, ...
    'YTickLabel', 1:nLines, ...
    'YAxisLocation', 'right', ...
    'YGrid', 'on', ...
    'XLim', [diffTicks(1), diffTicks(end)], ...
    'XTick', diffTicks, ...
    'XTickLabel', diffTickLabels);
line(maxes, 1:nLines, ...
    'Parent', ax(2), ...
    'LineStyle', 'none', ...
    'Marker', '+', ...
    'Color', [1 0 0])
line(means, 1:nLines, ...
    'Parent', ax(2), ...
    'LineStyle', 'none', ...
    'Marker', 'o', ...
    'Color', [0 0 0])
legend(ax(2), 'max', 'mean', 'Location', 'northeast');
title(ax(2), 'relative diff');

% let the user scroll both axes at the same time
nLinesAtATime = 25;
scrollerData.axes = ax;
scrollerData.nLinesAtATime = nLinesAtATime;
scroller = uicontrol( ...
    'Parent', f, ...
    'Units', 'normalized', ...
    'Position', [.95 0 .05 1], ...
    'Callback', @scrollSummaryAxes, ...
    'Min', 1, ...
    'Max', max(2, nLines), ...
    'Value', nLines, ...
    'Style', 'slider', ...
    'SliderStep', [1 2], ...
    'UserData', scrollerData);
scrollSummaryAxes(scroller, []);

% resize to fit image names
w = 1000;
p = get(f, 'Position');
p(3) = w;
set(f, 'Position', p);



% Summarize a distribuition of data with a struct of stats.
function summary = summarizeData(data)
finiteData = data(isfinite(data));
summary.min = min(finiteData);
summary.mean = mean(finiteData);
summary.max = max(finiteData);


% Scroll summary axes together.
function scrollSummaryAxes(object, event)
scrollerData = get(object, 'UserData');
topLine = get(object, 'Value');
yLimit = topLine + [-scrollerData.nLinesAtATime 1];
set(scrollerData.axes, 'YLim', yLimit);
