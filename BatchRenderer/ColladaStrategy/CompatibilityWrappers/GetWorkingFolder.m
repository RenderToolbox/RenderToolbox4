function folder = GetWorkingFolder(folderName, isRendererSpecific, hints)
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

if nargin < 2
    isRendererSpecific = false;
end

if nargin < 3
    hints = GetDefaultHints();
else
    hints = GetDefaultHints(hints);
end


folder = rtbWorkingFolder( ...
    'folderName', folderName, ...
    'rendererSpecific', isRendererSpecific, ...
    'hints', hints);
