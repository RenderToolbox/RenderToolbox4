classdef RtbConverter < handle
    %% Abstract interface for how to make scene files.
    % Defines the outline for how to convert a basic scene representation
    % into a renderer-native format.
    %
    
    properties
        remodelBeforeMappingsFunction = [];
        remodelAfterMappingsFunction = [];
    end
    
    methods (Abstract)
        % Build the default mappings for this renderer.
        defaultMappings = loadDefaultMappings(obj, varargin);
        
        % Convert the scene to native format, or return a placeholder.
        nativeScene = startConversion(obj, parentScene, mappings, names, conditionValues, conditionNumber);
        
        % Apply mappings to adjust the native scene in progress.
        nativeScene = applyMappings(obj, parentScene, nativeScene, mappings, names, conditionValues, conditionNumber);
        
        % Convert the scene to native format, if not done yet.
        nativeScene = finishConversion(obj, parentScene, nativeScene, mappings, names, conditionValues, conditionNumber);
    end
    
    methods
        % Optional hook to modify native scene before mappings are applied.
        function nativeScene = remodelBeforeMappings(obj, parentScene, nativeScene, mappings, names, conditionValues, conditionNumber)
            if isempty(obj.remodelBeforeMappingsFunction)
                return;
            end
            nativeScene = feval(obj.remodelBeforeMappingsFunction, parentScene, nativeScene, mappings, names, conditionValues, conditionNumber);
        end
        
        % Optional hook to modify native scene after mappings are applied.
        function nativeScene = remodelAfterMappings(obj, parentScene, nativeScene, mappings, names, conditionValues, conditionNumber)
            if isempty(obj.remodelAfterMappingsFunction)
                return;
            end
            nativeScene = feval(obj.remodelAfterMappingsFunction, parentScene, nativeScene, mappings, names, conditionValues, conditionNumber);
        end
    end
end
