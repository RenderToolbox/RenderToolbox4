function matFileName = rtbCloudDownload( hints )

% Download all the data from the working directory into the cloud

% cmd = sprintf('gcloud auth activate-service-account --key-file=%s',hints.batchRenderStrategy.renderer.tokenPath);
% system(cmd);

if strcmp(hints.renderer,'PBRTCloud') == 0
    return;
end

sourceDir = fullfile(hints.batchRenderStrategy.renderer.cloudFolder,'renderings',hints.renderer);
destDir = rtbWorkingFolder('folderName','renderings',...
    'rendererSpecific',true,...
    'hints',hints);

% Download data (rendering outputs).
cmd = sprintf('gsutil rsync -x ".*.mat" %s %s',sourceDir,destDir);
system(cmd);

%{
cmd = sprintf('gsutil cp %s/*.dat %s/',sourceDir,destDir);
system(cmd);

% Download text files
cmd = sprintf('gsutil cp %s/*.txt %s/',sourceDir,destDir);
system(cmd);
%}

% Go over all the files and re-create the associated .mat files

fNames = dir(fullfile(destDir,'*.dat'));
matFileName = cell(length(fNames),1);

for f=1:length(fNames)
    
    % Load the data that was saved, everything is here except for radiance
    % that was copied from the cloud
    [a, conditionName] = fileparts(fNames(f).name);
    matFileName{f} = fullfile(destDir,sprintf('%s.mat',conditionName));
    
    load(matFileName{f});
    
    % Read the radiance data
    outFile = fullfile(destDir,fNames(f).name);
    S = hints.batchRenderStrategy.renderer.pbrt.S;
    image = rtbReadDAT(outFile, 'maxPlanes', S(3));
    
    % Assemble a spectral image
    [multispectralImage, radiometricScaleFactor] = ...
    hints.batchRenderStrategy.renderer.toRadiance(image, S, scene);
    
    
    save(matFileName{f}, 'multispectralImage', 'S', 'radiometricScaleFactor', ...
    'hints', 'scene', 'versionInfo', 'commandResult');
    
end



end

