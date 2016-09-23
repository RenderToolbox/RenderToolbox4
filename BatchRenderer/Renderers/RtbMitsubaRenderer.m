classdef RtbMitsubaRenderer < RtbRenderer
    %% Implementation for rendering with Mitsuba.
    
    properties
        % RenderToolbox4 options struct, see rtbDefaultHints()
        hints = [];
        
        % Mitsuba info struct
        mitsuba;
        
        % where to write output files
        outputFolder;
    end
    
    methods
        function obj = RtbMitsubaRenderer(hints)
            obj.hints = rtbDefaultHints(hints);
            obj.mitsuba = getpref('Mitsuba');
            obj.outputFolder = rtbWorkingFolder( ...
                'folderName', 'renderings', ...
                'rendererSpecific', true, ...
                'hints', obj.hints);
        end
        
        function info = versionInfo(obj)
            try
                executable = fullfile(obj.mitsuba.app, obj.mitsuba.executable);
                info = dir(executable);
            catch err
                info = err;
            end
        end
        
        function [status, result, mitsubaOut] = importCollada(obj, colladaIn, mitsubaOut)
            % look carefully for the input file
            workingFolder = rtbWorkingFolder('hints', obj.hints);
            fileInfo = rtbResolveFilePath(colladaIn, workingFolder);
            colladaIn = fileInfo.absolutePath;
            
            % build a mtsimport command
            importCommand = sprintf('mtsimport -r %dx%d -l %s "%s" "%s"', ...
                obj.hints.imageWidth, obj.hints.imageHeight, ...
                obj.hints.filmType, ...
                colladaIn, ...
                mitsubaOut);
            
            % run in a container or locally
            if rtbDockerExists()
                % run as user '' aka root, to start an X server
                [status, result] = rtbRunDocker(importCommand, ...
                    obj.mitsuba.dockerImage, ...
                    'user', '', ...
                    'workingFolder', workingFolder, ...
                    'volumes', {workingFolder, rtbRoot()}, ...
                    'hints', obj.hints);
            elseif rtbKubernetesExists()
                [status, result] = rtbRunKubernetes(importCommand, ...
                    obj.mitsuba.kubernetesPodSelector, ...
                    'workingFolder', workingFolder, ...
                    'hints', obj.hints);
            else
                mitsubaPath = fileparts(fullfile(obj.mitsuba.app, obj.mitsuba.executable));
                renderCommand = sprintf('%s="%s" "%s%s"%s', ...
                    obj.mitsuba.libraryPathName, ...
                    obj.mitsuba.libraryPath, ...
                    mitsubaPath, ...
                    filesep(), ...
                    importCommand);
                [status, result] = rtbRunCommand(renderCommand, 'hints', obj.hints);
            end
            
            if status ~= 0
                error('RtbMitsubaRenderer:mtsimportError', result);
            end

        end
        
        function [status, result, outFile, imageName] = renderToExr(obj, nativeScene)
            % look carefully for the input file
            [~, imageName] = fileparts(nativeScene);
            workingFolder = rtbWorkingFolder('hints', obj.hints);
            fileInfo = rtbResolveFilePath(nativeScene, workingFolder);
            nativeScene = fileInfo.absolutePath;
            
            % build a mitsuba command
            outFile = fullfile(obj.outputFolder, [imageName '.exr']);
            renderCommand = sprintf('mitsuba -o "%s" "%s"', ...
                outFile, ...
                nativeScene);
            
            % run in a container or locally
            if rtbDockerExists()
                [status, result] = rtbRunDocker(renderCommand, ...
                    obj.mitsuba.dockerImage, ...
                    'workingFolder', workingFolder, ...
                    'volumes', {workingFolder, rtbRoot()}, ...
                    'hints', obj.hints);
            elseif rtbKubernetesExists()
                [status, result] = rtbRunKubernetes(renderCommand, ...
                    obj.mitsuba.kubernetesPodSelector, ...
                    'workingFolder', workingFolder, ...
                    'hints', obj.hints);
            else
                mitsubaPath = fileparts(fullfile(obj.mitsuba.app, obj.mitsuba.executable));
                renderCommand = sprintf('%s="%s" "%s%s"%s', ...
                    obj.mitsuba.libraryPathName, ...
                    obj.mitsuba.libraryPath, ...
                    mitsubaPath, ...
                    filesep(), ...
                    renderCommand);
                [status, result] = rtbRunCommand(renderCommand, 'hints', obj.hints);
            end
            
            if status ~= 0
                error('RtbMitsubaRenderer:mitsubaError', result);
            end
        end
        
        function [status, result, image, sampling, imageName] = render(obj, nativeScene)
            [status, result, outFile, imageName] = obj.renderToExr(nativeScene);
            [image, ~, sampling] = rtbReadMultispectralEXR(outFile);
        end
        
        function [radianceImage, scaleFactor] = toRadiance(obj, image, sampling, nativeScene)
            scaleFactor = obj.mitsuba.radiometricScaleFactor;
            radianceImage = image .* scaleFactor;
        end
    end
end
