%% Run an "epic" example tests, and compare to published reference data.
%
% This script is an example of how to run through an "epic scene test" and
% comparison of results to reference data stored at Brainard Archiva.
%   http://52.32.77.154/#browse~RenderToolbox/reference-data
%
% All the work is done by the function rtbRunEpicValidation().  But there
% are several parameters that you might want to configure.  So here is a
% script with comments.
%
%%% RenderToolbox4 Copyright (c) 2012-2017 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

clear;
clc;


%% Parameters to pass to rtbRunEpicExamples().

% where to store locally generated results
localOutput = '/Users/ben/Deskop/rtb-epic';

% choose a few recipes for testing this out
makeFunctions = {'rtbMakeCoordinatesTest', 'rtbMakeDragon'};

% leave empty to run them all
% makeFunctions = {};


%% Parameters to pass to rtbRunEpicComparison().

% where to store fetched reference data
rtbReference = '/Users/ben/Deskop/rtb-reference';

% where to save generated comparison figures
figureFolder = '/Users/ben/Deskop/rtb-figures';

% a name to use for this comparison run
summaryName = 'epic-validation-example';


%% Run examples and do the comparison.
% You could pass in additional parameters for rtbRunEpicExamples() or
% rtbRunEpicComparison(), too.  They will be forwarded along.  The
% parameters above seem like a good bunch to start with.

% This may take a long time.
% The outputs are:
%  - exampleResults -- struct array with info for each example recipe run
%  - comparisons -- struct array with info about comparisons to reference
%  - matchInfo -- struct array about matching up local data vs reference
%  - figures -- array of figure handles with comparison summary
[exampleResults, comparisons, matchInfo, figs] = rtbRunEpicValidation( ...
    localOutput, ...
    rtbReference, ...
    'makeFunctions', makeFunctions, ...
    'figureFolder', figureFolder, ...
    'summaryName', summaryName);

