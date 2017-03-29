%% Read metadata about a VirtualScenes base scene or object.
%   @param modelName the name of a VirtualScenes model like "RingToy"
%
% @details
% Reads a mat-file of metadata for a 3D Collada model that we previouslt
% registered in the VirtualScenes ModelRepository using WriteMetadata().
% @a modelName must be the same name that was passed to WriteMetadata(),
% for example "RingToy".  This must would correspond to the name of the
% Collada file in the VirtualScenes Toolbox ModelRepository, such as
% 'VirtualScenesToolbox/ModelRepository/Objects/Models/RingToy.dae'.
%
% @details
% Returns the struct metadata that was previously written by
% WriteMetadata().
%
% @details
% Usage:
%   metadata = ReadMetadata(modelName)
%
% @ingroup VirtualScenes
function metadata = rtbReadMetadata(modelName)
metadata = [];

% locate the metadata file
metadataFile = [modelName '.mat'];
rootFolder = getpref('VirtualScenes', 'modelRepository');
fileInfo = rtbResolveFilePath(metadataFile, rootFolder);

if ~fileInfo.isRootFolderMatch
    warning('VirtualScenes:NoSuchMetadata', ...
        'Could not find metadata for model named "%s" in %s', modelName, rootFolder);
    return;
end

metadataFullPath = fileInfo.absolutePath;
fprintf('\nFound model metadata:\n  %s\n', metadataFullPath);

fileData = load(fileInfo.absolutePath);

if ~isfield(fileData, 'metadata')
    warning('VirtualScenes:BadMetadata', ...
        'Metadata is missing from data file %s', metadataFullPath);
    return;
end

metadata = fileData.metadata;
