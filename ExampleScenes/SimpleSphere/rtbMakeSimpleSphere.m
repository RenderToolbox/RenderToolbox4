%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
%% Render a Ward sphere under a point light and orthogonal camera.

%% Choose example files.
parentSceneFile = 'SimpleSphere.blend';
mappingsFile = 'SimpleSphereMappings.json';


%% Choose batch renderer options.
hints.imageWidth = 201;
hints.imageHeight = 201;
hints.recipeName = 'rtbMakeSimpleSphere';


%% Render with Mitsuba and PBRT.

% how to convert multi-spectral images to sRGB
toneMapFactor = 10;
isScale = true;

% make a montage and sensor images with each renderer
for renderer = {'Mitsuba', 'PBRT'}
    
    % choose one renderer
    hints.renderer = renderer{1};
        
    % make multi-spectral renderings, saved in .mat files
    nativeSceneFiles = rtbMakeSceneFiles(parentSceneFile, ...
        'mappingsFile', mappingsFile, ...
        'hints', hints);
    radianceDataFiles = rtbBatchRender(nativeSceneFiles, ...
        'hints', hints);
    
    % display a montage
    montageName = sprintf('rtbMakeSimpleSphere (%s)', hints.renderer);
    montageFile = [montageName '.png'];
    SRGBMontage = rtbMakeMontage(radianceDataFiles, ...
        'outFile', montageFile, ...
        'toneMapFactor', toneMapFactor, ...
        'isScale', isScale, ...
        'hints', hints);
    rtbShowXYZAndSRGB([], SRGBMontage, montageName);
end
