function [rendererFunction, functionPath] = GetRendererAPIFunction(functionName, hints)
%% Find the function_handle of a RenderToolbox4 renderer API function.
%
% rendererFunction = GetRendererAPIFunction(functionName, hints) Attempts
% to locate the named Renderer API function that belongs to the given
% hints.renderer, which names a set of renderer plugin functions.  Renderer
% API functions must on the Matlab path.  They must have names that folow
% the  pattern RTB_(functionName)_(renderer), for example
% RTB_ApplyMappings_SampleRenderer.
%
% functionName must be the name of a RenderToolbox4 Renderer API
% function:
%   - ApplyMappings: the funciton that converts RenderToolbox4 mappings
%   to renderer-native scene adjustments
%   - ImportCollada: the function that converts Collada parent scene
%   files to the @a renderer-native format
%   - Render: the function that invokes the given @a hints.renderer
%   - DataToRadiance: the function that converts @a hints.renderer outputs to
%   physical radiance units
%   - VersionInfo: the function that returns version information about
%   a renderer.
%
% hints.renderer must be the name of any supported renderer, for example,
% "SampleRenderer", "PBRT", or "Mitsuba".
%
% Returns the function_handle of the RenderToolbox4 Renderer API function,
% for the given hints.renderer and functionName.  If no such function
% is found, retuns an empty [].  Also returns the full path to the named
% function, if found.
%
% [rendererFunction, functionPath] = GetRendererAPIFunction(functionName, hints)
%
%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

parser = inputParser();
parser.addRequired('functionName', @(s) ischar(s) && any(strcmp(s, {'ApplyMappings', 'ImportCollada', 'Render', 'DataToRadiance', 'VersionInfo'})));
parser.addRequired('hints', @isstruct);
parser.parse(functionName, hints);
functionName = parser.Results.functionName;
hints = parser.Results.hints;

rendererFunction = [];
functionPath = '';

% build a standard function name
standardName = ['RTB_' functionName '_' hints.renderer];

% try to find the API function by name
info = rtbResolveFilePath(standardName, hints.workingFolder);
if isempty(info.resolvedPath)
    disp(['Expected Renderer API function is missing: ' standardName])
    return
end

% return the API function as a function_handle
rendererFunction = str2func(standardName);
functionPath = info.absolutePath;
