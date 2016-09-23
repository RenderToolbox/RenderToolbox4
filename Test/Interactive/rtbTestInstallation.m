function [renderResults, comparison] = rtbTestInstallation(varargin)
% Make sure a new RenderToolbox4 installation is working.
%
% rtbTestInstallation() Initializes RenderToolbox4 after
% installation and then put it through some basic tests.  If this function
% runs properly, you're off to the races.
%
% rtbTestInstallation( ... 'referenceRoot', referenceRoot)
% provide the path to a set of RenderToolbox4 reference data.  Rendering
% produced locally will be compared to renderings in the reference data
% set.
%
% rtbTestInstallation( ... 'doAll', doAll) specify whether to to
% all available test renderings (true), or just a few (false). The default
% is false, do just a few test renderings.
%
% Returns a struct of results from rendering test scenes.  If
% referenceRoot is provided, also returns a struct of comparisons between
% local renderings and reference renderings.
%
% [renderResults, comparison] = rtbTestInstallation(varargin)
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

parser = inputParser();
parser.addParameter('referenceRoot', '', @ischar);
parser.addParameter('doAll', false, @islogical);
parser.parse(varargin{:});
referenceRoot = parser.Results.referenceRoot;
doAll = parser.Results.doAll;

renderResults = [];
comparison = [];

%% Check working folder for write permission.
workingFolder = rtbWorkingFolder();
fprintf('Checking working folder:\n');

% make sure the folder exists
if exist(workingFolder, 'dir')
    fprintf('  folder exists: %s\n', workingFolder);
    fprintf('  OK.\n');
else
    fprintf('  creating folder: %s\n', workingFolder);
    [status, message] = mkdir(workingFolder);
    if 1 == status
        fprintf('  OK.\n');
    else
        error('Could not create folder %s:\n  %s\n', ...
            workingFolder, message);
    end
end

% make sure Matlab can write to the folder
testFile = fullfile(workingFolder, 'test.txt');
fprintf('Trying to write: %s\n', testFile);
[fid, message] = fopen(testFile, 'w');
if fid < 0
    error('Could not write to folder %s:\n  %s\n', workingFolder, message);
end
fclose(fid);
delete(testFile);
fprintf('  OK.\n');

%% Check for Docker, the preferred way to render.
fprintf('Checking for Docker...\n');
[status, result] = system('docker ps');
if 0 == status
    fprintf('  OK.\n');
else
    fprintf('  Could not invoke Docker: %s.\n', result);
end

%% Check for local install of Renderers.
mitsuba = getpref('Mitsuba');
if ismac()
    checkExists(mitsuba.app, 'Checking for Mitsuba App...');
else
    checkExists(mitsuba.executable, 'Checking for Mitsuba Executable...');
end

pbrt = getpref('PBRT');
checkExists(pbrt.executable, 'Checking for PBRT Executable...');

%% Render some example scenes.
if doAll
    fprintf('\nTesting rendering with all example scripts.\n');
    fprintf('This might take a while.\n');
    renderResults = rtbTestAllExampleScenes([], []);
    
else
    testScenes = { ...
        'rtbMakeCoordinatesTest.m', ...
        'rtbMakeDragon.m', ...
        'rtbMakeMaterialSphereBumps.m', ...;
        'rtbMakeMaterialSphereRemodeled.m'};
    
    fprintf('\nTesting rendering with %d example scripts.\n', numel(testScenes));
    fprintf('You should see several figures with rendered images.\n\n');
    renderResults = rtbTestAllExampleScenes('makeFunctions', testScenes);
    
end

if all([renderResults.isSuccess])
    fprintf('\nYour RenderToolbox4 installation seems to be working!\n');
end

%% Compare renderings to reference renderings?
if ~isempty(referenceRoot)
    localRoot = rtbWorkingFolder();
    fprintf('\nComparing local renderings\n  %s\n', localRoot);
    fprintf('with reference renderings\n  %s\n', referenceRoot);
    fprintf('You should see several more figures.\n\n');
    comparison = rtbCompareAllExampleScenes(localRoot, referenceRoot, '', 2);
else
    fprintf('\nNo referenceRoot provided.  Local renderings\n');
    fprintf('will not be compared with reference renderings.\n');
end


%% Check whether something exists and print messages.
function exists = checkExists(filePath, message)
fprintf('%s\n', message);
exists = 0 ~= exist(filePath, 'dir') || 0 ~= exist(filePath, 'file');
if exists
    fprintf('  Found %s\n', filePath);
    fprintf('  OK.\n');
else
    fprintf('  Could not find %s\n', filePath);
end
