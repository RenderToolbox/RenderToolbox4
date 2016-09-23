%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
%% Probe the RGB spectral promotion algortigms of renderers.

%% Move to temp folder before creating new files.
hints = rtbDefaultHints();
hints.recipeName = mfilename();

resources = rtbWorkingFolder('folderName', 'resources', 'hints', hints);

%% Choose some illuminants and RGB colors to render
% yellow daylight
cieInfo = load('B_cieday');

temp = 4000;
spd = GenerateCIEDay(temp, cieInfo.B_cieday);
wls = SToWls(cieInfo.S_cieday);
yellowDay = rtbWriteSpectrumFile(wls, spd, fullfile(resources, sprintf('CIE-day-%d.spd', temp)));

% blue daylight
temp = 10000;
spd = GenerateCIEDay(temp, cieInfo.B_cieday);
wls = SToWls(cieInfo.S_cieday);
blueDay = rtbWriteSpectrumFile(wls, spd, fullfile(resources, sprintf('CIE-day-%d.spd', temp)));

illuminants = {yellowDay, blueDay};
RGBs = {[0.8, 0.1, 0.3], [1 0 0], [0 1 0], [0 0 1], [1 1 1], [1 1 1], 0.5*[1 1 1]};
RGBNames = {'irregular', 'red', 'green', 'blue', 'white', 'sum', 'gray'};


%% Get RGB promotions from PBRT and Mitsuba
renderers = {'Mitsuba', 'PBRT'};
nRenderers = numel(renderers);
nIlluminants = numel(illuminants);
nRGBs = numel(RGBs);
promotions = cell(nRenderers, nIlluminants, nRGBs);
SOuts = cell(nRenderers, nIlluminants, nRGBs);
RGBOuts = cell(nRenderers, nIlluminants, nRGBs);
dataFiles = cell(nRenderers, nIlluminants, nRGBs);
for rend = 1:nRenderers
    for illum = 1:nIlluminants
        for rgb = 1:nRGBs
            hints.renderer = renderers{rend};
            
            if strcmp('sum', RGBNames{rgb})
                % build the "sum" condition out of red, green, and blue
                promoted = promotions{rend, illum, 2} ...
                    + promotions{rend, illum, 3} ...
                    + promotions{rend, illum, 4};
                S = SOuts{1};
                RGB = RGBOuts{rend, illum, 2} ...
                    + RGBOuts{rend, illum, 3} ...
                    + RGBOuts{rend, illum, 4};
                dataFile = '';
            else
                [promoted, S, RGB, dataFile] = rtbPromoteRGBReflectance(RGBs{rgb}, ...
                    'illuminant', illuminants{illum}, ...
                    'hints', hints);
            end
            
            promotions{rend, illum, rgb} = promoted;
            SOuts{rend, illum, rgb} = S;
            RGBOuts{rend, illum, rgb} = RGB;
            dataFiles{rend, illum, rgb} = dataFile;
        end
    end
end

%% Plot RGB, and promoted spectra.
close all
hints = rtbDefaultHints();
RGBMarkers = {'x', 'o'};
RGBOutMarkers = {'+', 'square'};
spectrumMarkers = {'x', 'o'};
RGBLegend = {};
labelSize = 14;
fig = figure();
nCols = nIlluminants * 2;
nRows = nRGBs;
for illum = 1:nIlluminants
    for rgb = 1:nRGBs
        % for plotting RGB values
        row = rgb;
        sp = (2*illum-1) + (rgb-1)*nCols;
        maxReflectance = 1.25;
        axRGB = subplot(nRows, nCols, sp, ...
            'Parent', fig, ...
            'YLim', [0 maxReflectance], ...
            'YTick', [0 0.5 1], ...
            'YGrid', 'on', ...
            'XLim', [.9 3.1], ...
            'XTick', 1:3, ...
            'XTickLabel', {});
        
        % for plotting promoted spectra
        outWls = MakeItWls(SOuts{1, illum, rgb});
        axSpectra = subplot(nRows, nCols, sp+1, ...
            'Parent', fig, ...
            'YLim', [0 maxReflectance], ...
            'YTick', [0 0.5 1], ...
            'YGrid', 'on', ...
            'YAxisLocation', 'right', ...
            'XLim', [min(outWls) max(outWls)] + [-.1 .1], ...
            'XTick', [min(outWls) max(outWls)], ...
            'XTickLabel', {}, ...
            'XDir', 'reverse');
        
        % label outside plots
        if 1 == rgb
            [illumPath, illumName] = fileparts(illuminants{illum});
            title(axRGB, sprintf('%s: RGB', illumName), ...
                'FontSize', labelSize);
            title(axSpectra, 'promoted', ...
                'FontSize', labelSize);
        end
        
        if nRGBs == rgb
            set(axRGB, 'XTickLabel', {'R', 'G', 'B'});
            xlabel(axRGB, 'component', 'FontSize', labelSize);
            set(axSpectra, 'XTickLabel', [min(outWls) max(outWls)])
            xlabel(axSpectra, 'wavelength (nm)', 'FontSize', labelSize);
            
            if nIlluminants == illum
                ylabel(axSpectra, 'reflectance', 'FontSize', labelSize);
            end
        end
        
        if 1 == illum
            ylabel(axRGB, RGBNames{rgb}, 'FontSize', labelSize);
        end
        
        for rend = 1:nRenderers
            % plot original RGB
            plotColor = RGBs{rgb};
            line(1:3, RGBs{rgb}, ...
                'Parent', axRGB, ...
                'Color', plotColor, ...
                'Marker', RGBMarkers{rend}, ...
                'LineStyle', 'none');
            
            % plot recovered RGB
            line(1:3, RGBOuts{rend, illum, rgb}, ...
                'Parent', axRGB, ...
                'Color', plotColor, ...
                'Marker', RGBOutMarkers{rend}, ...
                'LineStyle', 'none');
            
            % plot promoted spectra
            line(outWls, promotions{rend, illum, rgb}, ...
                'Parent', axSpectra, ...
                'Color', plotColor, ...
                'Marker', spectrumMarkers{rend}, ...
                'LineStyle', 'none');
            
            % plot white points on a dark background
            if all(plotColor > 0.9)
                set([axRGB axSpectra], 'Color', 0.5*[1 1 1]);
            end
            
            % remember RGB legend info
            rgbIndex = (rend-1)*nRenderers;
            RGBLegend{rgbIndex+1} = sprintf('%s in', renderers{rend});
            RGBLegend{rgbIndex+2} = sprintf('%s out', renderers{rend});
        end
    end
end

% resize the figure before messing with legend positions
set(fig, 'Position', [0 0 1000, 1000]);

% put legends on the last axes
%   move clear of plotted points
l = legend(axRGB, RGBLegend, 'Location', 'southeast');
set(l, 'Position', get(l, 'Position') + [0 0.01 0 0]);
l = legend(axSpectra, renderers, 'Location', 'southwest');
set(l, 'Position', get(l, 'Position') + [0 0.01 0 0]);
