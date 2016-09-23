classdef RtbPBRTRenderer < RtbRenderer
    %% Implementation for rendering with Mitsuba.
    
    properties
        % RenderToolbox4 options struct, see rtbDefaultHints()
        hints = [];
        
        % pbrt info struct
        pbrt;
        
        % where to write output files
        outputFolder;
        
        % where to put scenes before rendering
        workingFolder;
    end
    
    methods
        function obj = RtbPBRTRenderer(hints)
            obj.hints = rtbDefaultHints(hints);
            obj.pbrt = getpref('PBRT');
            obj.outputFolder = rtbWorkingFolder( ...
                'folderName', 'renderings', ...
                'rendererSpecific', true, ...
                'hints', obj.hints);
            obj.workingFolder = rtbWorkingFolder('hints', obj.hints);
        end
        
        function info = versionInfo(obj)
            try
                info = dir(obj.pbrt.executable);
            catch err
                info = err;
            end
        end
        
        function [status, result, image, sampling, imageName] = render(obj, nativeScene)
            % look carefully for the file
            [~, imageName] = fileparts(nativeScene);
            fileInfo = rtbResolveFilePath(nativeScene, obj.workingFolder);
            nativeScene = fileInfo.absolutePath;
            
            % build a pbrt command
            outFile = fullfile(obj.outputFolder, [imageName '.dat']);
            renderCommand = sprintf('pbrt --outfile %s %s', ...
                outFile, ...
                nativeScene);
            
            % run in a container or locally
            if rtbDockerExists()
                [status, result] = rtbRunDocker(renderCommand, ...
                    obj.pbrt.dockerImage, ...
                    'workingFolder', obj.workingFolder, ...
                    'volumes', {obj.workingFolder, rtbRoot()}, ...
                    'hints', obj.hints);
            elseif rtbKubernetesExists()
                [status, result] = rtbRunKubernetes(renderCommand, ...
                    obj.pbrt.kubernetesPodSelector, ...
                    'workingFolder', obj.workingFolder, ...
                    'hints', obj.hints);
            else
                pbrtPath = fileparts(fullfile(obj.pbrt.app, obj.pbrt.executable));
                renderCommand = sprintf('%s="%s" "%s%s"%s', ...
                    obj.pbrt.libraryPathName, ...
                    obj.pbrt.libraryPath, ...
                    pbrtPath, ...
                    filesep(), ...
                    renderCommand);
                [status, result] = rtbRunCommand(renderCommand, 'hints', obj.hints);
            end
            
            if status ~= 0
                error('RtbPbrtRenderer:pbrtError', result);
            end
            
            sampling = obj.pbrt.S;
            image = rtbReadDAT(outFile, 'maxPlanes', sampling(3));
        end
        
        function [radianceImage, scaleFactor] = toRadiance(obj, image, sampling, nativeScene)
            scaleFactor = obj.pbrt.radiometricScaleFactor;
            radianceImage = image .* scaleFactor;
        end
    end
end
