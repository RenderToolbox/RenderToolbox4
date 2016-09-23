function results = rtbTestAllExampleScenes(varargin)
%% Run all "Make*" executive scripts in the ExampleScenes/ folder.
%
% results = rtbTestAllExampleScenes() renders example scenes by invoking
% all of the "Make..." executive sripts found within the ExampleScenes/
% folder
%
% Returns a struct with information about each executive script, such as
% whether the script executed successfully, any Matlab error that was
% thrown, and when the script completed.
%
% Also saves a mat-file with several variables about test parameters and
% results:
%   - outputRoot -- the workingFolder that contains test outputs
%   - makeFunctions -- the execuive scripts that were run
%   - hints -- default RenderToolbox4 option
%   - results -- the returned struct of results about rendering scripts
%
% The mat-file will be saved in the working outputRoot folder.  It will
% have a name that that includes the name of this m-file, plus the date and
% time.
%
% rtbTestAllExampleScenes( ... 'outputRoot', outputRoot) specifies the
% working folder where to put rendering outputs.  The default is from
% rtbDefaultHints().
%
% rtbTestAllExampleScenes( ... 'makeFunctions', makeFunctions) specifies a
% cell array of executive functions to run.  The default is to search the
% ExampleScenes/ folder for files that begin with "Make".
%
%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

parser = inputParser();
parser.addParameter('outputRoot', rtbWorkingFolder(), @ischar);
parser.addParameter('makeFunctions', {}, @iscellstr);
parser.parse(varargin{:});
outputRoot = parser.Results.outputRoot;
makeFunctions = parser.Results.makeFunctions;

% set global workingFolder preference so that scrupts can find it
% make best effort to restore workingFolder at the end
oldOutputRoot = getpref('RenderToolbox4', 'workingFolder');
setpref('RenderToolbox4', 'workingFolder', outputRoot);
hints = rtbDefaultHints();

% choose execitive scripts/functions to run
if isempty(makeFunctions)
    % find all the m-functions named "Make*", in ExampleScenes/
    makePattern = 'Make\w+\.m';
    exampleRoot = fullfile(rtbRoot(), 'ExampleScenes');
    makeFunctions = rtbFindFiles('root', exampleRoot, 'filter', makePattern);
    
    % exclude functions that don't work yet
    notWorkingPath = fullfile(exampleRoot, 'NotYetWorking');
    notWorkingFunctions = rtbFindFiles('root', notWorkingPath, 'filter', makePattern);
    makeFunctions = setdiff(makeFunctions, notWorkingFunctions);
end

% declare a struct for test results
results = struct( ...
    'makeFile', makeFunctions, ...
    'isSuccess', false, ...
    'error', [], ...
    'elapsed', []);

% turn of warnings about scaling for this run, so as not
% to alarm the user of the test program.
warnState(1) = warning('off','RenderToolbox4:PBRTXMLIncorrectlyScaled');
warnState(2) = warning('off','RenderToolbox4:DefaultParamsIncorrectlyScaled');

% try to render each example scene
testTic = tic();
for ii = 1:numel(makeFunctions)
    
    [makePath, makeName] = fileparts(makeFunctions{ii});
    
    try
        % make the example scene!
        evalin('base', 'clear');
        evalin('base', ['run ' fullfile(makePath, makeName)]);
        results(ii).isSuccess = true;
        
    catch err
        % trap the error
        results(ii).isSuccess = false;
        results(ii).error = err;
    end
    
    % close figures so as to avoid filling up memory
    close all;
    
    % keep track of timing
    results(ii).elapsed = toc(testTic);
end

% restore warning state
for ii = 1:length(warnState)
    warning(warnState(ii).state,warnState(ii).identifier);
end

% restore working folder preference
setpref('RenderToolbox4', 'workingFolder', oldOutputRoot);

% how did it go?
isExampleSuccess = [results.isSuccess];
fprintf('\n%d scenes succeeded.\n\n', sum(isExampleSuccess));
for ii = find(isExampleSuccess)
    disp(sprintf('%d %s', ii, results(ii).makeFile))
end

fprintf('\n%d scenes failed.\n\n', sum(~isExampleSuccess));
for ii = find(~isExampleSuccess)
    disp('----')
    disp(sprintf('%d %s', ii, results(ii).makeFile))
    disp(results(ii).error)
    disp(' ')
end

toc(testTic)


%% Save lots of results to a .mat file.
if ~isempty(outputRoot) && ~exist(outputRoot, 'dir')
    mkdir(outputRoot);
end
baseName = mfilename();
dateTime = datestr(now(), 30);
resultsBase = sprintf('%s-%s', baseName, dateTime);
resultsFile = fullfile(outputRoot, resultsBase);
save(resultsFile, 'outputRoot', 'makeFunctions', 'results', 'hints');
