%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
%% Render the Dice scene, with a texture.

%% Choose example files, make sure they're on the Matlab path.
parentSceneFile = 'Dice.dae';
mappingsFile = 'DiceTransformationsMappings.json';
conditionsFile = 'DiceTransformationsConditions.txt';

%% Choose batch renderer options.
hints.fov = 49.13434 * pi() / 180;
hints.imageWidth = 640;
hints.imageHeight = 480;
hints.recipeName = 'rtbMakeDiceTransformations';

%% Render with Mitsuba and PBRT.
toneMapFactor = 100;
isScale = true;
for renderer = {'Mitsuba', 'PBRT'}
    hints.renderer = renderer{1};
    
    nativeSceneFiles = rtbMakeSceneFiles(parentSceneFile, ...
        'conditionsFile', conditionsFile, ...
        'mappingsFile', mappingsFile, ...
        'hints', hints);
    radianceDataFiles = rtbBatchRender(nativeSceneFiles, 'hints', hints);
    
    for ii = 1:numel(radianceDataFiles)
        [~, imageName] = fileparts(radianceDataFiles{ii});
        montageName = sprintf('Dice - %s (%s)', imageName, hints.renderer);
        montageFile = [montageName '.png'];
        [SRGBMontage, XYZMontage] = ...
            rtbMakeMontage(radianceDataFiles(ii), ...
            'toneMapFactor', toneMapFactor, ...
            'isScale', isScale, ...
            'hints', hints);
        rtbShowXYZAndSRGB([], SRGBMontage, montageName);
    end
end
