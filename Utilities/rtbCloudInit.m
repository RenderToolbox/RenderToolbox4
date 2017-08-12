function rtbCloudInit( hints )

% This function sets up the Container engine on google cloud.
% We assume that you have goocle cloud SDK installed on your system and
% that you have set up the sdk by running:
% 
% gcloud init
%
%

if strcmp(hints.renderer,'PBRTCloud') == 0
    return;
end

if ~strcmpi(hints.batchRenderStrategy.renderer.provider,'google')
    error('Only Google Cloud is supported\n');
end

% First we set up a container cluster
% This command sets up a cluster of high-cpu, 32 core, preemptible machines
% Autoscaling is enabled so if you aren't using all the resources the
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
    
    if hints.batchRenderStrategy.renderer.preemptible,
        cmd = sprintf('%s --preemptible',cmd);
    end
    
    minNodes = hints.batchRenderStrategy.renderer.minInstances;
    maxNodes = hints.batchRenderStrategy.renderer.maxInstances;
    
    if hints.batchRenderStrategy.renderer.autoscaling,
        cmd = sprintf('%s --enable-autoscaling --min-nodes=%i --max-nodes=%i',...
            cmd, minNodes, maxNodes);
    end
    [~, result] = system(cmd);
    fprintf('%s\n',result);
end

% Once the container cluster is created one neds to get credentials, so
% that kubectl comands are executed on that particualr cluster.
cmd = sprintf('gcloud container clusters get-credentials %s --zone=%s',...
    clusterName,timeZone);
system(cmd);


% A cleanup-job
% The Container Cluster stores the completed jobs, and they use up
% resources (disk space, memory). We are going to run a simple service that
% periodically lists all succesfully completed jobs and removes them from
% the engine.

cmd = 'kubectl get jobs | grep cleanup';
[~, result] = system(cmd);

if isempty(strfind(result,'cleanup'))
    namespace = hints.batchRenderStraregy.renderer.kubectlNamespace;
    cmd = sprintf('kubectl run %scleanup --limits cpu=500m --restart=OnFailure --image=google/cloud-sdk -- /bin/bash -c ''while true; do echo "Starting"; kubectl delete jobs --namespace=%s $(kubectl get jobs --namespace=%s | awk ''"''"''$3=="1" {print $1}''"''"''); echo "Deleted jobs"; sleep 30; done''',...
        namespace,namespace,namespace);
    system(cmd);
end



%% Push the docker rendering image to the projec
% gcloud container images list --repository=gcr.io/primal-surfer-140120
[containerDir, containerName] = fileparts(hints.batchRenderStrategy.renderer.pbrt.dockerImage);

cmd = sprintf('gcloud container images list --repository=%s | grep %s',containerDir, containerName);
[~, result] = system(cmd);

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

