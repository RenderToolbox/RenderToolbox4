%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Convert a reference from a Collada document to a PBRT-XML document.
%   @param id
%   @param stubIDMap
%   @param colladaIDMap
%   @param hints struct of RenderToolbox4 options, see rtbDefaultHints()
%
% @details
% Cherry pick from Collada node s that refer to "instances" of other nodes,
% by "url", "instance", or "target" attributes, and populate a
% cooresponding node of the stub PBRT-XML document represented by the given
% @a stubIDMap.  @a id is the unique identifier of the referencinf node.
% @a hints is a struct of conversion hints.
%
% @details
% Returns true if the conversion was successful.
%
% @details
% Used internally by ColladaToPBRT().
%
% @details
% Usage:
%   isConverted = ConvertReferences(id, stubIDMap, colladaIDMap)
%
% @ingroup ColladaToPBRT
function isConverted = ConvertReferences(id, stubIDMap, colladaIDMap)

isConverted = true;

% find "instance" urls among the scene paths
colladaNode = colladaIDMap(id);
referencePattern = 'instance.+\.url|instance.+\.target';
pathMap = GenerateScenePathMap(colladaNode, '', referencePattern);
instancePaths = pathMap.keys();

% keep track of geometry ID and material ID to tie them together
geometryID = '';
materialID = '';

% add each reference to the stub document
for ii = 1:numel(instancePaths)
    pathCell = PathStringToCell(instancePaths{ii});
    
    % get the id of a referenced node
    referenceID = GetSceneValue(colladaIDMap, pathCell);
    
    % get the name of the node that holds the reference
    [refOp, refName] = ScanPathPart(pathCell{end-1});
    
    % choose a reference type based on the node name
    %   may also change the node type as a hint for later
    if strfind(refName, 'geometry')
        refType = 'Object';
        geometryID = referenceID;
        
    elseif strfind(refName, 'material')
        refType = 'Material';
        materialID = referenceID;
        
    elseif strfind(refName, 'light')
        refType = 'LightSource';
        
    elseif strfind(refName, 'camera')
        refType = 'Camera';
        SetType(stubIDMap, id, 'CameraNode', '');
        
    else
        refType = '';
    end
    
    % only convert references of known types
    if ~isempty(refType)
        AddReference(stubIDMap, id, refName, refType, referenceID);
    end
end

% let a geometry node refer to a corresponding material node
if ~isempty(geometryID) && ~isempty(materialID)
    AddReference(stubIDMap, geometryID, 'material', 'Material', materialID);
end