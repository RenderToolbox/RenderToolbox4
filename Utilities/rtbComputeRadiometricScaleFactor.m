function radiometricScaleFactor = rtbComputeRadiometricScaleFactor(renderer)
%% Calculate scale factors to bring renderer outputs into radiance units.
%
% rtbComputeRadiometricScaleFactor(renderer) Calculates a radiometric unit
% scale factor for the given renderer and stores the scale factor using
% Matlab's setpref().  Radiometric unit scale factors are used by
% RenderToolbox4 DataToRadiance functions to bring "raw" renderer output
% into physical rasiance units.  Computation is based on the
% ExampleScenes/RadiaceTest recipe which has known radiometric properties.
%
% See the RenderToolbox4 wiki for details about radiometric units:
%	https://github.com/DavidBrainard/RenderToolbox4/wiki/RadianceTest
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

parser = inputParser();
parser.addRequired('renderer', @ischar);
parser.parse(renderer);
renderer = parser.Results.renderer;

%% Produce renderingings with known radiometric properties.
% render the RadianceTest scene
%   assume outputs go to the deafult outputDataFolder
evalIsolated('rtbMakeRadianceTest');

hints.renderer = renderer;
hints.recipeName = 'rtbMakeRadianceTest';
dataFolder = rtbWorkingFolder( ...
    'folderName', 'renderings', ...
    'rendererSpecific', true, ...
    'hints', hints);

resources = rtbWorkingFolder( ...
    'folderName', 'resources', ...
    'hints', hints);

%% Read known parameters from the RadianceTest "reference" condition.
% distance from point light to reflector
[names, values] = rtbParseConditions('RadianceTestConditions.txt');
isName = strcmp('imageName', names);
isReference = strcmp('reference', values(:, isName));
isDistance = strcmp('lightDistance', names);
distanceToPointSource = sscanf(values{isReference, isDistance}, '%f');

% power of point source per unit wavelength
%   arbitrarily, choose a spectrum sample near 500nm
isSpectrum = strcmp('lightSpectrum', names);
spectrumFile = values{isReference, isSpectrum};
[wavelengths, magnitudes] = rtbReadSpectrum(fullfile(resources, spectrumFile));
spectrumIndex = find(wavelengths >= 500, 1, 'first');
pointSource_PowerPerUnitWavelength = magnitudes(spectrumIndex);

%% Compute expected radiance from first principles.

% illuminance arriving at a unit area on the diffuser.
irradiance_PowerPerUnitAreaUnitWl = ...
    pointSource_PowerPerUnitWavelength/(4*pi*(distanceToPointSource^2));

% light coming off the diffuser scatters over a hemisphere.
%   because of the cos(phi) factor in the lambertion equation,
%   the total light over the hemisphere is equal to pi times
%   the luminance.  See Wyszecki and Stiles, 2cd edition, pp.
%   273-274, equaiton 29(4.3.6).
radiance_PowerPerAreaSrUnitWl = irradiance_PowerPerUnitAreaUnitWl / pi();

%% Compute a radiometric unit scale factor the given render.

% locate RadianceTest "reference" data file
dataFile = rtbFindFiles('root', dataFolder, 'filter', 'reference\.mat$');
data = load(dataFile{1});

% get a pixel spectrum from the center of the multispectral rendering
%   arbitrarily, choose a spectrum sample near 500nm
center = round(size(data.multispectralImage)/2);
wavelengths = MakeItWls(data.S);
spectrumIndex = find(wavelengths >= 500, 1, 'first');
renderedIrradiance_PixelValue = ...
    data.multispectralImage(center(1), center(2), spectrumIndex);

% scale renderer output to match expected radiance
radiometricScaleFactor = ...
    radiance_PowerPerAreaSrUnitWl/renderedIrradiance_PixelValue;

% store the scale factor
setpref(renderer, 'radiometricScaleFactor', radiometricScaleFactor);

% explain the scale factor
fprintf('%s irradiance: %0.4g (arbitrary units)\n', ...
    renderer, renderedIrradiance_PixelValue);
fprintf('Corresponding radiance: %0.4g (power/[area-sr-wl])\n', ...
    radiance_PowerPerAreaSrUnitWl);
fprintf('%s scale factor: %0.4g to bring rendered image into physical radiance units\n\n', ...
    renderer, radiometricScaleFactor);


%% Run a command in an isolated workspace.
function evalIsolated(command)
eval(command);

