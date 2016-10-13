%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
%% Make a figure with data about renderer output absolute magnitudes.

%% Render the scene.
rtbMakeScalingTest;

%% Get multi-spectral data each sphere rendering.

% look in the conditions file for image names
conditionsFile = 'ScalingTestConditions.txt';
[names, values] = rtbParseConditions(conditionsFile);
imageNames = values(:, strcmp('imageName', names));
nImages = numel(imageNames);

% allocate structs of data and computations
pbrt = struct( ...
    'imageName', imageNames, ...
    'imageSpectral', [], ...
    'maxSpectral', [], ...
    'scaleSRGB', [], ...
    'imageSRGB', [], ...
    'S', []);
mitsuba = pbrt;

% fill in multi-spectral data for each condition
hints.recipeName = 'rtbMakeScalingTest';
for ii = 1:nImages
    % read PBRT data for this condition
    hints.renderer = 'PBRT';
    dataFolder = rtbWorkingFolder( ...
        'folderName', 'renderings', ...
        'rendererSpecific', true, ...
        'hints', hints);
    file = rtbFindFiles('root', dataFolder, 'filter', [imageNames{ii} '.mat']);
    data = load(file{1});
    pbrt(ii).imageSpectral = data.multispectralImage;
    pbrt(ii).maxSpectral = max(data.multispectralImage(:));
    pbrt(ii).S = data.S;
    
    % read Mitsuba data for this condition
    hints.renderer = 'Mitsuba';
    dataFolder = rtbWorkingFolder( ...
        'folderName', 'renderings', ...
        'rendererSpecific', true, ...
        'hints', hints);
    file = rtbFindFiles('root', dataFolder, 'filter', [imageNames{ii} '.mat']);
    data = load(file{1});
    mitsuba(ii).imageSpectral = data.multispectralImage;
    mitsuba(ii).maxSpectral = max(data.multispectralImage(:));
    mitsuba(ii).S = data.S;
end

%% Determine scaling to convert multi-spectral data to nice sRGB.
% let the maximum power of the first image correspond to medium gray
maxSRGB = .25;

% scale for PBRT
tinyImage = pbrt(1).maxSpectral * ones(1, 1, pbrt(1).S(3));
[sRGB, XYZ, rawRGB] = rtbMultispectralToSRGB(tinyImage, pbrt(1).S);
scale = maxSRGB / max(rawRGB(:));
[pbrt.scaleSRGB] = deal(scale);

% scale for Mitsuba
tinyImage = mitsuba(1).maxSpectral * ones(1, 1, mitsuba(1).S(3));
[sRGB, XYZ, rawRGB] = rtbMultispectralToSRGB(tinyImage, mitsuba(1).S);
scale = maxSRGB / max(rawRGB(:));
[mitsuba.scaleSRGB] = deal(scale);

%% Convert images to XYZ and sRGB.
for ii = 1:nImages
    % PBRT image
    imageSpectral = pbrt(ii).imageSpectral * pbrt(ii).scaleSRGB;
    pbrt(ii).imageSRGB = rtbMultispectralToSRGB(imageSpectral, pbrt(ii).S);
    
    % Mitsuba image
    imageSpectral = mitsuba(ii).imageSpectral * mitsuba(ii).scaleSRGB;
    mitsuba(ii).imageSRGB = rtbMultispectralToSRGB(imageSpectral, mitsuba(ii).S);
end


%% Show images and plots in a figure.
fig = figure();
clf(fig);
set(fig, 'Name', 'ScalingTest');
labelSize = 14;

% choose where to slice through each image
sliceHeight = 0.33;

wls = MakeItWls(pbrt(1).S);
nBands = numel(wls);
sliceBand = 13;

% choose power levels of interest
referenceMax = pbrt(1).maxSpectral * pbrt(1).scaleSRGB;
pbrtMaxMax = max([pbrt.maxSpectral]);
mitsubaMaxMax = max([mitsuba.maxSpectral]);
grandMax = max([ ...
    pbrtMaxMax * pbrt(1).scaleSRGB, ...
    mitsubaMaxMax * mitsuba(1).scaleSRGB]);
powerLevels = referenceMax*(0:4);

% label image slices
pbrtColor = [1 0.5 0];
pbrtMarker = 'square';
mitsubaColor = [0 0 1];
mitsubaMarker = '+';
for ii = 1:nImages
    plotCount = 1 + 3*(ii-1);
    
    % choose the image row to slice
    imageHeight = size(pbrt(ii).imageSpectral, 1);
    imageWidth = size(pbrt(ii).imageSpectral, 2);
    sliceRow = floor(sliceHeight*imageHeight);
    
    % PBRT image
    axPBRT = subplot(nImages, 3, plotCount, ...
        'Parent', fig);
    imshow(uint8(pbrt(ii).imageSRGB), 'Parent', axPBRT);
    
    % Mitsuba image
    axMitsuba = subplot(nImages, 3, plotCount + 1, ...
        'Parent', fig);
    imshow(uint8(mitsuba(ii).imageSRGB), 'Parent', axMitsuba);
    
    % plots of power
    sliceCols = 1:imageWidth;
    slicePBRT = pbrt(ii).imageSpectral(sliceRow, sliceCols, sliceBand) * pbrt(ii).scaleSRGB;
    sliceMitsuba = mitsuba(ii).imageSpectral(sliceRow, sliceCols, sliceBand) * mitsuba(ii).scaleSRGB;
    axPower = subplot(nImages, 3, plotCount + 2, ...
        'Parent', fig, ...
        'YLim', [0 grandMax*1.1], ...
        'YTick', powerLevels, ...
        'YGrid', 'on', ...
        'YTickLabel', {}, ...
        'XLim', [0 imageWidth + 1]);
    line(1:imageWidth, slicePBRT, ...
        'Parent', axPower, ...
        'Marker', pbrtMarker, ...
        'MarkerSize', 7, ...
        'Color', pbrtColor, ...
        'LineStyle', 'none');
    line(1:imageWidth, sliceMitsuba, ...
        'Parent', axPower, ...
        'Marker', mitsubaMarker, ...
        'MarkerSize', 5, ...
        'Color', mitsubaColor, ...
        'LineStyle', 'none');
    
    % annotate outside plots
    if 1 == ii
        title(axPBRT, 'PBRT', 'FontSize', labelSize);
        title(axMitsuba, 'Mitsuba', 'FontSize', labelSize);
        
        % image slices
        line([0 imageWidth + 1], sliceRow*[1 1], ...
            'Parent', axPBRT, ...
            'Color', pbrtColor, ...
            'LineStyle', ':', ...
            'LineWidth', 2, ...
            'Marker', 'none');
        line([0 imageWidth + 1], sliceRow*[1 1], ...
            'Parent', axMitsuba, ...
            'Color', mitsubaColor, ...
            'LineStyle', ':', ...
            'LineWidth', 2, ...
            'Marker', 'none');
        
        % slice power
        powerText = sprintf('%dnm power', wls(sliceBand));
        title(axPower, powerText, 'FontSize', labelSize);
        set(axPower, ...
            'YTickLabel', {'0', 'reference max', 'x2', 'x3', 'x4'})
    end
    
    y = ylabel(axPBRT, pbrt(ii).imageName, ...
        'Rotation', 0, ...
        'HorizontalAlignment', 'right', ...
        'FontSize', labelSize);
end

% resize the figure to show images at native size
pos = get(fig, 'Position');
pos(3:4) = [850 750];
set(fig, 'Position', pos);

% save the figure as an image file
figureFolder = rtbWorkingFolder( ...
    'folderName', 'images', ...
    'hints', hints);
figureFile = fullfile(figureFolder, [hints.recipeName '.png']);
saveas(fig, figureFile);
