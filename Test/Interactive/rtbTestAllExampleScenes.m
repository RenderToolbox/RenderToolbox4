function results = rtbTestAllExampleScenes(varargin)
%% Run all "rtbMake..." scripts in the ExampleScenes/ folder.
%
% results = rtbTestAllExampleScenes() renders example scenes by invoking
% all of the "rtbMake..." executive sripts found within the ExampleScenes/
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
% ExampleScenes/ folder for m-files that begin with "rtbMake".
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addParameter('outputRoot', rtbWorkingFolder(), @ischar);
parser.addParameter('makeFunctions', {}, @iscellstr);
parser.parse(varargin{:});
outputRoot = parser.Results.outputRoot;
makeFunctions = parser.Results.makeFunctions;

if ~isempty(outputRoot) && 7 ~= exist(outputRoot, 'dir')
    mkdir(outputRoot);
end

% choose execitive scripts/functions to run
if isempty(makeFunctions)
    % find all the m-functions named "Make*", in ExampleScenes/
    makePattern = 'rtbMake[\w]+\.m$';
    exampleRoot = fullfile(rtbRoot(), 'ExampleScenes');
    makeFunctions = rtbFindFiles('root', exampleRoot, 'filter', makePattern);
end

% declare a struct for test results
results = struct( ...
    'makeFile', makeFunctions, ...
    'isSuccess', false, ...
    'error', [], ...
    'elapsed', []);

% try to render each example scene
testTic = tic();
for ii = 1:numel(makeFunctions)
    
    % set alternate workingFolder
    oldOutputRoot = getpref('RenderToolbox4', 'workingFolder');
    setpref('RenderToolbox4', 'workingFolder', outputRoot);
    
    % turn of warnings about scaling for the moment so as not to alarm user
    warnState(1) = warning('off', 'RenderToolbox4:PBRTXMLIncorrectlyScaled');
    warnState(2) = warning('off', 'RenderToolbox4:DefaultParamsIncorrectlyScaled');
    
    try
        % make the example scene!
        runIsolated(makeFunctions{ii});
        results(ii).isSuccess = true;
    catch err
        % trap any error
        results(ii).isSuccess = false;
        results(ii).error = err;
    end
    
    % close figures so as to avoid filling up memory
    close all;
    
    % keep track of timing
    results(ii).elapsed = toc(testTic);
    
    % restore warning state
    for ww = 1:length(warnState)
        warning(warnState(ww).state, warnState(ww).identifier);
    end
    
    % restore working folder preference
    setpref('RenderToolbox4', 'workingFolder', oldOutputRoot);
end


% how did it go?
isExampleSuccess = [results.isSuccess];
fprintf('\n%d scenes succeeded.\n\n', sum(isExampleSuccess));
for ii = find(isExampleSuccess)
    fprintf('%d %s\n', ii, results(ii).makeFile);
end

fprintf('\n%d scenes failed.\n\n', sum(~isExampleSuccess));
for ii = find(~isExampleSuccess)
    disp('----')
    fprintf('%d %s\n', ii, results(ii).makeFile);
    disp(results(ii).error)
    disp(results(ii).error.message)
    disp(' ')
end

toc(testTic)


%% Save lots of results to a .mat file.
baseName = mfilename();
dateTime = datestr(now(), 30);
resultsBase = sprintf('%s-%s', baseName, dateTime);
resultsFile = fullfile(outputRoot, resultsBase);
save(resultsFile);


%% Run a script in an isolated workspace.
function runIsolated(scriptPath)
run(scriptPath);

