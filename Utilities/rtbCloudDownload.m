function matFileName = rtbCloudDownload( hints )
% Download the data from the working directory into the cloud
%
% The job status is checked.  If the jobs are all complete, the data are
% downloaded.
%
% At this time, the data are also assembled assuming a pbrt-spectral docker
% output.  But that will get separated out from this routine in the fullness of
% time. (BW).
%
% HB?
% cmd = sprintf('gcloud auth activate-service-account --key-file=%s',hints.batchRenderStrategy.renderer.tokenPath);
% system(cmd);
%
% HB, Scien Team

%%
matFileName = [];

%%
if strcmp(hints.renderer,'PBRTCloud') == 0, return; end

% Force the recipe name to be consistent with kubectl requirements
% recipeName means this job.
% namespace means this user.
validRecipeName = hints.recipeName;
validRecipeName(ismember(validRecipeName,' -')) = '';
validRecipeName = lower(validRecipeName);

% Set up in the main script
namespace = hints.batchRenderStrategy.renderer.kubectlNamespace;

% Gete the list of jobs relevant to this calculation for this user
cmd = sprintf('kubectl get jobs --namespace=%s | grep %s',namespace,validRecipeName);
[~, result] = system(cmd);

% If result contains information, it contains stuff that is still ongoing.  So,
% we return matFileName empty.
if ~isempty(result)
    fprintf('Job status in namepsace %s\n',namespace);
    disp(result);
    C = textscan(result,'%s %s %s %s');
    for ii=1:length(C{1})
        if ~isequal(str2double(C{3}{ii}),1)
            fprintf('Job %d is not complete\n',ii);
            return;
        end
    end
end

% Looks like we are done.  Organize and download the data.
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

% This assembles the matlab data returned from the gcloud
% But this routine is a bit specialized for the pbrt-spectral case.  We should
% consider breaking it up so that below here is a different function and all we
% do is return the names of the files, above.
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

