%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
%% Try to render an unknown, complex scene without totally barfing.

%% Choose example files, make sure they're on the Matlab path.
%parentSceneFile = 'cup.dae';
parentSceneFile = 'interior.dae';

%% Choose batch renderer options.
hints.imageHeight = 480;
hints.imageWidth = 640;
hints.recipeName = mfilename();
rtbChangeToWorkingFolder(hints);

%% Use the automatic, default mappings file.
colors = { ...
    'mccBabel-1.spd', ...
    'mccBabel-2.spd', ...
    'mccBabel-3.spd', ...
    'mccBabel-4.spd', ...
    };
mappingsFile = WriteDefaultMappingsFile( ...
    fullfile(GetWorkingPath('resources', false, hints), parentSceneFile), ...
    '', '', colors);

%% Render with Mitsuba and PBRT
toneMapFactor = 10;
isScale = true;
for renderer = {'Mitsuba', 'PBRT'}
    hints.renderer = renderer{1};
    nativeSceneFiles = rtbMakeSceneFiles(parentSceneFile, '', mappingsFile, hints);
    radianceDataFiles = rtbBatchRender(nativeSceneFiles, hints);
    montageName = sprintf('%s (%s)', 'ComplexScene', hints.renderer);
    montageFile = [montageName '.png'];
    [SRGBMontage, XYZMontage] = ...
        rtbMakeMontage(radianceDataFiles, montageFile, toneMapFactor, isScale, hints);
    rtbShowXYZAndSRGB([], SRGBMontage, montageName);
end
