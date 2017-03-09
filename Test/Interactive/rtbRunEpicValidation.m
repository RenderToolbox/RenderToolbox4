function [results, comparisons, matchInfo, figs] = rtbRunEpicValidation(outputRoot, referenceRoot, varargin)
%% Run an "epic" example tests, and compare to published reference data.
%
% results = rtbRunEpicValidation(outputRoot, referenceRoot) renders example
% scenes by invoking all of the "rtbMake..." executive sripts found within
% the ExampleScenes/ folder and putting results into the given outputRoot
% folder.  Then compares all rendered recipes to published reference data,
% using the given referenceRoot to store the reference data.
%
% Returns a struct with information about each recipe executed locally --
% see rtbRunEpicExamples().  Also returns a struct with information about
% comparisons to reference data, a struct with information about how local
% and reference data files were matched up, and an array of figure handles
% that illustrate the comparisons -- see rtbRunEpicComparison().
%
% rtbRunEpicValidation( ... name, value) passes additional name-value pairs
% to the functions rtbRunEpicExamples() and rtbRunEpicComparison().
%
%%% RenderToolbox4 Copyright (c) 2012-2017 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('outputRoot', @ischar);
parser.addRequired('referenceRoot', @ischar);
parser.parse(outputRoot, referenceRoot);
outputRoot = parser.Results.outputRoot;
referenceRoot = parser.Results.referenceRoot;


%% Run the epic example set.
results = rtbRunEpicExamples( ...
    'outputRoot', outputRoot, ...
    varargin{:});


%% Run the epic comparison.
[comparisons, matchInfo, figs] = rtbRunEpicComparison( ...
    outputRoot, referenceRoot, ...
    varargin{:});
