function rtbCloudUpload_Ali( hints, nativeSceneFiles )

% Upload all the data from the working directory into the cloud

% No need to authenticate on the local system
% cmd = sprintf('gcloud auth activate-service-account --key-file=%s',hints.batchRenderStrategy.renderer.tokenPath);
% system(cmd);

if strcmp(hints.renderer,'PBRTCloud') == 0
    return;
end

fileName = hints.batchRenderStrategy.renderer.getDataFileName;
allFiles = cell2mat(strcat(nativeSceneFiles,{' '}));

allFilesAndFolders = sprintf('%s ./resources ./scenes',allFiles);

currentPath = pwd;
cd(hints.batchRenderStrategy.renderer.workingFolder);
cmd = sprintf('zip -r %s/%s %s -x *.jpg *.png',hints.batchRenderStrategy.renderer.workingFolder,fileName,allFilesAndFolders);
system(cmd);
cd(currentPath);
% Google and Alibaba use different commands for files uploading.
%if strcmp(hints.batchRenderStrategy.renderer.provider,'Alicloud') == 1 %add in the hints
    cmd = sprintf('/Users/eugeneliu/Downloads/ossutilmac64 cp %s/%s oss://docker2017',hints.batchRenderStrategy.renderer.workingFolder,fileName);
    %cmd = sprintf('/Users/eugeneliu/Downloads/ossutilmac64 cp %s/%s %s',hints.batchRenderStrategy.renderer.workingFolder,fileName,...
    %hints.batchRenderStrategy.renderer.cloudFolder);% Ali uses oss bucket as a clould storage
    system(cmd);% Ali use an unix executable file instead of a simple command
%else 
%    cmd = sprintf('gsutil cp %s/%s %s/',hints.batchRenderStrategy.renderer.workingFolder,fileName,...
%    hints.batchRenderStrategy.renderer.cloudFolder);
%system(cmd);
%end

end

