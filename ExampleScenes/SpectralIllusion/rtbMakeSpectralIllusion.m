%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
%% Render the SpectralIllusion scene, with sampled spectra on a cube.

%% Choose example files, make sure they're on the Matlab path.
parentSceneFile = 'SpectralIllusion.dae';
mappingsFile = 'SpectralIllusionMappings.json';
initialConditionsFile = 'SpectralIllusionConditionsInitial.txt';
cleverConditionsFile = 'SpectralIllusionConditionsClever.txt';


%% Choose batch renderer options.
hints.renderer = 'Mitsuba';
hints.fov = 49.13434 * pi() / 180;
hints.imageWidth = 640;
hints.imageHeight = 480;
hints.recipeName = 'rtbMakeSpectralIllusion';

toneMapFactor = 100;
isScale = true;


%% Write some initial spectrum files.
resources = rtbWorkingFolder('folderName', 'resources', 'hints', hints);

% get basis CIE daylight basis vectors
cieInfo = load('B_cieday');

% make the bright yellow sun
temp = 4000;
scale = 1;
spd = scale * GenerateCIEDay(temp, cieInfo.B_cieday);
wls = SToWls(cieInfo.S_cieday);
rtbWriteSpectrumFile(wls, spd, fullfile(resources, sprintf('CIE-daylight-%d.spd', temp)));

% make the dimmer blue sky
temp = 10000;
scale = 0.001;
spd = scale * GenerateCIEDay(temp, cieInfo.B_cieday);
wls = SToWls(cieInfo.S_cieday);
rtbWriteSpectrumFile(wls, spd, fullfile(resources, sprintf('CIE-daylight-%d.spd', temp)));

% make a target reflectance that is not too bright
originalSpectrum = 'mccBabel-11.spd';
[wls, originalReflect] = rtbReadSpectrum(originalSpectrum);
scale = 1;
srf = scale * originalReflect;
targetSpectrumFile = fullfile(resources, 'SpectralIllusionTarget.spd');
rtbWriteSpectrumFile(wls, srf, targetSpectrumFile);


%% Plot the initial target and destination reflectances.
% read target and destination reflectances from conditions file
[names, values] = rtbParseConditions(initialConditionsFile);
targSpectrum = values{strcmp(names, 'targetColor')};
destSpectrum = values{strcmp(names, 'destinationColor')};
[targWls, targReflect] = rtbReadSpectrum(fullfile(resources, targSpectrum));
[destWls, destReflect] = rtbReadSpectrum(destSpectrum);

f = figure('UserData', 'SpectralIllusion');
axReflect = subplot(5, 1, 3, 'Parent', f);
plot(axReflect, ...
    targWls, targReflect, 'sb', ...
    destWls, destReflect, 'og');
xlim(axReflect, [350 750]);
ylabel(axReflect, 'reflectance');
legend(axReflect, 'target', 'destination', 'Location', 'northwest')
set(axReflect,  'UserData', 'reflectance', 'Box', 'off');
drawnow();


%% Do the initial rendering.
nativeSceneFiles = rtbMakeSceneFiles(parentSceneFile, ...
    'conditionsFile', initialConditionsFile, ...
    'mappingsFile', mappingsFile, ...
    'hints', hints);
radianceDataFiles = rtbBatchRender(nativeSceneFiles, 'hints', hints);
montageName = sprintf('SpectralIllusionInitial (%s)', hints.renderer);
montageFile = [montageName '.png'];
SRGBMontage = rtbMakeMontage(radianceDataFiles, ...
    'outFile', montageFile, ...
    'toneMapFactor', toneMapFactor, ...
    'isScale', isScale, ...
    'hints', hints);


%% Plot the initial rendering.
axInitial = subplot(5, 2, [1 3], 'Parent', f);
imshow(uint8(SRGBMontage), 'Parent', axInitial);
title('initial');
set(axInitial, 'UserData', 'initial');
drawnow();


%% Read the initial rendering and compute a clever destination spectrum.
% locate the target and destination pixels in the rendering
rendering = load(radianceDataFiles{1});
height = size(rendering.multispectralImage, 1);
width = size(rendering.multispectralImage, 2);
targX = round(width * (165/320));
targY = round(height * (68/240));
destX = round(width * (211/320));
destY = round(height * (151/240));

% get the target and destination pixel spectra
targPixel = squeeze(rendering.multispectralImage(targY, targX, :));
destPixel = squeeze(rendering.multispectralImage(destY, destX, :));

% compute the target and destination apparent illumination
targPixelResampled = SplineRaw(rendering.S, targPixel, targWls);
targIllum = targPixelResampled ./ targReflect;
destPixelResampled = SplineRaw(rendering.S, destPixel, destWls);
destIllum = destPixelResampled ./ destReflect;


%% Plot target and destination pixels and apparent illumination.
% show target and destination pixel locations
line(targX, targY, ...
    'Parent', axInitial, ...
    'Marker', 'square', ...
    'MarkerSize', 10, ...
    'Color', [0 0 1]);
line(destX, destY, ...
    'Parent', axInitial, ...
    'Marker', 'o', ...
    'MarkerSize', 10, ...
    'Color', [0 1 0]);

% show apparent illumination
axIllum = subplot(5, 1, 4, 'Parent', f);
plot(axIllum, ...
    targWls, targIllum, 'sb', ...
    destWls, destIllum, 'og');
ylabel(axIllum, 'illumination');
xlim(axIllum, [350 750]);
set(axIllum, 'UserData', 'illumination', 'Box', 'off');
drawnow();

% show rendered pixel spectra
wls = SToWls(rendering.S);
axPixel = subplot(5, 1, 5, 'Parent', f);
plot(axPixel, ...
    wls, targPixel, 'sb', ...
    wls, destPixel, 'og');
ylabel(axPixel, 'pixel');
xlim(axPixel, [350 750]);
set(axPixel, 'UserData', 'reflected', 'Box', 'off');
drawnow();


%% Compute a clever new destination spectrum and write it to file.
destIllumNonzero = max(destIllum, 0.001);
cleverReflect = targPixelResampled ./ destIllumNonzero;
destinationSpectrumFile = fullfile(resources, 'SpectralIllusionDestination.spd');
rtbWriteSpectrumFile(destWls, cleverReflect, destinationSpectrumFile);


%% Plot the clever new reflectance
line(destWls, cleverReflect, ...
    'Parent', axReflect, ...
    'LineStyle', 'none', ...
    'Marker', '*', ...
    'Color', [1 0 0])
legend(axReflect, 'target', 'destination', 'illusion destination', ...
    'Location', 'northwest')


%% Render the illusion using the clever destination spectrum.
nativeSceneFiles = rtbMakeSceneFiles(parentSceneFile, ...
    'conditionsFile', cleverConditionsFile, ...
    'mappingsFile', mappingsFile, ...
    'hints', hints);
radianceDataFiles = rtbBatchRender(nativeSceneFiles, 'hints', hints);
montageName = sprintf('SpectralIllusionClever (%s)', hints.renderer);
montageFile = [montageName '.png'];
SRGBMontage = rtbMakeMontage(radianceDataFiles, ...
    'outFile', montageFile, ...
    'toneMapFactor', toneMapFactor, ...
    'isScale', isScale, ...
    'hints', hints);


%% Plot the clever rendering.
axClever = subplot(5, 2, [2 4], 'Parent', f);
imshow(uint8(SRGBMontage), 'Parent', axClever);
title('illusion');
set(axClever,  'UserData', 'illusion');
drawnow();


%% Read the destination pixel from the clever rendering.
rendering = load(radianceDataFiles{1});
height = size(rendering.multispectralImage, 1);
width = size(rendering.multispectralImage, 2);
destPixel = squeeze(rendering.multispectralImage(destY, destX, :));

% compute the destination pixel apparent illumination
destPixelResampled = SplineRaw(rendering.S, destPixel, destWls);
destIllum = destPixelResampled ./ cleverReflect;


%% Plot clever destination pixel spectrum and apparent illumination.
% apparent illumination
line(destWls, destIllum, ...
    'Parent', axIllum, ...
    'LineStyle', 'none', ...
    'Marker', '*', ...
    'Color', [1 0 0])

% pixel spectrum
wls = SToWls(rendering.S);
line(wls, destPixel, ...
    'Parent', axPixel, ...
    'LineStyle', 'none', ...
    'Marker', '*', ...
    'Color', [1 0 0])


%% Save the figure as an image file
figureFolder = rtbWorkingFolder( ...
    'folderName', 'images', ...
    'hints', hints);
figureFile = fullfile(figureFolder, [hints.recipeName '.png']);
saveas(gcf(), figureFile);
