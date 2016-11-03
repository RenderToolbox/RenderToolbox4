classdef RtbAssimpStrategy < RtbBatchRenderStrategy
    %% Implementation for how batch process with mexximp and JSON.
    %
    % This implements a batch rendering strategy for the Version 3
    % way of doing batch rendering, with mexximp and JSON mappings files.
    %
    % We choose a scene file converter and renderer based on the
    % hints.renderer passed to the constructor.
    %
    
    properties
        % options for batch rendering, see rtbDefaultHints()
        hints = [];
        
        % args to pass to mexximpCleanImport() for scene loading
        importArgs = {'ignoreRootTransform', true, 'flipUVs', true};
        
        % args to pass to loadDefaultMappings() for mappings loading
        mappingsArgs = {};
        
        % optional function_handle for remodeling
        remodelOnceBeforeAllFunction = [];
        
        % optional function_handle for remodeling
        remodelPerConditionBeforeFunction = [];
        
        % optional function_handle for remodeling
        remodelPerConditionAfterFunction = [];
    end
    
    methods
        function obj = RtbAssimpStrategy(hints, varargin)
            obj.hints = rtbDefaultHints(hints);
            obj.importArgs = cat(2, obj.importArgs, varargin);
            obj.mappingsArgs = cat(2, {hints}, varargin);
            obj.converter = RtbAssimpStrategy.chooseConverter(obj.hints);
            obj.renderer = RtbAssimpStrategy.chooseRenderer(obj.hints);
        end
    end
    
    methods (Static)
        function converter = chooseConverter(hints)
            if isobject(hints.converter)
                % pass-through for pre-constructed converter
                converter = hints.converter;
                return;
            end
            
            if isempty(hints.converter)
                % choose converter based on the renderer.
                hints.converter = hints.renderer;
            end
            
            converterName = hints.converter;
            constructorName = ['RtbAssimp' converterName 'Converter'];
            if 2 == exist(constructorName, 'file')
                converter = feval(constructorName, hints);
            else
                converter = [];
            end
        end
        
        function renderer = chooseRenderer(hints)
            if isobject(hints.renderer)
                % pass-through for pre-constructed renderer
                renderer = hints.renderer;
                return;
            end
            
            rendererName = hints.renderer;
            constructorName = ['Rtb' rendererName 'Renderer'];
            if 2 == exist(constructorName, 'file')
                renderer = feval(constructorName, hints);
            else
                renderer = [];
            end
        end
        
        function defaultMappings = loadDefaultMappings(varargin)
            parser = inputParser();
            parser.KeepUnmatched = true;
            parser.addParameter('fov', pi()/3, @isnumeric);
            parser.addParameter('imageWidth', 320, @isnumeric);
            parser.addParameter('imageHeight', 240, @isnumeric);
            parser.addParameter('lookAtDirection', [0 0 -1]', @isnumeric);
            parser.addParameter('upDirection', [0 1 0]', @isnumeric);
            parser.parse(varargin{:});
            fov = parser.Results.fov;
            imageWidth = parser.Results.imageWidth;
            imageHeight = parser.Results.imageHeight;
            lookAtDirection = parser.Results.lookAtDirection;
            upDirection = parser.Results.upDirection;
            
            mm = 1;
            defaultMappings{mm}.name = 'Camera';
            defaultMappings{mm}.broadType = 'cameras';
            defaultMappings{mm}.operation = 'update';
            defaultMappings{mm}.destination = 'mexximp';
            defaultMappings{mm}.properties(1).name = 'lookAtDirection';
            defaultMappings{mm}.properties(1).valueType = 'lookAt';
            defaultMappings{mm}.properties(1).value = lookAtDirection;
            defaultMappings{mm}.properties(2).name = 'upDirection';
            defaultMappings{mm}.properties(2).valueType = 'lookAt';
            defaultMappings{mm}.properties(2).value = upDirection;
            defaultMappings{mm}.properties(3).name = 'horizontalFov';
            defaultMappings{mm}.properties(3).valueType = 'float';
            defaultMappings{mm}.properties(3).value = fov;
            defaultMappings{mm}.properties(4).name = 'aspectRatio';
            defaultMappings{mm}.properties(4).valueType = 'float';
            defaultMappings{mm}.properties(4).value = imageWidth / imageHeight;
        end
        
        function isFileCandidate = mightBeFile(string)
            isFileCandidate = ischar(string) ...
                && ~isempty(string) ...
                && ~isempty(strfind(string, '.'));
        end
    end
    
    methods
        function scene = loadScene(obj, sceneFile)
            if isstruct(sceneFile)
                % pass-through for a pre-loaded scene
                scene = sceneFile;
                return;
            end
            
            % look carefully for the file
            [scenePath, ~, sceneExt] = fileparts(sceneFile);
            if isempty(scenePath)
                fileInfo = rtbResolveFilePath(sceneFile, rtbWorkingFolder('hints', obj.hints));
                sceneFile = fileInfo.absolutePath;
            end
            
            if strcmp('.mat', sceneExt)
                % reload pre-imported scene
                scene = mexximpLoad(sceneFile);
            else
                % import anew
                scene = mexximpCleanImport(sceneFile, obj.importArgs{:});
            end
        end
        
        function scene = remodelOnceBeforeAll(obj, scene)
            if isempty(obj.remodelOnceBeforeAllFunction)
                return;
            end
            scene = feval(obj.remodelOnceBeforeAllFunction, scene);
        end
        
        function [names, allValues] = loadConditions(obj, conditionsFile)
            [names, allValues] = rtbParseConditions(conditionsFile);
        end
        
        function mappings = loadMappings(obj, mappingsFile)
            defaultBasicMappings = RtbAssimpStrategy.loadDefaultMappings(obj.mappingsArgs{:});
            defaultConverterMappings = obj.converter.loadDefaultMappings(obj.mappingsArgs{:});
            rawMappings = cat(2, defaultBasicMappings, defaultConverterMappings);
            defaultMappings = rtbValidateMappings(rawMappings);
            sceneMappings = rtbLoadJsonMappings(mappingsFile);
            mappings = cat(2, defaultMappings, sceneMappings);
        end
        
        function [scene, mappings] = applyVariablesToMappings(obj, scene, mappings, names, conditionValues, conditionNumber)
            mappings = mexximpVisitStructFields(mappings, @rtbSubstituteStringVariables, ...
                'filterFunction', @ischar, ...
                'visitArgs', {names, conditionValues});
        end
        
        function [scene, mappings] = resolveResources(obj, scene, mappings)
            % locate files and fix up names
            resourceFolder = rtbWorkingFolder( ...
                'folderName', 'resources', ...
                'rendererSpecific', false, ...
                'hints', obj.hints);
            mappings = mexximpVisitStructFields(mappings, @rtbResourcePath, ...
                'filterFunction', @RtbAssimpStrategy.mightBeFile, ...
                'ignoreFields', {'rootNode', 'embeddedTextures', 'meshes', 'lights', 'cameras'}, ...
                'visitArgs', { ...
                'strictMatching', true, ...
                'resourceFolder', resourceFolder, ...
                'writeFullPaths', false, ...
                'relativePath', 'resources', ...
                'toReplace', ':-', ...
                'copyOnReplace', true});
            scene = mexximpVisitStructFields(scene, @rtbResourcePath, ...
                'filterFunction', @RtbAssimpStrategy.mightBeFile, ...
                'ignoreFields', {'rootNode', 'embeddedTextures', 'meshes', 'lights', 'cameras'}, ...
                'visitArgs', { ...
                'strictMatching', true, ...
                'resourceFolder', resourceFolder, ...
                'writeFullPaths', false, ...
                'relativePath', 'resources', ...
                'toReplace', ':-', ...
                'copyOnReplace', true});
            
            mappings = mexximpVisitStructFields(mappings, @mexximpRecodeImage, ...
                'filterFunction', @RtbAssimpStrategy.mightBeFile, ...
                'ignoreFields', {'rootNode', 'embeddedTextures', 'meshes', 'lights', 'cameras'}, ...
                'visitArgs', { ...
                'toReplace', {'gif'}, ...
                'targetFormat', 'png'});
            scene = mexximpVisitStructFields(scene, @mexximpRecodeImage, ...
                'filterFunction', @RtbAssimpStrategy.mightBeFile, ...
                'ignoreFields', {'rootNode', 'embeddedTextures', 'meshes', 'lights', 'cameras'}, ...
                'visitArgs', { ...
                'toReplace', {'gif'}, ...
                'targetFormat', 'png'});
        end
        
        function [scene, mappings] = remodelPerConditionBefore(obj, scene, mappings, names, conditionValues, conditionNumber)
            if isempty(obj.remodelPerConditionBeforeFunction)
                return;
            end
            [scene, mappings] = feval(obj.remodelPerConditionBeforeFunction, scene, mappings, names, conditionValues, conditionNumber);
        end
        
        function [scene, mappings] = applyBasicMappings(obj, scene, mappings, names, conditionValues, conditionNumber)
            groupName = rtbGetNamedValue(names, conditionValues, 'groupName', '');
            if isempty(groupName)
                groupMappings = mappings;
            else
                isAnyGroup = strcmp('', {mappings.group});
                isInGroup = strcmp(groupName, {mappings.group});
                groupMappings = mappings(isAnyGroup | isInGroup);
            end
            scene = rtbApplyMexximpMappings(scene, groupMappings);
        end
        
        function [scene, mappings] = remodelPerConditionAfter(obj, scene, mappings, names, conditionValues, conditionNumber)
            if isempty(obj.remodelPerConditionAfterFunction)
                return;
            end
            [scene, mappings] = feval(obj.remodelPerConditionAfterFunction, scene, mappings, names, conditionValues, conditionNumber);
        end
    end
end
