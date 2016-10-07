%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Convert a Collada parent scene file the PBRT native format
%   @param colladaFile input Collada parent scene file name or path
%   @param adjustments native adjustments data, or file name or path
%   @param imageName the name to use for this scene and new files
%   @param hints struct of RenderToolbox4 options
%
% @details
% This is the RenderToolbox4 "ImportCollada" function for PBRT.
%
% @details
% For more about ImportCollada functions see
% RTB_ImportCollada_SampleRenderer().
%
% @details
% Usage:
%   scene = RTB_ImportCollada_PBRT(colladaFile, adjustments, imageName, hints)
function scene = RTB_ImportCollada_PBRT(colladaFile, adjustments, imageName, hints)

% choose new files to create
scenesFolder = rtbWorkingFolder( ...
    'folderName', 'scenes', ...
    'rendererSpecific', true, ...
    'hints', hints);
tempFolder = rtbWorkingFolder( ...
    'folderName', 'temp', ...
    'rendererSpecific', true, ...
    'hints', hints);
pbrtFile = fullfile(scenesFolder, [imageName '.pbrt']);
pbrtXMLFile = fullfile(scenesFolder, [imageName 'pbrt.xml']);
adjustmentsFile = fullfile(tempFolder, [imageName 'Adjustments.xml']);

% report new files as relative paths
scene.colladaFile = rtbGetWorkingRelativePath(colladaFile, 'hints', hints);
scene.pbrtFile = rtbGetWorkingRelativePath(pbrtFile, 'hints', hints);
scene.pbrtXMLFile = rtbGetWorkingRelativePath(pbrtXMLFile, 'hints', hints);
scene.adjustmentsFile = rtbGetWorkingRelativePath(adjustmentsFile, 'hints', hints);

% image is a safe default film for PBRT
if isempty(hints.filmType)
    hints.filmType = 'image';
end

if hints.isReuseSceneFiles
    % locate exsiting scene files, but don't produce new ones
    disp('Reusing scene files for PBRT scene:')
    disp(scene)
    drawnow();
    
else
    %% Invoke several Collada to PBRT utilities.
    fprintf('Converting %s\n  to %s.\n', colladaFile, pbrtFile);
    
    % read the collada file
    [colladaDoc, colladaIDMap] = ReadSceneDOM(colladaFile);
    
    % create a new PBRT-XML document
    [pbrtDoc, pbrtIDMap] = CreateStubDOM(colladaIDMap, 'pbrt_xml');
    PopulateStubDOM(pbrtIDMap, colladaIDMap, hints);
    
    % make sure the adjustments document has a film node
    filmNodeID = 'film';
    filmPBRTIdentifier = 'Film';
    if ~adjustments.idMap.isKey(filmNodeID)
        adjustRoot = adjustments.docNode.getDocumentElement();
        filmNode = CreateElementChild(adjustRoot, filmPBRTIdentifier, filmNodeID);
        adjustments.idMap(filmNodeID) = filmNode;
    end
    
    % fill in the film parameters
    SetType(adjustments.idMap, filmNodeID, filmPBRTIdentifier, hints.filmType);
    AddParameter(adjustments.idMap, filmNodeID, ...
        'xresolution', 'integer', hints.imageWidth);
    AddParameter(adjustments.idMap, filmNodeID, ...
        'yresolution', 'integer', hints.imageHeight);
    
    % write the adjusted PBRT-XML document to file
    MergeAdjustments(pbrtDoc, adjustments.docNode);
    WriteSceneDOM(pbrtXMLFile, pbrtDoc);
    WriteSceneDOM(adjustmentsFile, adjustments.docNode);
    
    % dump the PBRT-XML document into a .pbrt text file
    WritePBRTFile(pbrtFile, pbrtXMLFile, hints);
end
