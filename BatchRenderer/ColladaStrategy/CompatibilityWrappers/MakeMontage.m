function [SRGBMontage, XYZMontage, luminanceScale] = MakeMontage(inFiles, outFile, toneMapFactor, isScale, hints)
%% Compatibility wrapper for code written using version 2.
%
% This function is a wrapper that can be called by "old" RenderToolbox4
% examples and user code, written before the Version 3.  Its job is to
% "look like" the old code, but internally it calls new code.
%
% To encourage users to update to Versoin 3 code, this wrapper will display
% an irritating warning.
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

rtbWarnDeprecated();

SRGBMontage = [];
XYZMontage = [];

if nargin < 1 || isempty(inFiles)
    return;
end

if nargin < 2 || isempty(outFile)
    [inPath, inBase, inExt] = fileparts(inFiles{1});
    outFile = [inBase '-montage.png'];
end
[outPath, outBase, outExt] = fileparts(outFile);

if isempty(outPath)
    outPath = rtbWorkingFolder( ...
        'folderName', 'images', ...
        'rendererSpecific', true, ...
        'hints', hints);
end

if nargin < 3 || isempty(toneMapFactor)
    toneMapFactor = 0;
end

if nargin < 4 || isempty(isScale)
    isScale = false;
end

if nargin < 5
    hints = GetDefaultHints();
else
    hints = GetDefaultHints(hints);
end

[SRGBMontage, XYZMontage, luminanceScale] = rtbMakeMontage(inFiles, ...
    'outFile', outFile, ...
    'toneMapFactor', toneMapFactor, ...
    'isScale', isScale, ...
    'hints', hints);
