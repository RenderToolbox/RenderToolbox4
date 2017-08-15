function [gs, kube] = rtbCloudInit( hints )
% Sets up the container engine on a google cloud instance via kubernetes
%
% We assume that you have google cloud SDK installed on your system and that you
% have set up the sdk by running
% 
%    gcloud init
%
% We assume you have set up your account services and credentials as per the
% NN_camera_generalization wiki page description.  This has been tested on Linux
% systems (only?) or mainly.
%
% This routine
%
%  * creates a cluster to run the container
%  * sets up kubectl to manage the rtb4 cluster
%  * If you don't have the docker image in your project repository, it will copy
% it there.
%  * If the job runs successfully, it cleans up the stored data
%
% See also - Functions to upload and download the data
%            rtbCloudDownload, rtbCloudUpload.
% 
% Examples:  s_differentLensesCloud.m in NN_Camera_Generalization
%
% HB, SCIENSTANFORD 2017

%% Check the variables
if strcmp(hints.renderer,'PBRTCloud') == 0
    % Not using the cloud.
    return;
end

namespace = hints.batchRenderStrategy.renderer.kubectlNamespace;

% gs = gcloud('bucket',yourBucket);
gs   = gcloud;
kube = kubernetes(namespace);

if ~strcmpi(hints.batchRenderStrategy.renderer.provider,'google')
    % Some day, alibaba
    error('Only Google Cloud is supported\n');
end

%% Set up a container cluster (default name is rtb4)

% By default, this command sets up a cluster of high-cpu, 32 core, preemptible
% machines.Autoscaling is enabled so if you aren't using all the resources the
% unnecessary machines are killed (to save you money).

clusterName = hints.batchRenderStrategy.renderer.clusterName;
timeZone = hints.batchRenderStrategy.renderer.zone;

cmd = sprintf('gcloud container clusters list --filter=%s',clusterName);
[~, result] = system(cmd);

if isempty(result)
    % we need to create a new cluster
    instanceType = hints.batchRenderStrategy.renderer.instanceType;
    
    cmd = sprintf('gcloud container clusters create %s --num-nodes=1 --max-nodes-per-pool=100 --machine-type=%s --zone=%s',...
        clusterName, instanceType, timeZone);
    
    if hints.batchRenderStrategy.renderer.preemptible
        cmd = sprintf('%s --preemptible',cmd);
    end
    
    minNodes = hints.batchRenderStrategy.renderer.minInstances;
    maxNodes = hints.batchRenderStrategy.renderer.maxInstances;
    
    if hints.batchRenderStrategy.renderer.autoscaling
        cmd = sprintf('%s --enable-autoscaling --min-nodes=%i --max-nodes=%i',...
            cmd, minNodes, maxNodes);
    end
    [~, result] = system(cmd);
    fprintf('%s\n',result);
end

%% Once the container cluster is created get your user credentials.

% This defines the container-cluster where your kubectl commands will be
% executed.

cmd = sprintf('gcloud container clusters get-credentials %s --zone=%s',...
    clusterName,timeZone);
system(cmd);

%% Cleanup

% A cleanup-job
% The Container Cluster stores the completed jobs, and they use up
% resources (disk space, memory). We are going to run a simple service that
% periodically lists all succesfully completed jobs and removes them from
% the engine.

% Check if a namespace for a user exists, if it doesn't create one.
cmd = sprintf('kubectl get namespaces | grep %s',namespace);
[~, result] = system(cmd);
if isempty(result)
    cmd = sprintf('kubectl create namespace %s',namespace);
    system(cmd);
end

% Create a cleanup job in the user namespace.
cmd = sprintf('kubectl get jobs --namespace=%s | grep cleanup',namespace);
[~, result] = system(cmd);

if isempty(strfind(result,'cleanup'))
    cmd = sprintf('kubectl run cleanup --limits cpu=500m --namespace=%s --restart=OnFailure --image=google/cloud-sdk -- /bin/bash -c ''while true; do echo "Starting"; kubectl delete jobs --namespace=%s $(kubectl get jobs --namespace=%s | awk ''"''"''$3=="1" {print $1}''"''"''); echo "Deleted jobs"; sleep 30; done''',...
        namespace,namespace,namespace);
    system(cmd);
end


%% Push the docker rendering image to the project

[containerDir, containerName] = fileparts(hints.batchRenderStrategy.renderer.pbrt.dockerImage);

% Check whether you have the necessary container
cmd = sprintf('gcloud container images list --repository=%s | grep %s',containerDir, containerName);
[~, result] = system(cmd);

% If you don't, it goes to work getting the container, tag it, and push it to
% the cloud.  This should really be on the RenderToolbox4 docker hub account in
% the future.
if isempty(result)
    % We need to copy the container to gcloud 
    cmd = sprintf('docker pull hblasins/%s',containerName);
    system(cmd);
    cmd = sprintf('docker tag hblasins/%s %s/%s',containerName, containerDir, containerName);
    system(cmd);
    cmd = sprintf('gcloud docker -- push %s/%s',containerDir, containerName);
    system(cmd);
end

end

