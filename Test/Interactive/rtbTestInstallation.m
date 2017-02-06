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
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

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


%% Check for native system libs and executables.
[status, ~, advice] = rtbCheckNativeDependencies();
if 0 ~= status
    error(advice);
end


%% Render some example scenes.
if doAll
    fprintf('\nTesting rendering with all example scripts.\n');
    fprintf('This might take a while.\n');
    renderResults = rtbRunEpicTest([], []);
    
else
    testScenes = { ...
        'rtbMakeCoordinatesTest.m', ...
        'rtbMakeDragon.m', ...
        'rtbMakeMaterialSphereBumps.m', ...;
        'rtbMakeMaterialSphereRemodeled.m'};
    
    fprintf('\nTesting rendering with %d example scripts.\n', numel(testScenes));
    fprintf('You should see several figures with rendered images.\n\n');
    renderResults = rtbRunEpicTest('makeFunctions', testScenes);
    
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
    comparison = rtbRunEpicComparison(localRoot, referenceRoot, '', 2);
else
    fprintf('\nNo referenceRoot provided.  Local renderings\n');
    fprintf('will not be compared with reference renderings.\n');
end
