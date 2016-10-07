function [remodelerFunction, functionPath] = GetRemodelerAPIFunction(functionName, hints)
%% Find the function_handle of a RenderToolbox4 Remodeling API function.
%
% remodelerFunction = GetRemodelerAPIFunction(functionName, hints) Attempts
% to locate the named Remodeling API function that belongs to the given
% hints.remodeler, which names a set of remodeling functions.  Remodeler
% API functions must on the Matlab path.  They must have names that folow
% the pattern RTB_(functionName)_(remodeler), for example
% RTB_BeforeAll_SampleRemodeler.
%
% functionName must be the name of a RenderToolbox4 Remodeler API
% function:
%   - BeforeAll: may modify the Collada parent scene document once,
%   before all other RenderToolbox4 processing.
%   - BeforeCondition: may modify the Collada parent scene document once
%   per condition, before mappings are applied.
%   - AfterCondition: may modify the Collada parent scene document once
%   per condition, after mappings are applied and before conversion to a
%   renderer-native scene.
%
% hints.remodeler must be the name of any set of user-defined remodeler
% functions, for example, "SampleRemodeler".
%
% Returns the function_handle of the RenderToolbox4 Remodeler API function,
% for the given hints.remodeler and functionName.  If no such function is
% found, retuns an empty [].  Also returns the full path to the named
% function, if found.
%
% [remodelerFunction, functionPath] = GetRemodelerAPIFunction(functionName, hints)
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('functionName', @(s) ischar(s) && any(strcmp(s, {'BeforeAll', 'BeforeCondition', 'AfterCondition'})));
parser.addRequired('hints', @isstruct);
parser.parse(functionName, hints);
functionName = parser.Results.functionName;
hints = parser.Results.hints;

remodelerFunction = [];
functionPath = '';

% build a standard function name
standardName = ['RTB_' functionName '_' hints.remodeler];

% try to find the API function by name
info = rtbResolveFilePath(standardName, hints.workingFolder);
if isempty(info.resolvedPath)
    disp(['Skipping optional Remodeler API function (not found): ' standardName])
    return
end

% return the API function as a function_handle
remodelerFunction = str2func(standardName);
functionPath = info.absolutePath;
