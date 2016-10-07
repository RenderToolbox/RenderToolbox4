function outFiles = rtbBatchRender(nativeScenes, varargin)
% Render multiple nativeScenes at once.
%
% outFiles = rtbBatchRender(nativeScenes)
% Renders multiple renderer-native scene files in one batch.  scenes
% must be a cell array of renderer-native scene descriptions or scene
% files, such as those produced by rtbMakeSceneFiles().  All renderer-native
% files should be intended for the same renderer.
%
% outFiles = rtbBatchRender(... 'hints', hints)
% Specify a hints struct with with options that affect the rendering
% process, as returned from rtbDefaultHints().  If hints is omitted,
% default options are used.  For example:
%   - hints.strategy specifies how to load and manipulate scene data (e.g.
%   Collada vs Assimp).  The default is RtbAssimpStrategy.
%   - hints.renderer specifies which renderer to target
%
% Renders each renderer-native scene in scenes, and writes a new mat-file
% for each one.  Each mat-file will contain several variables including:
%   - multispectralImage - matrix of multi-spectral radiance data with size
%   [height width n]
%   - S - spectral band description for the rendering with elements [start
%   delta n]
%
% height and width are pixel image dimensions and n is the number of
% spectral bands in the image.  See the RenderToolbox4 wiki for more about
% spectrum bands:
%  https://github.com/DavidBrainard/RenderToolbox4/wiki/Spectrum-Bands
%
% The each mat-file will also contain variables with metadata about how the
% scene was made and rendererd:
%   - scene - the renderer-native scene description (e.g. file name,
%   Collada author info)
%   - hints - the given hints struct, or default hints struct
%   - versionInfo - struct of version information about RenderToolbox4,
%   its dependencies, and the current renderer
%   - commandResult - text output from the the current renderer
%   - radiometricScaleFactor - scale factor that was used to bring renderer
%   ouput into physical radiance units
%
% Returns a cell array of output mat-file names, with the same dimensions
% as the given scenes.
%
% outFiles = rtbBatchRender(scenes, varargin)
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('nativeScenes', @iscell);
parser.addParameter('hints', rtbDefaultHints(), @isstruct);
parser.parse(nativeScenes, varargin{:});
nativeScenes = parser.Results.nativeScenes;
hints = rtbDefaultHints(parser.Results.hints);

%% Choose the batch rendering strategy.
strategy = rtbChooseStrategy('hints', hints);


%% Record toolbox and renderer version info.
versionInfo = rtbVersionInfo();
versionInfo.rendererVersionInfo = strategy.renderer.versionInfo();


%% Render each scene file.
fprintf('\nBatchRender started with isParallel=%d at %s.\n\n', ...
    hints.isParallel, datestr(now(), 0));
renderTick = tic();

nScenes = numel(nativeScenes);
outFiles = cell(size(nativeScenes));
if hints.isParallel
    % distributed "parfor" loop, don't time individual iterations
    parfor ii = 1:nScenes
        outFiles{ii} = renderScene(strategy, nativeScenes{ii}, versionInfo, hints);
    end
    
else
    % local "for" loop, makes sense to time each iteration
    for ii = 1:nScenes
        fprintf('\nStarting scene %d of %d at %s (%.1fs elapsed).\n\n', ...
            ii, nScenes, datestr(now(), 0), toc(renderTick));
        
        outFiles{ii} = renderScene(strategy, nativeScenes{ii}, versionInfo, hints);
        
        fprintf('\nFinished scene %d of %d at %s (%.1fs elapsed).\n\n', ...
            ii, nScenes, datestr(now(), 0), toc(renderTick));
    end
end

fprintf('\nBatchRender finished at %s (%.1fs elapsed).\n\n', ...
    datestr(now(), 0), toc(renderTick));


%% Render a scene and save a .mat data file.
function outFile = renderScene(strategy, scene, versionInfo, hints)

% invoke the renderer and convert to radiance
[status, commandResult, multispectralImage, S, imageName] = ...
    strategy.renderer.render(scene);
[multispectralImage, radiometricScaleFactor] = ...
    strategy.renderer.toRadiance(multispectralImage, S, scene);

% save a .mat file with multispectral data and metadata
outPath = rtbWorkingFolder( ...
    'folderName', 'renderings', ...
    'rendererSpecific', true, ...
    'hints', hints);
outFile = fullfile(outPath, [imageName '.mat']);
save(outFile, 'multispectralImage', 'S', 'radiometricScaleFactor', ...
    'hints', 'scene', 'versionInfo', 'commandResult');
