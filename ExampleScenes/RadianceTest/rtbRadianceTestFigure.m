%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
%% Make a figure with data about renderer film units.

%% Render the scene.
rtbMakeRadianceTest;

%% Get multi-spectral data each sphere rendering.

% look in the conditions file for image names
conditionsFile = 'RadianceTestConditions.txt';
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
hints.recipeName = 'rtbMakeRadianceTest';
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
maxSRGB = .95;

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
set(fig, 'Name', 'RadianceTest', 'UserData', 'RadianceTest');
labelSize = 14;

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
powerLevels = (referenceMax/4)*(0:4);

% label image slices
pbrtColor = [1 0.5 0];
pbrtMarker = 'square';
mitsubaColor = [0 0 1];
mitsubaMarker = '+';
for ii = 1:nImages
    plotCount = 1 + 3*(ii-1);
    
    % PBRT image
    tag = sprintf('PBRT-%s', pbrt(ii).imageName);
    axPBRT = subplot(nImages, 3, plotCount, ...
        'Parent', fig);
    imshow(uint8(pbrt(ii).imageSRGB), 'Parent', axPBRT);
    set(axPBRT, 'UserData', tag);
    
    % Mitsuba image
    tag = sprintf('Mitsuba-%s', pbrt(ii).imageName);
    axMitsuba = subplot(nImages, 3, plotCount + 1, ...
        'Parent', fig);
    imshow(uint8(mitsuba(ii).imageSRGB), 'Parent', axMitsuba);
    set(axMitsuba, 'UserData', tag);
    
    % slice through the middle of each image
    pbrtSize = size(pbrt(ii).imageSpectral);
    sliceRow = round(pbrtSize(1)/2);
    slicePBRT = pbrt(ii).imageSpectral(sliceRow, :, sliceBand) * pbrt(ii).scaleSRGB;
    
    mitsubaSize = size(mitsuba(ii).imageSpectral);
    sliceRow = round(mitsubaSize(1)/2);
    sliceMitsuba = mitsuba(ii).imageSpectral(sliceRow, :, sliceBand) * mitsuba(ii).scaleSRGB;
    
    % choose pixel tick marks along the slices
    quarter = floor(pbrtSize(2)/4);
    pixelTicks = [1  quarter 2*quarter 3*quarter pbrtSize(2)];
    
    % plots of power
    axPower = subplot(nImages, 3, plotCount + 2, ...
        'Parent', fig, ...
        'UserData', pbrt(ii).imageName, ...
        'YLim', [0 grandMax*1.1], ...
        'YTick', powerLevels, ...
        'YGrid', 'on', ...
        'YTickLabel', {}, ...
        'XLim', [0 pbrtSize(2)+1], ...
        'XTick', pixelTicks, ...
        'XTickLabel', {});
    line(1:pbrtSize(2), slicePBRT, ...
        'Parent', axPower, ...
        'Marker', pbrtMarker, ...
        'MarkerSize', 7, ...
        'Color', pbrtColor, ...
        'LineStyle', 'none');
    line(1:mitsubaSize(2), sliceMitsuba, ...
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
        line([0 pbrtSize(2) + 1], sliceRow*[1 1], ...
            'Parent', axPBRT, ...
            'Color', pbrtColor, ...
            'LineStyle', ':', ...
            'LineWidth', 2, ...
            'Marker', 'none');
        line([0 pbrtSize(2) + 1], sliceRow*[1 1], ...
            'Parent', axMitsuba, ...
            'Color', mitsubaColor, ...
            'LineStyle', ':', ...
            'LineWidth', 2, ...
            'Marker', 'none');
        
        % slice power
        powerText = sprintf('%dnm power', wls(sliceBand));
        title(axPower, powerText, 'FontSize', labelSize);
        set(axPower, ...
            'YTickLabel', {'0', '1/4', '1/2', '3/4', 'reference max'});
    end
    
    if nImages == ii
        set(axPower, ...
            'XTickLabel', pixelTicks);
        xlabel(axPower, 'image column (pixels)')
    end
    
    y = ylabel(axPBRT, pbrt(ii).imageName, ...
        'Rotation', 0, ...
        'HorizontalAlignment', 'right', ...
        'FontSize', labelSize);
end

% resize the figure to show images at native size
pos = get(fig, 'Position');
pos(3:4) = [850 1125];
set(fig, 'Position', pos);
