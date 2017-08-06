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
    instanceType = hints.batchRenderStrategy.renderer.instanceyType;
    
    cmd = sprintf('gcloud container clusters create %s --num-nodes=1 --max-nodes-per-pool=100 --machine-type=%s --zone=%s',...
        clusterName, instanceType, timeZone);
    
    if hints.batchRenderStrategy.renderer.preemptible,
        cmd = sprintf('%s --preemptible',cmd);
    end
    
    minNodes = hints.batchRenderStrategy.renderer.minNodes;
    maxNodes = hints.batchRenderStrategy.renderer.maxNodes;
    
    if hints.batchRenderStrategy.renderer.autoscaling,
        cmd = sprintf('%s --enable-autoscaling --min-nodes=%i --max-nodes==%i',...
            cmd, minNodes, maxNodes);
    end
    system(cmd)
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

if isempty(result)
    cmd = 'kubectl run cleanup --restart=OnFailure --image=google/cloud-sdk -- /bin/bash -c ''while true; do echo "Starting"; kubectl delete jobs $(kubectl get jobs | awk ''"''"''$3=="1" {print $1}''"''"''); echo "Deleted jobs"; sleep 600; done''';
    system(cmd);
end


end

