classdef RtbRenderer < handle
    %% Abstract interface for how to render scenes.
    % Defines the outline for how to invoke a given renderer on a
    % renderer-native scene file.  Does not care about the original, basic
    % scene representation.
    %
    % BH, Generic renderer
    
    methods (Abstract)
        % Invoke the renderer with the native scene.
        [status, result, image, sampling, imageName] = render(obj, nativeScene);
        
        % Convert a rendering to radiance units.
        [radianceImage, scaleFactor] = toRadiance(obj, image, sampling, nativeScene);
        
        % Get renderer version info.
        info = versionInfo(obj);
    end
end
