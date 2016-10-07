%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Make a D65 metamer for a given Macbeth ColorChcekr tile.
%   @param whichSur the number of a ColorChecker tile, 1-24.
%
% Produce a new illuminant that differs in spectrum from D65, but that
% produces the same XYZ value when reflected from the specified
% ColorChecker tile. 
%
% David Brainard wrote this to demonstrate the idea of metamers.
%
% @details
% Usage:
%   spd2 = rtbIlluminantMetamerExample(whichSur)
%
function spd2 = rtbIlluminantMetamerExample(whichSur)

%% Load in relevant data
S = [400 10 31];

% XYZ
load T_xyz1931
T_xyz = SplineCmf(S_xyz1931,T_xyz1931,S);

% MCC
if nargin < 1
    whichSur = 1;
end

dataFile = fullfile(rtbRoot(), 'RenderData', ...
    'Macbeth-ColorChecker', 'sur_mccBabel.mat');
load(dataFile);
sur_mcc = SplineSrf(S_mccBabel,sur_mccBabel,S);
sur1 = sur_mcc(:,whichSur);

% D65
load spd_D65
spd1 = SplineSpd(S_D65,spd_D65,S);

%% Find XYZ values that spd1 produces when
% it reflects off of the specified mcc surface
XYZ1 = T_xyz*diag(sur1)*spd1;

%% Load monitor spectra.   We'll create
% our metamer as a light that the monitor
% could produce
load B_monitor
B = SplineSpd(S_monitor,B_monitor,S);

%% Find the phosphor weights that produce the
% same XYZ values, when the resultant spectrum
% reflects from the same surface
M_MonToXYZ = T_xyz*diag(sur1)*B;
M_XYZToMon = inv(M_MonToXYZ);
spd2 = B*M_XYZToMon*XYZ1;
XYZ2 = T_xyz*diag(sur1)*spd2;
if (max(abs(XYZ1-XYZ2)) > 1e-6)
    error('Theory failure');
end

%% Plot the two illuminants
figure; clf; hold on
plot(SToWls(S),spd1,'k','LineWidth',2);
plot(SToWls(S),spd2,'r','LineWidth',2);
xlabel('Wavelength (nm)');
ylabel('Relative Power');
title(sprintf('Illuminant metamers wrt MCC surface %d',whichSur));
