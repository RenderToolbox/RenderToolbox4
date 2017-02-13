classdef RtbSampleRendererRenderer < RtbRenderer
    %% Implementation for how to render with the RendererPluginAPI.
    %
    % This class is a bridge between the "old" way of finding renderers
    % using functions that have conventional names, and the "new" way of
    % subclassing an abstract renderer supertype.
    %
    
    properties
        hints = [];
    end
    
    methods
        function obj = RtbSampleRendererRenderer(hints)
            obj.hints = hints;
        end
        
        function info = versionInfo(obj)
            info = [];
        end
        
        function [status, result, image, sampling, imageName] = render(obj, nativeScene)
            status = 0;
            result = '';
            image = nan(obj.hints.imageHeight, obj.hints.imageWidth);
            sampling = [400 10 1];
            imageName = '';
        end
        
        function [radianceImage, scaleFactor] = toRadiance(obj, image, sampling, nativeScene)
            radianceImage = image;
            scaleFactor = 0;
        end
    end
end
