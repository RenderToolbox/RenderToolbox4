function spdPerNm = rtbSpdPowerPerWlBandToPowerPerNm(spdPerWlBand, S)
%% Convert spectral power-per-wavelength-band to power-per-nanometer.
%
% spdPerNm = rtbSpdPowerPerWlBandToPowerPerNm(spdPerWlBand, S)
% Converts the given spdPerWlBand matrix, which should contain a
% spectral power distribution with samples in units of
% power-per-wavelength-band, to the equivalent distribution with in units
% of power-per-nanometer.  The given S must describe the spectral
% sampling used in spdPerWlBand, and determines the correct conversion
% factor.
%
% Returns the given spdPerWlBand, divided by the spectral sampling band
% width in the given S.
%
% spdPerNm = rtbSpdPowerPerWlBandToPowerPerNm(spdPerWlBand, S)
%
%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

parser = inputParser();
parser.addRequired('spdPerWlBand', @isnumeric);
parser.addRequired('S', @isnumeric);
parser.parse(spdPerWlBand, S);
spdPerWlBand = parser.Results.spdPerWlBand;
S = parser.Results.S;

% get the sampling bandwidth
S = MakeItS(S);
bandwidth = S(2);

% divide band power by bandwidth to get power per nanometer
spdPerNm = spdPerWlBand ./ bandwidth;
