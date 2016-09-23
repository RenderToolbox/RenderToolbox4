classdef RtbColladaStrategy < RtbBatchRenderStrategy
    %% Implementation for how batch process with Collada.
    %
    % This implements a batch rendering strategy for the "old" way of doing
    % things with Collada and plain text mappings files.  This is intended
    % to reproduce functionality from RenderToolbox4, version 2, including
    % the functions MakeSceneFiles and BatchRender, the RemodelerPluginAPI.
    %
    % Here are some conventions -- how the Collada way of doing things fits
    % into the Strategy outline:
    %   - the basic scene representation is the name of the Collada file
    %   - conditoins are the usual tabular text file
    %   - mappings are the "old" plain text syntax
    %   - the native scene representation has two parts:
    %       - nativeScene.scene is info about the native scene file
    %       - nativeScene.adjustments holds data from mappings
    %   - resolveResources is a no-op because the work is already done by
    %   ResolveMappingsValues(), in applyVariablesToMappings
    %   - don't try to pass the "adjustmetns" file to
    %   ResolveMappingsValues().  We never use it.
    %
    
    properties
        hints = [];
    end
    
    methods
        function obj = RtbColladaStrategy(hints)
            obj.hints = hints;
            obj.converter = RtbPluginConverter(hints);
            obj.renderer = RtbPluginRenderer(hints);
        end
    end
    
    methods
        function scene = loadScene(obj, sceneFile)
            % look carefully for the file
            [scenePath, sceneBase, sceneExt] = fileparts(sceneFile);
            if isempty(scenePath) && exist(sceneFile, 'file')
                fileInfo = rtbResolveFilePath(sceneFile, rtbWorkingFolder('hints', obj.hints));
                sceneFile = fileInfo.absolutePath;
            end
            
            % strip out non-ascii 7-bit characters
            tempFolder = rtbWorkingFolder( ...
                'folderName', 'temp', ...
                'rendererSpecific', true, ...
                'hints', obj.hints);
            collada7Bit = fullfile(tempFolder, [sceneBase '-7bit' sceneExt]);
            WriteASCII7BitOnly(sceneFile, collada7Bit);
            
            % clean up Collada elements and resource paths
            colladaDoc = ReadSceneDOM(collada7Bit);
            workingFolder = rtbWorkingFolder('hints', obj.hints);
            cleanDoc = CleanUpColladaDocument(colladaDoc, workingFolder);
            sceneCopy = fullfile(tempFolder, [sceneBase '-7bit-clean' sceneExt]);
            WriteSceneDOM(sceneCopy, cleanDoc);
            
            % call out the original Collada authoring tool (Blender, etc.)
            authoringTool = GetColladaAuthorInfo(sceneFile);
            fprintf('Original Collada scene authored with %s.\n\n', authoringTool);
            
            % the basic scene is just the file name
            scene = sceneCopy;
        end
        
        function scene = remodelOnceBeforeAll(obj, scene)
            scene = obj.remodelCollada(scene, 'BeforeAll');
        end
        
        function [names, allValues] = loadConditions(obj, conditionsFile)
            if isempty(conditionsFile)
                % no conditions, do a single rendering
                names = {};
                allValues = {};
                
            else
                % read variables and values for each condition
                [names, allValues] = rtbParseConditions(conditionsFile);
            end
        end
        
        function mappings = loadMappings(obj, mappingsFile)
            if isempty(mappingsFile)
                mappingsFile = fullfile(rtbRoot(), ...
                    'BatchRenderer', 'Collada', 'Deprecated', 'RenderData', ...
                    'DefaultMappings.txt');
            end
            mappings = ParseMappings(mappingsFile);
        end
        
        function [sceneOut, mappings] = applyVariablesToMappings(obj, sceneIn, mappings, names, conditionValues, conditionNumber)

            % isolate this condition with a scene file copy
            [scenePath, sceneBase, sceneExt] = fileparts(sceneIn);
            sceneSuffix = sprintf('%03d', conditionNumber);
            sceneOut = fullfile(scenePath, [sceneBase '-' sceneSuffix sceneExt]);
            copyfile(sceneIn, sceneOut, 'f');
            
            mappings = ResolveMappingsValues(mappings, names, conditionValues, sceneIn, [], obj.hints);
        end
        
        function [scene, mappings] = resolveResources(obj, scene, mappings)
            % no-op, handled in applyVariablesToMappings
        end
        
        function [scene, mappings] = remodelPerConditionBefore(obj, scene, mappings, names, conditionValues, conditionNumber)
            scene = obj.remodelCollada(scene, 'BeforeCondition', ...
                mappings, names, conditionValues, conditionNumber);
        end
        
        function [scene, mappings] = applyBasicMappings(obj, scene, mappings, names, conditionValues, conditionNumber)
            if isempty(scene)
                return;
            end
            
            groupName = rtbGetNamedValue(names, conditionValues, 'groupName', '');
            
            % apply Collada mappings to the scene
            if ~isempty(mappings)
                
                blockNums = [mappings.blockNumber];
                for bb = unique(blockNums)
                    % get all mappings from one block
                    blockMappings = mappings(bb == blockNums);
                    blockGroup = blockMappings(1).group;
                    blockType = blockMappings(1).blockType;
                    
                    % choose mappings for an active groupName
                    isInGroup = isempty(groupName) ...
                        || isempty(blockGroup) || strcmp(groupName, blockGroup);
                    
                    if any(isInGroup)
                        switch blockType
                            case 'Collada'
                                % DOM paths apply directly to Collada
                                [colladaDoc, colladaIDMap] = ReadSceneDOM(scene);
                                ApplySceneDOMPaths(colladaIDMap, blockMappings);
                                WriteSceneDOM(scene, colladaDoc);
                        end
                    end
                end
            end
        end
        
        function [scene, mappings] = remodelPerConditionAfter(obj, scene, mappings, names, conditionValues, conditionNumber)
            scene = obj.remodelCollada(scene, 'AfterCondition', ...
                mappings, names, conditionValues, conditionNumber);
        end
    end
    
    methods (Access = private)
        %% Locate a remodeler API funciton and call it.
        function colladaCopy = remodelCollada(obj, colladaFile, functionName, varargin)
            
            if isempty(colladaFile) || isempty(obj.hints.remodeler)
                colladaCopy = colladaFile;
                return;
            end
            
            remodelerFunction = GetRemodelerAPIFunction(functionName, obj.hints);
            if isempty(remodelerFunction)
                colladaCopy = colladaFile;
                return;
            end
            
            % read original Collada document into memory
            [scenePath, sceneBase, sceneExt] = fileparts(colladaFile);
            if isempty(scenePath) && 2 == exist(colladaFile, 'file')
                info = rtbResolveFilePath(colladaFile, rtbWorkingFolder('hints', obj.hints));
                colladaFile = info.absolutePath;
            end
            colladaDoc = ReadSceneDOM(colladaFile);
            
            % apply the remodeler function
            colladaDoc = feval(remodelerFunction, colladaDoc, varargin{:}, obj.hints);
            
            % write modified document to new file
            tempFolder = fullfile(rtbWorkingFolder( ...
                'folderName', 'temp', ...
                'rendererSpecific', true, ...
                'hints', obj.hints));
            colladaCopy = fullfile(tempFolder, [sceneBase '-' functionName sceneExt]);
            WriteSceneDOM(colladaCopy, colladaDoc);
        end
    end
end
