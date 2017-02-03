function [renderings, referenceRoot, artifact] = rtbFetchReferenceData(recipeName, varargin)
% Fetch a reference rendering and make it available locally.
%
% renderings = rtbFetchReferenceData(recipeName) fetches a reference data
% zip-file from the default brainard-archiva server.  The given recipeName
% must be the name of an rtb example recipe, like 'rtbMakeDragon'.  Expands
% the fetched zip file into the current directory.  Returns a struct array
% of rendering data files that were found in the reference data.
%
% Also returns the path to the root folder where the zip file was expanded.
% Also returns the RemoteDataToolbox artifact record for the fetched data.
%
% rtbFetchReferenceData( ... 'rdtConfig', rdtConfig) specify the Remote
% Data Toolbox configuration to use.  The default is 'render-toolbox'.
%
% rtbFetchReferenceData( ... 'remotePath', remotePath) specify the Remote
% Data Toolbox artifact path to use.  The default is 'reference-data'.
%
% rtbFetchReferenceData( ... 'referenceVersion', referenceVersion) specify
% the Remote Data Toolbox artifact version to fetch.  The default is '+',
% the latest available.
%
% rtbFetchReferenceData( ... 'referenceRoot', referenceRoot) specify the
% root folder where to expand the fetched zip file.  The default is pwd().
%
% [renderings, referenceRoot, artifact] = rtbFetchReferenceData(recipeName, varargin)
%
%%% RenderToolbox4 Copyright (c) 2012-2017 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('recipeName', @ischar);
parser.addParameter('rdtConfig', 'render-toolbox');
parser.addParameter('remotePath', 'reference-data', @ischar);
parser.addParameter('referenceVersion', '+', @ischar);
parser.addParameter('referenceRoot', pwd(), @ischar);
parser.parse(recipeName, varargin{:});
recipeName = parser.Results.recipeName;
rdtConfig = parser.Results.rdtConfig;
remotePath = parser.Results.remotePath;
referenceVersion = parser.Results.referenceVersion;
referenceRoot = parser.Results.referenceRoot;


%% Get a whole recipe from the server.
artifactPath = fullfile(remotePath, recipeName);
[fileName, artifact] = rdtReadArtifact(rdtConfig, artifactPath, recipeName, ...
    'version', referenceVersion, ...
    'type', 'zip');

if isempty(fileName)
    renderings = [];
    artifact = [];
    return;
end


%% Explode renderings it into the destination folder.
destination = fullfile(referenceRoot, recipeName);
unzip(fileName, destination);

% scan for rendering records
renderings = rtbFindRenderings(destination);
