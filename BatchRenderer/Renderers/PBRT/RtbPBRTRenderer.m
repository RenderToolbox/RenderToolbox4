classdef RtbPBRTRenderer < RtbRenderer
    %% Implementation for rendering with PBRTs.
    % 
    % Creates a PBRT renderer object based on the defaults in hints
    %
    %   hints = rtbDefaultHints;
    %   pbrt = RtbPBRTRenderesr(hints)
    %
    % Relies on rtbLocalConfigTemplate, which sets RenderToolbox4 prefs
    %
    % Examples
    %    pbrt.versionInfo
    %
    % BH, sometime in the past
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
                % Run locally using docker
                [status, result] = rtbRunDocker(renderCommand, ...
                    obj.pbrt.dockerImage, ...
                    'workingFolder', obj.workingFolder, ...
                    'volumes', {obj.workingFolder, rtbRoot()}, ...
                    'hints', obj.hints);
            elseif rtbKubernetesExists()
                % Run on cloud using kubernetes
                [status, result] = rtbRunKubernetes(renderCommand, ...
                    obj.pbrt.kubernetesPodSelector, ...
                    'workingFolder', obj.workingFolder, ...
                    'hints', obj.hints);
            else
                % Run local version of pbrt
                pbrtPath = fileparts(obj.pbrt.executable);
                renderCommand = sprintf('%s%s%s', ...
                    pbrtPath, ...
                    filesep(), ...
                    renderCommand);
                [status, result] = rtbRunCommand(renderCommand, 'hints', obj.hints);
            end
            
            if status ~= 0
                error('RtbPbrtRenderer:pbrtError', result);
            end
            
            sampling = obj.pbrt.S;

            if(exist(outFile,'file') == 0)
                % Because of the cameras renderer in PBRT, there's a chance
                % that the output file will not exist. In this case, we
                % won't read anything. 
                warning('Output .dat file does not exist. Radiance image set to zero.')
                image = zeros(obj.hints.imageHeight, obj.hints.imageWidth, sampling(3));
            else
                image = rtbReadDAT(outFile, 'maxPlanes', sampling(3));
            end
        end
        
        function [radianceImage, scaleFactor] = toRadiance(obj, image, sampling, nativeScene)
            scaleFactor = obj.pbrt.radiometricScaleFactor;
            radianceImage = image .* scaleFactor;
        end
    end
end
