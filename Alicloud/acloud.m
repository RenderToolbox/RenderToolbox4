classdef acloud < handle
    % Create an alibaba cloud object to interact with aliyun.
    %
    % To use these methods, you need to have an Alibaba account.
    % See the instructions on the RenderToolbox4 wiki page, or her
    % <https://account.aliyun.com/register/register.htm>.  
    %
    % Ultimately, we will move the cloud components into a separate
    % repository.
    %
    % For testing see v_acloudTest.m
    %
    % ZL Vistasoft Team 2017
    properties 
        bucket;          % Bucket on Aliyun where the data are stored.
        ros;             % Resource orchestration service command
        kubeTemplate;    % Kubernetes cluster template
        python;          % The executable you want used for python (many people have multiple pythons).
        
        
        masterIP;      
        masterType;               % 
        stackID;
        stackName;
        k8sPassword;              % Kubernetes Cluster password
        regionID = 'us-west-1';   % Stanford uses this
    end
    
    methods
        function obj = acloud(varargin)
            % Users may vary in the version of python, ossutil, ros, and template
            % locations.  So we let them be set here.
            %
            % acloud('python','/Users/wandell/anaconda/bin/python')
            % 
            p = inputParser;
            p.addParameter('bucket','oss://',@ischar);
            
            [~,systemPython] = system('which python');
            p.addParameter('python',systemPython,@(x)(exist(x,'file')));
            
            kubeTemplate = fullfile(aclRootPath,'kube_3master.json');
            p.addParameter('kubeTemplate',kubeTemplate,@(x)(exist(x,'file')));

            p.parse(varargin{:});

            % ROS is in the python bin directory.  We force the output
            % to be JSON.
            obj.bucket = p.Results.bucket;            
            obj.kubeTemplate = p.Results.kubeTemplate;
            obj.python = p.Results.python;
                        
            pythonDir = fileparts(obj.python);
            obj.ros = fullfile(pythonDir,'ros --json');
            
        end
        
        % List the objects
        function [result, status, cmd] = ls(obj,bucketname)
            if ieNotDefined('bucketname')
                d = obj.bucket;
            else
                d = fullfile(obj.bucket, bucketname);
            end
            cmd = sprintf('ossutil ls %s\n',d);
            [status,result] = system(cmd);
        end
        
        % Remove one object
        function [result, status, cmd] = objectrm(obj,objectname)
            if ieNotDefined('objectname')
                disp('Object name required')
            else
                objname = fullfile(obj.bucket,objectname);
                cmd = sprintf('ossutil rm %s \n',objname);
                [status, result] = system(cmd);
            end
        end
        
        % Remove one bucket
        function [result, status, cmd] = bucketrm(obj,bucketname)
            if ieNotDefined('bucketname')
                disp('Bucket name required')
            else
                bname = fullfile(obj.bucket,bucketname);
                cmd = sprintf('ossutil rm %s -b -f\n',bname);
                [status, result] = system(cmd);
            end
        end
        
        % Create one bucket
        function [result, status, cmd] = bucketCreate(obj,bucketname)
            if ieNotDefined('bucketname')
                disp('Bucket name (lower case) required')
            else
                bucketname = lower(bucketname);
                bname  = fullfile(obj.bucket,bucketname);
                cmd = sprintf('ossutil mb %s \n',bname);
                [status, result] = system(cmd);
            end
        end
        
        % Upload a folder or a file
        function [result, status, cmd] = upload(obj,local_dir,cloud_dir)
            cloud_dir = fullfile(obj.bucket,cloud_dir);
            cmd = sprintf('ossutil cp %s %s -r -f -u\n',local_dir,cloud_dir);
            [status, result] = system(cmd);
        end
        
        % Download a folder or a file
        function [result, status, cmd] = download(obj,cloud_dir,local_dir)
            cloud_dir = fullfile(obj.bucket,cloud_dir);
            cmd = sprintf('ossutil cp %s %s -r -f -u\n',cloud_dir,local_dir);
            [status, result] = system(cmd);
        end
        
        % Create a kubernetes cluster that can be controled by kubectl
        function [result, status, cmd] = ...
                k8sCreate(obj, stackName, MasterInstanceType, WorkerInstanceType, NumberOfNodes, password)
            %{
            alicloud = acloud('python','/Users/wandell/anaconda/bin/python');
            StackName = 'ros-name';           % Name of the cluster you are creating
            MasterType = 'ecs.n1.medium';     % The options can be found in the kube_3master.json template
            WorkerType = MasterType;          % Match the workers to the master or use another type
            NumberWorkerNodes = 2;            % A string, though we are planning to make it a number
            Password   = 'go2017Warriors';    % Creating a password for this cluster
            [result, status, masterIp, cmd] = alicloud.k8sCreate(StackName, MasterType, ...
                WorkerType,NumberWorkerNodes,Password);
            %}
            
            if notDefined('password'), password = 'go2017Cleveland'; end
            
            cmd = sprintf('%s create-stack',[obj.python,' ',obj.ros]);
            cmd = [cmd, sprintf(' --stack-name %s',stackName)];
            cmd = [cmd, sprintf(' --template-url %s',obj.kubeTemplate)];
            cmd = [cmd, sprintf(' --parameters ')];
            cmd = [cmd, sprintf('MasterInstanceType=%s,',MasterInstanceType)];
            cmd = [cmd, sprintf('WorkerInstanceType=%s,',WorkerInstanceType)];
            cmd = [cmd, sprintf('ImageId=centos_7,')];
            cmd = [cmd, sprintf('NumOfNodes=%d,',NumberOfNodes)];
            cmd = [cmd, sprintf('LoginPassword=%s',password)];
            
            obj.k8sPassword = password;
            obj.stackName = stackName;

            %             cmd = sprintf('%s create-stack --stack-name %s --template-url /Users/eugeneliu/git_repo/RenderToolbox4/Alicloud/kube_3master.json --parameters MasterInstanceType=%s,WorkerInstanceType=%s,ImageId=centos_7,NumOfNodes=%d,LoginPassword=%s',...
            %                 obj.ros,stackname,MasterInstanceType,WorkerInstanceType,NumberOfNodes,password);
            %
            
            [~, result] = system(cmd);
            % result = erase(result,'[Succeed]');  % Get rid of this part of the string
            result = jsonread(result);
            obj.stackID   = result.Id;
            
            fprintf('Initiated %s creation.  Takes about 30 minutes\n',obj.stackName);
            
            while true
                % Check the status of the creation.  Return
                % when done.  This could be its own separate function.
                cmd = sprintf('%s describe-stack --stack-name %s --stack-id %s',obj.ros,obj.stackName,obj.stackID);
                [~, result] = system(cmd);
                result_check = erase(result,'[Succeed]');
                result_check = jsonread(result_check);
                status = result_check.Status;
                
                % Check again in 60 secs
                pause(60);
                fprintf('%s\n',status);
                if strcmp(status,'CREATE_COMPLETE')== 1
                    break;
                end
                obj.masterIP = result_check.Outputs{2}.OutputValue;
            end
            
        end
        
        % Delete a kubernetes cluster
        function[result, status, cmd]= k8sDelete(obj)
                cmd = sprintf('%s delete-stack --region-id %s --stack-name %s --stack-id %s',...
                    obj.ros,obj.regionID, obj.stackName,obj.stackID);
                [status, result] = system(cmd);
        end
        
        % Adjust the kubernetes allocation
        function[result, status, cmd]=k8sUpdate(obj,stackname,stackID,MasterInstanceType,WorkerInstanceType,NumberOfNodes,password)
                cmd = sprintf('%s create-stack --stack-name %s --template-url /Users/eugeneliu/git_repo/RenderToolbox4/Alicloud/kube_3master.json --parameters MasterInstanceType=%s,WorkerInstanceType=%s,ImageId=centos_7,NumOfNodes=%d,LoginPassword=%s,--regionID us-west-1 --stack-id %s',...
                obj.ros,obj.stackName,obj.masterType,WorkerInstanceType,NumberOfNodes,password,stackID); 
                [status, result] = system(cmd);
        end
        
    end
end


































