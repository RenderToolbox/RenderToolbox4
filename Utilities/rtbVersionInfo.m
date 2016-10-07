function info = rtbVersionInfo()
%% Collect revision information about RenderToolbox4 and dependencies.
%
% info = rtbVersionInfo() Gets revision information about
% RenderTooblox4 and its dependencies, including Psychtoolbox, Matlab, the
% computer, PBRT, and Mitsuba.
%
% Returns a struct that contains information collected about each
% component.
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

% Git info about RenderToolbox4
try
    info.rtbGitInfo = GetGITInfo(rtbRoot());
catch err
    info.rtbGitInfo = err;
end

% SVN or git info about Psychtoolbox
try
    info.PsychtoolboxSVNInfo = GetSVNInfo(PsychtoolboxRoot());
    info.PsychtoolboxGITInfo = GetGITInfo(PsychtoolboxRoot());
    
catch err
    info.PsychtoolboxSVNInfo = err;
end

% Matlab version
try
    info.MatlabVersion = version();
catch err
    info.MatlabVersion = err;
end

% Matlab tooblox versions
try
    info.MatlabToolboxVersions = ver();
catch err
    info.MatlabToolboxVersions = err;
end

% Text that includes OS version
try
    info.OSVersion = evalc('ver');
catch err
    info.OSVersion = err;
end

% RenderToolbox4 preferences
try
    info.rtbPreferences = getpref('RenderToolbox4');
catch err
    info.rtbPreferences = err;
end

