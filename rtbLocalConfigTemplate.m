%% Configure RenderToolbox4 system defaults.
%
% This script attempts to locate system resources and create Matlab
% preferences necessary to use RenderToolbox4.
%
% For vanilla installations, like when installing on a fresh virutal
% machine, this script should work out-of-the-box.  For custom
% installations, you may need to copy and modify this script.
%
% You should run this script whenever you want to make sure that
% RenderToolbox4 is all set up.  This could be once, when you first install
% RenderToolbox4, or as often as you like!
%
% This script is also intended as a "local hook template" for use with the
% Toolbox Toolbox.  This means that when you deploy RenderToolbox4 using
% the ToolboxToolbox, you will get a copy of this script in your local
% hooks folder.  You should modify that copy as you need.
%
% Use rtbTestInstallation() to test whether things are working.
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.


%% Matlab preferences for RenderToolbox4 default hints.
myFolder = fullfile(rtbGetUserFolder(), 'render_toolbox');
renderToolbox4.workingFolder = myFolder;
renderToolbox4.recipeName = '';
renderToolbox4.batchRenderStrategy = 'RtbAssimpStrategy';
renderToolbox4.renderer = 'SampleRenderer';
renderToolbox4.converter = '';
renderToolbox4.imageHeight = 240;
renderToolbox4.imageWidth = 320;
renderToolbox4.whichConditions = [];
renderToolbox4.isReuseSceneFiles = false;
renderToolbox4.isParallel = false;
renderToolbox4.isCaptureCommandResults = true;

setpref('RenderToolbox4', fieldnames(renderToolbox4), struct2cell(renderToolbox4));


%% Locate Mitsuba.
mitsuba.radiometricScaleFactor = 0.0795827427;

% use Docker or Kubernetes, if present
mitsuba.dockerImage = 'ninjaben/mitsuba-spectral';
mitsuba.kubernetesPodSelector = 'app=mitsuba-spectral';

% or use local installation
if ismac()
    mitsuba.app = '/Applications/Mitsuba.app';
    mitsuba.executable = 'Contents/MacOS/mitsuba';
    mitsuba.importer = 'Contents/MacOS/mtsimport';
    mitsuba.libraryPathName = 'DYLD_LIBRARY_PATH';
    mitsuba.libraryPath = '';
else
    mitsuba.app = '';
    mitsuba.executable = 'mitusba';
    mitsuba.importer = 'mtsimport';
    mitsuba.libraryPathName = 'LD_LIBRARY_PATH';
    mitsuba.libraryPath = '';
end

% version 2 compatibility -- deprecated
mitsuba.adjustments = fullfile(rtbRoot(), ...
    'BatchRenderer', 'Collada', 'Deprecated', ...
    'RendererPlugins', 'Mitsuba', 'MitsubaDefaultAdjustments.xml');

setpref('Mitsuba', fieldnames(mitsuba), struct2cell(mitsuba));

%% Locate PBRT.
pbrt.radiometricScaleFactor = 0.0063831432;

% use Docker, if present
pbrt.dockerImage = 'ninjaben/pbrt-v2-spectral-docker';
pbrt.kubernetesPodSelector = 'app=pbrt';

% or use local install
pbrt.S = [400 10 31];
pbrt.executable = 'pbrt';

% version 2 compatibility -- deprecated
pbrt.adjustments = fullfile(rtbRoot(), ...
    'BatchRenderer', 'Collada', 'Deprecated', ...
    'RendererPlugins', 'PBRT', 'PBRTDefaultAdjustments.xml');

setpref('PBRT', fieldnames(pbrt), struct2cell(pbrt));

