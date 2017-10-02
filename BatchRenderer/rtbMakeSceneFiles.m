function nativeScenes = rtbMakeSceneFiles(parentScene, varargin)
%% Make a family of renderer-native scenes based on a given parent scene.
%
% nativeScenes = rtbMakeSceneFiles(parentScene, varargin)
%
% Input
%  parentScene - Describe, please
%
% Return
%  nativeScenes - File names of the scenes for the specific renderer (e.g., PBRT)
%                 The scene files are written to disk by the relevant converter,
%                 say RtbAssimpPBRTConverter.finishConversion for PBRT.
%
% Parameter/values
%   'conditionsFIle'
%   'mappingsFile'
%   'hints'
%
% scenes = rtbMakeSceneFiles(parentScene)
%   Creates a renderer-native scene based on the parentScene.  The parentScene
%   format is described in XXXX.
%
% scenes = rtbMakeSceneFiles(... 'conditionsFile', conditionsFile)
%   Specify the conditionsFile which specifies how many scenes to generate
%   and parameters for each scene.  If conditionsFile contains an 'imageName'
%   variable, each scene file is named with the value of 'imageName'.
%   See the RenderToolbox wiki for the conditions file format:
%     https://github.com/RenderToolbox/RenderToolbox4/wiki/Conditions-File-Format
%
% scenes = rtbMakeSceneFiles(... 'mappingsFile', mappingsFile)
%   Specify the mappingsFile which specifies how to map conditions file
%   variables and other constants to the parent scene.  See the
%   RenderToolbox wiki for more about the mappings file format:
%    https://github.com/RenderToolbox/RenderToolbox4/wiki/Mappings-File-Format
%   (Not yet used by Stanford group)
%
% scenes = rtbMakeSceneFiles(... 'hints', hints)
%   Specify a struct of options that affect the process of generating
%   renderer-native scene files.
%    - hints.strategy specifies how to load and manipulate scene data (e.g.
%      Collada vs Assimp).  The default is RtbAssimpStrategy.
%    - hints.renderer specifies which renderer to target
%    - hints.imageHeight and hints.imageWidth specify the image pixel
%      dimensions to specify for the scene
%   If hints is omitted, values are taken from rtbDefaultHints().
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('parentScene');
parser.addParameter('conditionsFile', '', @ischar);
parser.addParameter('mappingsFile', '', @ischar);
parser.addParameter('hints', rtbDefaultHints(), @isstruct);
parser.parse(parentScene, varargin{:});
parentScene = parser.Results.parentScene;
conditionsFile = parser.Results.conditionsFile;
mappingsFile = parser.Results.mappingsFile;
hints = rtbDefaultHints(parser.Results.hints);

fprintf('\nMakeSceneFiles started at %s.\n\n', datestr(now(), 0));

%% Attempt to locate scene in case it's a relative path.
if ~isempty(parentScene) && ischar(parentScene) && 2 ~= exist(parentScene, 'file')
    workingFolder = rtbWorkingFolder('hints', hints);
    sceneInfo = rtbResolveFilePath(parentScene, workingFolder);
    parentScene = sceneInfo.absolutePath;
end

%% Choose the batch rendering strategy.
strategy = rtbChooseStrategy('hints', hints);

%% Read conditions file into memory.
if isempty(conditionsFile) || 2 ~= exist(conditionsFile, 'file')
    % no conditions, do a single rendering
    nConditions = 1;
    names = {};
    values = {};
    
else
    % read variables and values for each condition
    [names, values] = strategy.loadConditions(conditionsFile);
    
    % choose which conditions to render
    if isempty(hints.whichConditions)
        hints.whichConditions = 1:size(values, 1);
    end
    nConditions = numel(hints.whichConditions);
    values = values(hints.whichConditions,:);
end


%% Read mappings file into memory.
mappings = strategy.loadMappings(mappingsFile);

%% Read the scene into memory.
if isempty(parentScene)
    scene = [];
else
    scene = strategy.loadScene(parentScene);
    scene = strategy.remodelOnceBeforeAll(scene);
end


%% Make a renderer-native scene file for each condition.
nativeScenes = cell(1, nConditions);

fprintf('\nMakeSceneFiles started with isParallel=%d at %s.\n\n', ...
    hints.isParallel, datestr(now(), 0));
makeScenesTick = tic();

if hints.isParallel
    % distributed "parfor" loop
    
    [status, nCores] = system('nproc');
    
    if status == 0
        cluster = parcluster();
        cluster.NumWorkers = str2double(nCores) - 1;
        parpool(cluster,cluster.NumWorkers);
    end
    
    parfor cc = 1:nConditions
        % choose variable values for this condition
        if isempty(values)
            conditionValues = {};
        else
            conditionValues = values(cc,:);
        end
        fprintf('Making scene for condition %i.\n', cc);
        
        % make a the scene file for this condition
        nativeScenes{cc} = makeSceneForCondition(strategy, ...
            scene, mappings, cc, names, conditionValues, hints);
    end
    
    delete(gcp);
    
else
    % local "for" loop
    for cc = 1:nConditions
        % choose variable values for this condition
        if isempty(values)
            conditionValues = {};
        else
            conditionValues = values(cc,:);
        end
        
        % make a the scene file for this condition
        nativeScenes{cc} = makeSceneForCondition(strategy, ...
            scene, mappings, cc, names, conditionValues, hints);
    end
end

fprintf('\nMakeSceneFiles finished at %s (%.1fs elapsed).\n\n', ...
    datestr(now(), 0), toc(makeScenesTick));


%% Create a renderer-native scene description for one condition.
function nativeScene = makeSceneForCondition(strategy, ...
    scene, mappings, cc, names, conditionValues, hints)

% possibly load a new scene named in the conditions file
parentScene = rtbGetNamedValue(names, conditionValues, 'parentScene', '');
if ~isempty(parentScene)
    scene = strategy.loadScene(parentScene);
    scene = strategy.remodelOnceBeforeAll(scene);
end

% possibly load new mappings named in the conditions file
mappingsFile = rtbGetNamedValue(names, conditionValues, 'mappingsFile', '');
if ~isempty(mappingsFile)
    mappings = strategy.loadMappings(mappingsFile);
end

if isempty(scene)
    nativeScene = [];
    return;
end

% update the mappings for this condition
[scene, mappings] = strategy.applyVariablesToMappings(scene, mappings, names, conditionValues, cc);
[scene, mappings] = strategy.resolveResources(scene, mappings);

% apply basic mappings to the scene
[scene, mappings] = strategy.remodelPerConditionBefore(scene, mappings, names, conditionValues, cc);
[scene, mappings] = strategy.applyBasicMappings(scene, mappings, names, conditionValues, cc);
[scene, mappings] = strategy.remodelPerConditionAfter(scene, mappings, names, conditionValues, cc);

% apply renderer-specific mappings to the scene.
nativeScene = strategy.converter.startConversion(scene, mappings, names, conditionValues, cc);
nativeScene = strategy.converter.remodelBeforeMappings(scene, nativeScene, mappings, names, conditionValues, cc);
nativeScene = strategy.converter.applyMappings(scene, nativeScene, mappings, names, conditionValues, cc);
nativeScene = strategy.converter.remodelAfterMappings(scene, nativeScene, mappings, names, conditionValues, cc);
nativeScene = strategy.converter.finishConversion(scene, nativeScene, mappings, names, conditionValues, cc);
