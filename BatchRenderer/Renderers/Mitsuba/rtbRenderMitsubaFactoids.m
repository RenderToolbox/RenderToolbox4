function [factoids, exrOutput] = rtbRenderMitsubaFactoids(sceneFile, varargin)
% Obtain ground truth "factoids" about a Mitsuba scene.
%
% [factoids, exrOutput] = rtbRenderMitsubaFactoids(sceneFile) invokes
% Mitsuba to obtain ground truth scene "factoids".  Returns a struct array
% of ground truth images, with one field per ground truth factoid.
%
% The given sceneFile must specify a "multichannel" integrator with one or
% more nested "field" integrators.  You can create such scenes with
% rtbWriteMitsubaFactoidScene().
%
% rtbRenderMitsubaFactoids( ... 'mitsuba', mitsuba) specify a struct of
% info about the installed Mitsuba renderer.  For some factoids, this must
% be a version of Mistuba compiled for RGB rendering, not spectral
% rendering.  The default is taken from getpref('Mitsuba').
%
% rtbRenderMitsubaFactoids(... 'hints', hints)
% Specify a struct of RenderToolbox options.  If hints is omitted, values
% are taken from rtbDefaultHints().
%
%%% RenderToolbox4 Copyright (c) 2012-2017 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('sceneFile', @ischar);
parser.addParameter('mitsuba', [], @(m) isempty(m) || isstruct(m));
parser.addParameter('hints', rtbDefaultHints(), @isstruct);
parser.parse(sceneFile, varargin{:});
sceneFile = parser.Results.sceneFile;
mitsuba = parser.Results.mitsuba;
hints = rtbDefaultHints(parser.Results.hints);

if isempty(mitsuba)
    % modify default mitsuba config to look for rgb
    mitsuba = getpref('Mitsuba');
    mitsuba.dockerImage = 'ninjaben/mitsuba-rgb';
    mitsuba.kubernetesPodSelector = 'app=mitsuba-spectral';
    if ismac()
        mitsuba.app = '/Applications/Mitsuba-RGB.app';
    else
        mitsuba.executable = 'mitusba-rgb';
    end
end

% look carefully for the input file
workingFolder = rtbWorkingFolder('hints', hints);
fileInfo = rtbResolveFilePath(sceneFile, workingFolder);
sceneFile = fileInfo.absolutePath;


%% Render the factoid scene.renderer = RtbMitsubaRenderer(hints);
renderer = RtbMitsubaRenderer(hints);
renderer.mitsuba = mitsuba;

[~, ~, exrOutput] = renderer.renderToExr(sceneFile);
[sliceInfo, data] = ReadMultichannelEXR(exrOutput);


%% Group data slices by factoid name.
factoids = struct();
factoidSize = size(data);
for ii = 1:numel(sliceInfo)
    % factoid channels have names like albedo.R, albedo.G, albedo.B
    split = find(sliceInfo(ii).name == '.');
    factoidName = sliceInfo(ii).name(1:split-1);
    channelName = sliceInfo(ii).name(split+1:end);
    
    % initialize factoid output with data array and channel names
    if ~isfield(factoids, factoidName)
        factoids.(factoidName).data = ...
            zeros(factoidSize(1), factoidSize(2), 0);
        factoids.(factoidName).channels = {};
    end
    
    % sort channels, which may arrive out of order
    switch channelName
        case 'R'
            dataIndex = 1;
        case 'G'
            dataIndex = 2;
        case 'B'
            dataIndex = 3;
        otherwise
            dataIndex = numel(factoids.(factoidName).channels) + 1;
    end
    
    % insert data and channel name into output for this factoid
    slice = data(:,:,ii);
    factoids.(factoidName).data(:, :, dataIndex) = slice;
    factoids.(factoidName).channels{dataIndex} = channelName;
end

