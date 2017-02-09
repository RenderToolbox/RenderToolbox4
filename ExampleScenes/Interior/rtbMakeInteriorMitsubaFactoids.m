%%% RenderToolbox4 Copyright (c) 2012-2017 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
%% Render the Interior scene with various lighting.

%% Choose example files, make sure they're on the Matlab path.
parentSceneFile = 'interio.dae';
conditionsFile = 'InteriorConditions.txt';
mappingsFile = 'InteriorMappings.json';

%% Choose batch renderer options.
hints.whichConditions = 1;
hints.fov = 49.13434 * pi() / 180;
hints.recipeName = 'rtbMakeInteriorFactoids';

%% Write some spectra to use.
resources = rtbWorkingFolder('folderName', 'resources', 'hints', hints);
cieInfo = load('B_cieday');

% make orange-yellow for a few lights
temp = 4000;
scale = 3;
spd = scale * GenerateCIEDay(temp, cieInfo.B_cieday);
wls = SToWls(cieInfo.S_cieday);
rtbWriteSpectrumFile(wls, spd, fullfile(resources, 'YellowLight.spd'));

% make strong yellow for the hanging spot light
temp = 5000;
scale = 30;
spd = scale * GenerateCIEDay(temp, cieInfo.B_cieday);
wls = SToWls(cieInfo.S_cieday);
rtbWriteSpectrumFile(wls, spd, fullfile(resources, 'HangingLight.spd'));

% make daylight for the windows behind the camera
[wavelengths, magnitudes] = rtbReadSpectrum('D65.spd');
scale = 1;
magnitudes = scale * magnitudes;
rtbWriteSpectrumFile(wavelengths, magnitudes, fullfile(resources, 'WindowLight.spd'));

%% Obtain factoids with Mitsuba.

% start by generating a regular scene file.
hints.renderer = 'Mitsuba';
nativeSceneFiles = rtbMakeSceneFiles(parentSceneFile, ...
    'mappingsFile', mappingsFile, ...
    'conditionsFile', conditionsFile, ...
    'hints', hints);

% convert regular scene file for factoid rendering
factoidSceneFile = rtbWriteMitsubaFactoidScene(nativeSceneFiles{1}, ...
    'hints', hints);

% invoke Mitsuba to get the factoids
factoids = rtbRenderMitsubaFactoids(factoidSceneFile, ...
    'hints', hints);

%% Plot the factoids.
factoidNames = fieldnames(factoids);
nFactoids = numel(factoidNames);
rows = 3;
columns = ceil(nFactoids / rows);
for ff = 1:nFactoids
    factoidName = factoidNames{ff};
    factoid = factoids.(factoidName);
    
    subplot(rows, columns, ff);
    
    switch factoidName
        case {'primIndex', 'shapeIndex'}
            % index/nominal data with colormap
            imshow(factoid.data(:,:,1), prism());
        otherwise
            % continuous data as stretched rgb
            stretchedRgb = factoid.data ./ max(factoid.data(:));
            imshow(stretchedRgb);
    end
    
    title(factoidName);
end
