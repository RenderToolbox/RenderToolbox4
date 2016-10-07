%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Get version information about the Mitsuba.
%
% @details
% This is the RenderToolbox4 "VersionInfo" function for Mitsuba.
%
% @details
% See RTB_VersionInfo_SampleRenderer() for more about VersionInfo
% functions.
%
% Usage:
%   versionInfo = RTB_VersionInfo_Mitsuba()
function versionInfo = RTB_VersionInfo_Mitsuba()

% Mitsuba executable date stamp
try
    executable = fullfile( ...
        getpref('Mitsuba', 'app'), getpref('Mitsuba', 'executable'));
    versionInfo = dir(executable);
catch err
    versionInfo = err;
end
