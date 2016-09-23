classdef RtbPluginConverter < handle
    %% Implementation for how to make scene files with the RendererPluginAPI.
    %
    % This class is a bridge between the "old" way of finding renderers
    % using functions that have conventional names, and the "new" way of
    % subclassing an abstract renderer supertype.
    %
    
    properties
        hints = [];
    end
    
    methods
        function obj = RtbPluginConverter(hints)
            obj.hints = hints;
        end
        
        function defaultMappings = loadDefaultMappings(obj, varargin)
            defaultMappings = [];
        end
        
        function nativeScene = startConversion(obj, parentScene, mappings, names, conditionValues, conditionNumber)
            applyMappingsFunction = GetRendererAPIFunction('ApplyMappings', obj.hints);
            if isempty(applyMappingsFunction)
                nativeScene = [];
                return;
            end
            nativeScene.adjustments = feval(applyMappingsFunction, [], []);
        end
        
        function nativeScene = applyMappings(obj, parentScene, nativeScene, mappings, names, conditionValues, conditionNumber)
            groupName = rtbGetNamedValue(names, conditionValues, 'groupName', '');
            
            applyMappingsFunction = GetRendererAPIFunction('ApplyMappings', obj.hints);
            if isempty(applyMappingsFunction)
                return;
            end
            
            % apply native mappings
            rendererName = obj.hints.renderer;
            rendererPathName = [rendererName '-path'];
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
                            case 'Generic'
                                % scene targets apply to adjustments
                                objects = MappingsToObjects(blockMappings);
                                objects = SupplementGenericObjects(objects);
                                nativeScene.adjustments = ...
                                    feval(applyMappingsFunction, objects, nativeScene.adjustments);
                                
                            case rendererName
                                % scene targets to apply to adjustments
                                objects = MappingsToObjects(blockMappings);
                                nativeScene.adjustments = ...
                                    feval(applyMappingsFunction, objects, nativeScene.adjustments);
                                
                            case rendererPathName
                                % collada path to apply to adjustments
                                nativeScene.adjustments = ...
                                    feval(applyMappingsFunction, blockMappings, nativeScene.adjustments);
                        end
                    end
                end
            end
        end
        
        function nativeScene = finishConversion(obj, parentScene, nativeScene, mappings, names, conditionValues, conditionNumber)
            
            if isempty(parentScene)
                nativeScene = [];
                return;
            end
            
            % extract some conditions
            imageName = rtbGetNamedValue( ...
                names, conditionValues, 'imageName', sprintf('scene-%03d', conditionNumber));
            
            localHints = obj.hints;
            localHints.imageHeight = StringToVector(rtbGetNamedValue( ...
                names, conditionValues, 'imageHeight', localHints.imageHeight));
            localHints.imageWidth = StringToVector(rtbGetNamedValue( ...
                names, conditionValues, 'imageWidth', localHints.imageWidth));
            
            % convert the scene to native
            importColladaFunction = GetRendererAPIFunction('ImportCollada', localHints);
            if isempty(importColladaFunction)
                return;
            end
            nativeScene.scene = feval(importColladaFunction, ...
                parentScene, ...
                nativeScene.adjustments, ...
                imageName, ...
                localHints);
            nativeScene.scene.imageName = imageName;
            
            % add Collada author info for good measure
            [authoringTool, asset] = GetColladaAuthorInfo(parentScene);
            authorInfo.authoringTool = authoringTool;
            authorInfo.asset = asset;
            nativeScene.scene.authorInfo = authorInfo;
        end
    end
end
