function rtbCloudUpload( hints, nativeSceneFiles )

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

cmd = sprintf('gsutil cp %s/%s %s/',hints.batchRenderStrategy.renderer.workingFolder,fileName,...
    hints.batchRenderStrategy.renderer.cloudFolder);
system(cmd);


end

