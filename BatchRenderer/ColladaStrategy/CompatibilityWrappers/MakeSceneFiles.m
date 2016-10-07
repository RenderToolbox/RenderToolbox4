function scenes = MakeSceneFiles(colladaFile, conditionsFile, mappingsFile, hints)
%% Compatibility wrapper for code written using version 2.
%
% This function is a wrapper that can be called by "old" RenderToolbox4
% examples and user code, written before the Version 3.  Its job is to
% "look like" the old code, but internally it calls new code.
%
% To encourage users to update to Versoin 3 code, this wrapper will display
% an irritating warning.
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

rtbWarnDeprecated();

%% Parameters
if nargin < 1 || isempty(colladaFile)
    colladaFile = '';
end

if nargin < 2 || isempty(conditionsFile)
    conditionsFile = '';
end

if nargin < 3 || isempty(mappingsFile)
    mappingsFile = fullfile( ...
        rtbRoot(), ...
        'BatchRenderer', 'Collada', 'Deprecated', ...
        'RenderData', 'DefaultMappings.txt');
end

if nargin < 4
    hints = GetDefaultHints();
else
    hints = GetDefaultHints(hints);
end

scenes = rtbMakeSceneFiles(colladaFile, ...
    'conditionsFile', conditionsFile, ...
    'mappingsFile', mappingsFile, ...
    'hints', hints);
