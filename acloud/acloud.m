classdef acloud < handle
    % Create an alibaba cloud object to interact with aliyun
    % You need to set up your alibaba account (see <https://account.aliyun.com/register/register.htm>)
    %
    % For testing see v_acloudTest.m
    %
    % ZL Vistasoft Team 2017
    properties 
        bucket = 'oss://';
        ros = 'python /Library/Frameworks/Python.framework/Versions/2.7/bin/ros --json';
    end
    methods
        function obj = acloud(varargin)
%             p = inputParser;
%             p.addParameter('bucket','oss://',@ischar);
%             p.addParameter('ros','python /Library/Frameworks/Python.framework/Versions/2.7/bin/ros --json',@ischar)
%             p.parse(varargin{:});
%             obj.bucket = p.Results.bucket;
%             obj.ros = p.Results.ros;
        end
        function [result, status, cmd] = ls(obj,bucketname)
            if ieNotDefined('bucketname')
                d = obj.bucket;
            else
                d = fullfile(obj.bucket, bucketname);
            end
            cmd = sprintf('ossutil ls %s\n',d);
            [status,result] = system(cmd);
        end
        function [result, status, cmd] = objectrm(obj,objectname)
            if ieNotDefined('objectname')
                disp('Object name required')
            else
                objname = fullfile(obj.bucket,objectname);
                cmd = sprintf('ossutil rm %s \n',objname);
                [status, result] = system(cmd);
            end
        end
        function [result, status, cmd] = bucketrm(obj,bucketname)
            if ieNotDefined('bucketname')
                disp('Bucket name required')
            else
                bname = fullfile(obj.bucket,bucketname);
                cmd = sprintf('ossutil rm %s -b -f\n',bname);
                [status, result] = system(cmd);
            end
        end
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
        function [result, status, cmd] = upload(obj,local_dir,cloud_dir)
            cloud_dir = fullfile(obj.bucket,cloud_dir);
            cmd = sprintf('ossutil cp %s %s -r -f -u\n',local_dir,cloud_dir);
            [status, result] = system(cmd);
        end
        function [result, status, cmd] = download(obj,cloud_dir,local_dir)
            cloud_dir = fullfile(obj.bucket,cloud_dir);
            cmd = sprintf('ossutil cp %s %s -r -f -u\n',cloud_dir,local_dir);
            [status, result] = system(cmd);
        end
        function [result, status,masterIp, stackname ,stackID, cmd] = k8sCreate(obj,stackname, MasterInstanceType,WorkerInstanceType,NumberOfNodes,password)
            cmd = sprintf('%s create-stack --stack-name %s --template-url /Users/eugeneliu/git_repo/RenderToolbox4/Alicloud/kube_3master.json --parameters MasterInstanceType=%s,WorkerInstanceType=%s,ImageId=centos_7,NumOfNodes=%d,LoginPassword=%s',...
                obj.ros,stackname,MasterInstanceType,WorkerInstanceType,NumberOfNodes,password);
            [~, result] = system(cmd);
            result = erase(result,'[Succeed]');
            result = parse_json(result);
            stackID = result.Id;
            while 1 
                    cmd = sprintf('%s describe-stack --stack-name %s --stack-id %s',obj.ros,stackname,stackID);
                    [~, result] = system(cmd);
                    result_check = erase(result,'[Succeed]');
                    result_check = parse_json(result_check);
                    status = result_check.Status;
                    pause(60);
                    fprintf('%s\n',status);
              if strcmp(status,'CREATE_COMPLETE')== 1
              break;
              end
              masterIp = result_check.Outputs{2}.OutputValue;
            end
            
            
        end
        function[result, status, cmd]= k8sDelete(obj,stackname,stackID)
                cmd = sprintf('%s delete-stack --region-id us-west-1 --stack-name %s --stack-id %s',obj.ros,stackname,stackID);
                [status, result] = system(cmd);
        end
        function[result, status, cmd]=k8sUpdate(obj,stackname,stackID,MasterInstanceType,WorkerInstanceType,NumberOfNodes,password)
                cmd = sprintf('%s create-stack --stack-name %s --template-url /Users/eugeneliu/git_repo/RenderToolbox4/Alicloud/kube_3master.json --parameters MasterInstanceType=%s,WorkerInstanceType=%s,ImageId=centos_7,NumOfNodes=%d,LoginPassword=%s,--regionID us-west-1 --stack-id %s',...
                obj.ros,stackname,MasterInstanceType,WorkerInstanceType,NumberOfNodes,password,stackID); 
                [status, result] = system(cmd);
        end
    end
end


































