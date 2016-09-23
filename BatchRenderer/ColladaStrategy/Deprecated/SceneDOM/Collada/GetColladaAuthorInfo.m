%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Get "authoring_tool" and "asset" elements from a Collad file.
%   @param colladaFile file name or path of a Collada scene file
%
% @details
% Reads the Collada document in the given @a colladaFile and retrieves the
% authoring_tool and asset elements that describe how the file was created.
% authoring_tool should be a string that describes the modeling
% application, for example "Blender 2.69.0 r60991".  asset should be a
% struct miscellaneous authoring info, such as the authoring_tool, creation
% date, unit of distance, etc.
%
% @details
% authoring_tools and assed elements should be present in Collada files,
% according to the Collada 1.4 schema:
%   http://www.khronos.org/collada/
%   http://www.khronos.org/files/collada_reference_card_1_4.pdf
%
% @details
% Returns the string authoring_tool element value and struct representation
% of the entire asset element.
%
% @details
% Usage:
%   [authoringTool, asset] = GetColladaAuthorInfo(colladaFile)
%
% @ingroup SceneDOM
function [authoringTool, asset] = GetColladaAuthorInfo(colladaFile)
asset = [];
authoringTool = '';

% get the root element of the Collada document
colladaDoc = ReadSceneDOM(colladaFile);
if isempty(colladaDoc)
    return;
end
colladaRoot = colladaDoc.getDocumentElement();

% parse the asset element
assetElements = GetElementChildren(colladaRoot, 'asset');
if isempty(assetElements)
    return;
end
asset = ElementToStruct(assetElements{1});

% dig out the authoring_tool in particular
if isfield(asset, 'contributor') && isfield(asset.contributor, 'authoring_tool')
    authoringTool = asset.contributor.authoring_tool.text;
end
