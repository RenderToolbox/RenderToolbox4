%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Convert a material from a Collada document to a PBRT-XML document.
%   @param id
%   @param stubIDMap
%   @param colladaIDMap
%   @param hints struct of RenderToolbox4 options, see rtbDefaultHints()
%
% @details
% Cherry pick from Collada "material" and "effect" nodes in the Collada
% document represented by the given @a colladaIDMap, and populate the
% corresponding node of the stub PBRT-XML document represented by the given
% @a stubIDMap.  @a id is the unique identifier of the material node.  @a
% hints is a struct of conversion hints.
%
% @details
% Returns true if the conversion was successful.
%
% @details
% Used internally by ColladaToPBRT().
%
% @details
% Usage:
%   isConverted = ConvertMaterial(id, stubIDMap, colladaIDMap, hints)
%
% @ingroup ColladaToPBRT
function isConverted = ConvertMaterial(id, stubIDMap, colladaIDMap, hints)

isConverted = true;

% get the id of the corresponding effect (without the '#')
colladaPath = {id, ':instance_effect', '.url'};
effectID = GetSceneValue(colladaIDMap, colladaPath);
effectID = effectID(effectID ~= '#');

% look for "phong" effect
phongPath = {effectID, ':profile_COMMON', ':technique', ':phong'};
phong = SearchScene(colladaIDMap, phongPath);
if isempty(phong)
    % boring matte
    SetType(stubIDMap, id, 'Material', 'matte');
    AddParameter(stubIDMap, id, 'Kd', 'rgb', '1 1 1');
    AddParameter(stubIDMap, id, 'sigma', 'float', '0');
    
else
    % diffuse (may be a texture)
    [diffuseType, diffuse] = extractPhongParameter(phong, 'diffuse', 'rgb', '1 1 1', []);
    
    % specular (may be a texture)
    [specularType, specular] = extractPhongParameter(phong, 'specular', 'rgb', '', []);
    
    if isempty(specular)
        % custom matte
        SetType(stubIDMap, id, 'Material', 'matte');
        
        AddParameter(stubIDMap, id, 'Kd', diffuseType, diffuse);
        if strcmp('texture', diffuseType)
            declareTexture(effectID, diffuse, stubIDMap, colladaIDMap);
        end
        
        AddParameter(stubIDMap, id, 'sigma', 'float', '0');
    else
        % custom Ward
        % would prefer uber with index of refraction, but it seems broken
        SetType(stubIDMap, id, 'Material', 'anisoward');
        
        % index of refraction
        %     [type, value] = extractPhongParameter(phong, 'index_of_refraction', 'float', '1', []);
        %     AddParameter(stubIDMap, id, 'index', type, value);
        
        AddParameter(stubIDMap, id, 'Kd', diffuseType, diffuse);
        if strcmp('texture', diffuseType)
            declareTexture(effectID, diffuse, stubIDMap, colladaIDMap);
        end
        
        AddParameter(stubIDMap, id, 'Ks', specularType, specular);
        if strcmp('texture', specularType)
            declareTexture(effectID, specular, stubIDMap, colladaIDMap);
        end
        AddParameter(stubIDMap, id, 'alphaU', 'float', '0.15');
        AddParameter(stubIDMap, id, 'alphaV', 'float', '0.15');
    end
end

% Extract parameter type and value from a phong
function [type, value, semantic] = extractPhongParameter(phong, paramName, type, value, semantic)

% named element(s) under a phong element
params = GetElementChildren(phong, paramName);
if isempty(params)
    return;
end
param = params{1};

[dataNodes, dataNames] = GetElementChildren(param);
nDataNodes = numel(dataNodes);
for ii = 1:nDataNodes
    dataNode = dataNodes{ii};
    dataName = dataNames{ii};
    
    switch dataName
        case 'color'
            type = 'rgb';
            value = StringToVector(char(dataNode.getTextContent()));
            value = value(1:3);
            [attribute, attributeName, semantic] = GetElementAttributes(dataNode, 'sid');
            return;
            
        case 'float'
            type = 'float';
            value = StringToVector(char(dataNode.getTextContent()));
            [attribute, attributeName, semantic] = GetElementAttributes(dataNode, 'sid');
            return;
            
        case 'texture'
            type = 'texture';
            [attribute, attributeName, value] = GetElementAttributes(dataNode, 'texture');
            [attribute, attributeName, semantic] = GetElementAttributes(dataNode, 'texcoord');
            return;
    end
end

% Declare a new texture that was referenced by a phong parameter.
function declareTexture(effectId, samplerId, stubIDMap, colladaIDMap)
% follow sampler reference to 2D surface
surfaceIdPath = {effectId, ':profile_COMMON', [':newparam|sid=' samplerId], ':sampler2D', ':source'};
surfaceId = GetSceneValue(colladaIDMap, surfaceIdPath);
if isempty(surfaceId)
    return;
end

% follow surface reference to image
imageIdPath = {effectId, ':profile_COMMON', [':newparam|sid=' surfaceId], ':surface', ':init_from'};
imageId = GetSceneValue(colladaIDMap, imageIdPath);
if isempty(imageId)
    return;
end

% follow image reference to file name
fileNamePath = {imageId, ':init_from'};
fileName = GetSceneValue(colladaIDMap, fileNamePath);
if isempty(fileName)
    return;
end

% texture with file name and default params
SetType(stubIDMap, samplerId, 'Texture', 'imagemap');
AddParameter(stubIDMap, samplerId, 'dataType', 'string', 'spectrum');
AddParameter(stubIDMap, samplerId, 'filename', 'string', fileName);
AddParameter(stubIDMap, samplerId, 'gamma', 'float', '1');
AddParameter(stubIDMap, samplerId, 'maxanisotropy', 'float', '20');
AddParameter(stubIDMap, samplerId, 'trilinear', 'bool', 'false');
AddParameter(stubIDMap, samplerId, 'udelta', 'float', '0.0');
AddParameter(stubIDMap, samplerId, 'vdelta', 'float', '0.0');
AddParameter(stubIDMap, samplerId, 'uscale', 'float', '1.0');
AddParameter(stubIDMap, samplerId, 'vscale', 'float', '1.0');
AddParameter(stubIDMap, samplerId, 'wrap', 'string', 'repeat');
