%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
%% Make a figure with data about light reflecting between surfaces.

%% Render the scene.
rtbMakeInterreflection;

%% Get multi-spectral data from each interreflection rendering.

% look in the conditions file for image names
conditionsFile = 'InterreflectionConditions.txt';
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
hints.recipeName = 'rtbMakeInterreflection';
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
% let the maximum power of the first image correspond to white
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

%% Make montages of cropped white panels.
% choose how to crop the white panel
imageHeight = size(pbrt(1).imageSpectral, 1);
imageWidth = size(pbrt(1).imageSpectral, 2);
cropCol = ceil(0.52*imageWidth);
cropRow = ceil(0.25*imageHeight);
cropWidth = floor(0.1*imageWidth);
cropY = cropRow + (1:cropWidth);
cropX = cropCol + (1:cropWidth);

% montages are 3 units tall and 1 wide
pbrtMontage = zeros(3*cropWidth , cropWidth, 3);
mitsubaMontage = zeros(3*cropWidth , cropWidth, 3);

% fill in montages with cropped images
for ii = 1:nImages
    % extract the cropped white panel from PBRT
    montageY = (ii-1)*cropWidth + (1:cropWidth);
    montageX = 1:cropWidth;
    pbrtMontage(montageY, montageX, :) = ...
        pbrt(ii).imageSRGB(cropY, cropX, :);
    
    % extract the cropped white panel from Mitsuba
    mitsubaMontage(montageY, montageX, :) = ...
        mitsuba(ii).imageSRGB(cropY, cropX, :);
end

% show white stripes in the montage for reference
stripeValue = round(255*maxSRGB);
stripeY = [1 1+cropWidth*(1:3)];
stripeX = [1 cropWidth];
pbrtMontage(stripeY, :, :) = stripeValue;
mitsubaMontage(stripeY, :, :) = stripeValue;
pbrtMontage(:, stripeX, :) = stripeValue;
mitsubaMontage(:, stripeX, :) = stripeValue;

%% Show images and plots in a figure.
fig = figure();
clf(fig);
set(fig, 'Name', 'Interreflection');
labelSize = 14;

% choose where to slice through each image
sliceHeight = 0.5;
sliceRow = floor(sliceHeight*imageHeight);

wls = MakeItWls(pbrt(1).S);
nBands = numel(wls);
sliceBands = [6 26];
sliceColors = {[0 0 1], [1 0 0]};
sliceMarkerSizes = [8 4];
sliceNames = cell(2, numel(sliceBands));

% choose power levels of interest
referenceMax = pbrt(1).maxSpectral * pbrt(1).scaleSRGB;
pbrtMaxMax = max([pbrt.maxSpectral]);
mitsubaMaxMax = max([mitsuba.maxSpectral]);
grandMax = max([ ...
    pbrtMaxMax * pbrt(1).scaleSRGB, ...
    mitsubaMaxMax * mitsuba(1).scaleSRGB]);
powerLevels = referenceMax*[0 1];

% label image slices
pbrtColor = [1 0.5 0];
pbrtMarker = 'square';
mitsubaColor = [0 0 1];
mitsubaMarker = '+';
for ii = 1:nImages
    plotCount = 1 + 3*(ii-1);
    
    % PBRT sRGB image
    axPBRT = subplot(1+nImages, 3, plotCount, ...
        'Parent', fig);
    imshow(uint8(pbrt(ii).imageSRGB), 'Parent', axPBRT);
    
    % Mitsuba sRGB image
    axMitsuba = subplot(1+nImages, 3, plotCount + 1, ...
        'Parent', fig);
    imshow(uint8(mitsuba(ii).imageSRGB), 'Parent', axMitsuba);
    
    % plots of power
    axPower = subplot(1+nImages, 3, plotCount + 2, ...
        'Parent', fig, ...
        'YLim', [0 grandMax*1.1], ...
        'YTick', powerLevels, ...
        'YGrid', 'on', ...
        'YTickLabel', {}, ...
        'XLim', [0 imageWidth + 1]);
    sliceCols = 1:imageWidth;
    for jj = 1:numel(sliceBands)
        band = sliceBands(jj);
        slicePBRT = pbrt(ii).imageSpectral(sliceRow, sliceCols, band) * pbrt(ii).scaleSRGB;
        sliceMitsuba = mitsuba(ii).imageSpectral(sliceRow, sliceCols, band) * mitsuba(ii).scaleSRGB;
        line(1:imageWidth, slicePBRT, ...
            'Parent', axPower, ...
            'Marker', pbrtMarker, ...
            'MarkerSize', sliceMarkerSizes(jj)-1, ...
            'Color', sliceColors{jj}, ...
            'LineStyle', 'none');
        line(1:imageWidth, sliceMitsuba, ...
            'Parent', axPower, ...
            'Marker', mitsubaMarker, ...
            'MarkerSize', sliceMarkerSizes(jj)+1, ...
            'Color', sliceColors{jj}, ...
            'LineStyle', 'none');
        
        sliceNames{1, jj} = sprintf('%dnm PBRT', wls(band));
        sliceNames{2, jj} = sprintf('%dnm Mitsuba', wls(band));
    end
    
    % annotate outside plots
    if 1 == ii
        title(axPBRT, 'PBRT', 'FontSize', labelSize);
        title(axMitsuba, 'Mitsuba', 'FontSize', labelSize);
        
        % show where spectral power slices were taken
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
        
        % show where the white panels were cropped
        cropBoxX = [cropX(1) cropX(end) cropX(end) cropX(1) cropX(1)];
        cropBoxY = [cropY(1) cropY(1) cropY(end) cropY(end) cropY(1)];
        line(cropBoxX, cropBoxY, ...
            'Parent', axPBRT, ...
            'Color', pbrtColor, ...
            'LineStyle', '-', ...
            'LineWidth', 1, ...
            'Marker', 'none');
        line(cropBoxX, cropBoxY, ...
            'Parent', axMitsuba, ...
            'Color', mitsubaColor, ...
            'LineStyle', '-', ...
            'LineWidth', 1, ...
            'Marker', 'none');
        
        % slice power
        title(axPower, 'Spectral Power')
        maxText = sprintf('reference max');
        set(axPower, ...
            'YTickLabel', {'0', maxText})
    end
    
    if ii == nImages
        % make a spectral power legend and move it to an empty space
        drawnow();
        leg = legend(axPower, sliceNames{:}, ...
            'Location', 'southwest');
        pos = get(leg, 'Position');
        pos(2) = pos(2) - 0.15;
        set(leg, 'Position', pos);
    end
    
    y = ylabel(axPBRT, pbrt(ii).imageName, ...
        'Rotation', 0, ...
        'HorizontalAlignment', 'right', ...
        'FontSize', labelSize);
end

% show the PBRT cropped white panels
axCrop = subplot(1+nImages, 3, 1 + nImages*3, ...
    'Parent', fig);
imshow(uint8(pbrtMontage), 'Parent', axCrop);

% label the croppings
labelX = -10;
labelY = cropWidth/2 + (0:2)*cropWidth;
for ii = 1:nImages
    text(labelX, labelY(ii), imageNames{ii}, ...
        'Parent', axCrop, ...
        'HorizontalAlignment', 'right', ...
        'FontSize', labelSize);
end

% show the Mitsuba cropped white panels
axCrop = subplot(1+nImages, 3, 2 + nImages*3, ...
    'Parent', fig);
imshow(uint8(mitsubaMontage), 'Parent', axCrop);

% resize the figure to show images at native size
drawnow();
pos = get(fig, 'Position');
pos(3:4) = [880 650];
set(fig, 'Position', pos);
