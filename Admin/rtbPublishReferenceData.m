function artifacts = rtbPublishReferenceData(varargin)
% Use RemoteDataToolbox to publish reference data to brainard-archiva.
%
% Archiva server "brainard-archiva" on AWS at http://brainard-archiva.psych.upenn.edu/
% and repository called RenderToolbox.
% see rdt-config-render-toolbox.json
%
% Reference data on Amazon S3 at
%   s3://render-toolbox-reference/all-example-scenes/2016-10-26-21-24-21
%
% Use yas3fs to mount the bucket before running this script.  Then this
% script can use the file system instead of the S3 API.
%
% Should run this from an AWS instance under the Brainard Lab AWS accout.
% This will avoid data transfer to the local workstation, which will make
% it go a lot faster and cheaper!
%
% For each example scene, make a zip archive.  Publish at a path like
%   reference-renderings/rtbMakeDragon
%
% Use the "epic scene test" date as the version, like
%   2016-10-26-21-24-21
%

parser = inputParser();
parser.addParameter('rdtConfig', 'render-toolbox');
parser.addParameter('rdtUsername', '');
parser.addParameter('rdtPassword', '');
parser.addParameter('referenceRoot', pwd(), @ischar);
parser.addParameter('tempRoot', fullfile(tempdir(), 'rtbPublishReferenceData'), @ischar);
parser.addParameter('referenceVersion', 'test', @ischar);
parser.addParameter('remotePath', 'reference-data', @ischar);
parser.addParameter('deployToolboxes', false, @islogical);
parser.addParameter('dryRun', true, @islogical);
parser.parse(varargin{:});
rdtConfig = parser.Results.rdtConfig;
rdtUsername = parser.Results.rdtUsername;
rdtPassword = parser.Results.rdtPassword;
referenceRoot = parser.Results.referenceRoot;
tempRoot = parser.Results.tempRoot;
referenceVersion = parser.Results.referenceVersion;
remotePath = parser.Results.remotePath;
deployToolboxes = parser.Results.deployToolboxes;
dryRun = parser.Results.dryRun;

if ~isempty(rdtUsername) && ~isempty(rdtPassword)
    rdtConfig = rdtConfiguration(rdtConfig);
    rdtConfig.username = rdtUsername;
    rdtConfig.password = rdtPassword;
end

if deployToolboxes
    tbUse({'RenderToolbox4', 'RemoteDataToolbox'});
end

if 7 ~= exist(tempRoot, 'dir')
    mkdir(tempRoot);
end

% iterate subfolders of referenceRoot for example names
fprintf('Looking for examples in <%s>:', referenceRoot);
[exampleNames, nExamples] = subfolderNames(referenceRoot);
artifactCell = cell(1, nExamples);
for ee = 1:nExamples
    exampleName = exampleNames{ee};
    exampleDir = fullfile(referenceRoot, exampleName);
    
    % zip up the example
    archiveTemp = fullfile(tempRoot, [exampleName '.zip']);
    if ~dryRun
        zip(archiveTemp, '.', exampleDir);
    end
    
    % publish the zip
    artifactCell{ee} = publishFile(rdtConfig, archiveTemp, remotePath,...
        exampleName, referenceVersion, dryRun);
end
artifacts = [artifactCell{:}];


function [names, nNames] = subfolderNames(parentPath)
parentDir = dir(parentPath);
parentDir = parentDir(3:end);
names = {parentDir([parentDir.isdir]).name};
nNames = numel(names);


function artifact = publishFile(rdtConfig, fileName, remotePath, exampleName, versionName, dryRun)

% describe the example
artifactPath = fullfile(remotePath, exampleName);
description = sprintf('  version <%s> example <%s>', versionName, exampleName);
disp(description);

if dryRun
    artifact = [];
    return;
end

% go ahead and publish the dir
artifact = rdtPublishArtifact(rdtConfig, fileName, artifactPath, ...
    'artifactId', exampleName, ...
    'version', versionName, ...
    'rescan', true);
