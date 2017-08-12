classdef RtbPBRTCloudRenderer < RtbRenderer
    %% Implementation for rendering with PBRT
    
    properties
        % RenderToolbox4 options struct, see rtbDefaultHints()
        hints = [];
        
        % pbrt info struct
        pbrt;
        
        % Google Clound Storage access token
        tokenPath;
        token;
        
        % Cloud folder
        cloudFolder;
        dataFileName = 'data.zip';
        
        % Local folder in the docker image
        localFolder = 'WorkDir';
        
        % where to write output files
        outputFolder;
        
        % where to put scenes before rendering
        workingFolder;
        
        % Variables specific to cloud provider
        provider = 'Google';
        clusterName = 'rtb4';
        zone = 'us-central1-a';
        instanceType = 'n1-highcpu-32';
        minInstances = 1;
        maxInstances = 10;
        preemptible = true;
        autoscaling = true;
        kubectlNamespace = '';
        
    end
    
    methods
        function obj = RtbPBRTCloudRenderer(hints)
            obj.hints = rtbDefaultHints(hints);
            obj.pbrt = getpref('PBRT');
            obj.tokenPath = hints.tokenPath;
            obj.token = loadjson(hints.tokenPath);
            obj.outputFolder = rtbWorkingFolder( ...
                'folderName', 'renderings', ...
                'rendererSpecific', true, ...
                'hints', obj.hints);
            obj.workingFolder = rtbWorkingFolder('hints', obj.hints);
            obj.kubectlNamespace = getenv('USER');
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
            workFolder = fullfile('/',obj.localFolder);
            outFile = fullfile(workFolder,'renderings','PBRTCloud', [imageName '.dat']);
            inFile = fullfile(workFolder,[imageName '.pbrt']);
            
            
            % Bullshit handling of different new-line characters across
            % systems. VERY HACKY
            key = obj.token.private_key;
            key = regexprep(key,'\n','\\n');
            
            token = obj.token;
            token.private_key = key;
            
            processedToken = savejson('',token);
            processedToken = regexprep(processedToken,'\\\\','\');
            
            %{
            command = sprintf('docker run -e http_proxy=http://10.102.1.10:8000 -e https_proxy=https://10.102.1.10:8000 --rm -ti hblasins/syncandrender ./syncAndRender.sh ''%s'' "%s" "%s" "%s" "%s" "%s"',...
                processedToken,...
                obj.cloudFolder,...
                workFolder,...
                obj.dataFileName,...
                inFile,...
                outFile);
            %}
                        
            % First delete all jobs that have been successfully completed.
            % Otherwise the nodes just accumulate the data and fill in the
            % disk space...
            % This has been replaced by a global cleanup job.
            % kubeCmd = sprintf('kubectl delete job $(kubectl get jobs --namespace=%s | awk ''$3=="1" {print $1}'')',namespace);
            % [status, result] = system(kubeCmd);
            
            kubeCmd = sprintf('kubectl get namespaces | grep %s',obj.kubectlNamespace);
            [status, result] = system(kubeCmd);
            
            if isempty(result)
               kubeCmd = sprintf('kubectl create namespace %s',obj.kubectlNamespace);
               [status, result] = system(kubeCmd);
            end
            
            
            jobName = lower([obj.hints.recipeName imageName]);
            jobName(jobName == '_' | jobName == '.' | jobName == '-') = '';
            jobName = jobName(1:min(63,length(jobName)));
            
            % Kubernetess does not allow two jobs with the same name.
            % We need to delete the old one first
            kubeCmd = sprintf('kubectl delete job --namespace=%s %s',obj.kubectlNamespace,jobName);
            [status, result] = system(kubeCmd);
            
            
            pos = strfind(obj.instanceType,'-');
            nCores = str2double(obj.instanceType(pos(end)+1:end));

            
            % Before we can issue a new one
            kubeCmd = sprintf('kubectl run %s --image=%s --namespace=%s --restart=OnFailure --limits cpu=%im  -- ./syncAndRender.sh ''%s'' "%s" "%s" "%s" "%s" "%s"',...
                jobName,...
                obj.pbrt.dockerImage,...
                obj.kubectlNamespace,...
                (nCores-0.9)*1000,...
                processedToken,...
                obj.cloudFolder,...
                workFolder,...
                obj.dataFileName,...
                inFile,...
                outFile);
            
            [status, result] = system(kubeCmd);
            
            
            
            
            
            
            %{
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
            %}
            if status ~= 0
                error('RtbPbrtRenderer:pbrtError', result);
            end
            
            sampling = obj.pbrt.S;
            image = [];
        end
        
        function [radianceImage, scaleFactor] = toRadiance(obj, image, sampling, nativeScene)
            scaleFactor = obj.pbrt.radiometricScaleFactor;
            radianceImage = image .* scaleFactor;
        end
    end
end
