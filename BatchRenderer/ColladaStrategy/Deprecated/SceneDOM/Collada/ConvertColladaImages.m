%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Update image file paths, relative to a working folder.
%   @param libraryImages "library_images" element frmo a Collada document
%   @param workingFolder path to search for resources like images
%
% @details
% For each image element within the given @a libraryImages, searches the
% given workingFolder for a file with the same name.  If such a file is
% found, replaces the image name with a relative path, relative to @a
% workingFolder.
%
% @details
% Returns nothing, but updates the given @a libraryImages
%
% @details
% Usage:
%   ConvertColladaImages(libraryImages, workingFolder)
%
% @ingroup SceneDOM
function ConvertColladaImages(libraryImages, workingFolder)

if ~isjava(libraryImages)
    % not a DOM element
    return;
end

imageNodes = GetElementChildren(libraryImages, 'image');
nImages = numel(imageNodes);
for ii = 1:nImages
    % does this image have an "init_from" with a file name?
    initFroms = GetElementChildren(imageNodes{ii}, 'init_from');
    if isempty(initFroms)
        continue;
    end
    initFrom = initFroms{1};
    initFromFile = char(initFrom.getTextContent());
    
    % is there such a file within workignFolder?
    fileInfo = rtbResolveFilePath(initFromFile, workingFolder);
    if fileInfo.isRootFolderMatch
        % update the file reference with path relative to workingFolder
        initFrom.setTextContent(fileInfo.resolvedPath);
    end
end

