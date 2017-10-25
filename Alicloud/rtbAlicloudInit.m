%% Kubernete Initialization
% Create a Kubernetes cluster using a template. 
clear; close all;
cmd = sprintf('python /Library/Frameworks/Python.framework/Versions/2.7/bin/ros --json create-stack --stack-name ros-demo --template-url /Users/eugeneliu/git_repo/RenderToolbox4/Alicloud/kube_3master.json --parameters MasterInstanceType=ecs.n1.medium,WorkerInstanceType=ecs.n1.medium,ImageId=centos_7,NumOfNodes=1,LoginPassword=Project2017');
[~, result] = system(cmd);
result = erase(result,'[Succeed]');
result = parse_json(result);
StackID = result.Id;

% check status of creating process
while 1 
      cmd = sprintf('python /Library/Frameworks/Python.framework/Versions/2.7/bin/ros --json describe-stack --stack-name ros-demo --stack-id %s',StackID);
      [~, result] = system(cmd);
      result_check = erase(result,'[Succeed]');
      result_check = parse_json(result_check);
      status = result_check.Status;
      pause(30);
      fprintf('%s\n',status);
if strcmp(status,'CREATE_COMPLETE')== 1
    break;
    
end
end
% Check the master ip
%result = erase(result,'[succeed]');
%result = parse_json(result);
masterIp = result_check.Outputs{2}.OutputValue;

% copy kube config file from alicloud master machine to local machine.
cmd = sprintf('scp root@%s:/etc/kubernetes/kube.conf $HOME/.kube/config',masterIp);
system(cmd);
% Validate template
% cmd = sprintf('python /Library/Frameworks/Python.framework/Versions/2.7/bin/ros validate-template --template-url kube_3master.json')
% [~, result] = system(cmd);
% result;

% Delet a kluster
%cmd = sprintf('python /Library/Frameworks/Python.framework/Versions/2.7/bin/ros delete-stack --region-id us-west-1 --stack-name ros-demo --stack-id %s',StackID);
%system(cmd)
% Create a buket

% Connect a bucket to kubernetes

% Create a bucket
% ossutilmac64 is a file that needed to be downloaded.
% bucketname =('zhenyi0929');
% cmd = sprintf('/Users/eugeneliu/Downloads/ossutilmac64 mb oss://%s', bucketname); %the name can be put into hints.
% system(cmd);
% % Upload local file to cloud bucket.
% cmd = sprintf('/Users/eugeneliu/Downloads/ossutilmac64 cp %s oss://%s', bucketname,localdir) ;%the name can be put into hints.
% system(cmd);
% % Download files from cloud.
% cmd = sprintf('/Users/eugeneliu/Downloads/ossutilmac64 cp oss://%s %s', bucketname,localdir); %the name can be put into hints.
% system(cmd);