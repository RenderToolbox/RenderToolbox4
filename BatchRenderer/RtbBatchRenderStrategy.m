classdef RtbBatchRenderStrategy < handle
    %% Abstract interface for how to do batch rendering.
    % We have at least two ways to do things with RenderToolbox4: the
    % original, deprecated way with Collada scenes and text mappings files,
    % and the new way with Assimp and JSON mappings files.  We
    % think the new way is better.  But we still want to be able to do
    % things the old way, at least for the foreseeable future.
    %
    % So we define this idea of a batch render "strategy".  It's an outline
    % of what we need to get done when batch rendering.  We reimplement the
    % batch rendering functions to follow this abstract outline.  Then we
    % will implement two or more concrete strategies: one for the old
    % Collada way of doing things, and one for the new Assimp and JSON.
    %
    % All of this deals with the basic scene representation (ie Collada
    % file vs Mexximp struct).  When it comes to the renderer, we delegate
    % to an RtbConverter and an RtbRenderer. The converter knows how to
    % convert the basic scene representation to a renderer-native format.
    % The renderer doesn't care about the basic scene representation, and
    % only deals with the renderer-native format.
    %
    
    properties
        % which RtbConverter to use
        converter;
        
        % which RtbRenderer to use
        renderer;
    end
    
    methods (Abstract)
        % load basic scene representation from file
        scene = loadScene(obj, sceneFile);
        
        % hook to alter the basic scene representation
        scene = remodelOnceBeforeAll(obj, scene);
        
        % load variable names and values from file
        [names, allValues] = loadConditions(obj, conditionsFile);
        
        % load scene alteration instructions from file
        mappings = loadMappings(obj, mappingsFile);
        
        % modify scene or mappings for the next condition
        [scene, mappings] = applyVariablesToMappings(obj, scene, mappings, names, conditionValues, conditionNumber);
        
        % modify scene or mappings for locally available files
        [scene, mappings] = resolveResources(obj, scene, mappings);
        
        % hook to alter the basic scene representation or mappings
        [scene, mappings] = remodelPerConditionBefore(obj, scene, mappings, names, conditionValues, conditionNumber);
        
        % alter the basic scene representation based on mappings
        [scene, mappings] = applyBasicMappings(obj, scene, mappings, names, conditionValues, conditionNumber);
        
        % hook to alter the basic scene representation or mappings
        [scene, mappings] = remodelPerConditionAfter(obj, scene, mappings, names, conditionValues, conditionNumber);
    end
end
