%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
%% Save D65 metamers for 24 Macbeth ColorChecker reflectances.
%
% Using the rtbIlluminantMetamerExample() demo function, loop through all 24
% MCC surface spectra and save the computed D65 Metamers.

% allocate a matrix to hold many metamers
nSurfaces = 24;
S_mccD65Metamer = getpref('Mitsuba', 'S');
sur_mccD65Metamer = zeros(S_mccD65Metamer(3), nSurfaces);

%% compute a D65 metamer for each mcc surface color
for ii = 1:nSurfaces
    sur_mccD65Metamer(:,ii) = rtbIlluminantMetamerExample(ii);
end
close all

%% save results to standard Colorimetric .mat file
outDir = fullfile(rtbRoot(), 'RenderData', 'Macbeth-D65Metamers');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end
name = 'sur_mccD65Metamer';
matFile = fullfile(outDir, [name '.mat']);
save(matFile, 'sur_mccD65Metamer', 'S_mccD65Metamer');

% generate .spd files
rtbImportPsychColorimetricMatFile(matFile, [name '.spd']);