%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Set the PBRT identifier and type of a PBRT-XML document node.
%   @param idMap
%   @param id
%   @param pbrtIdentifier
%   @param pbrtType
%
% @details
% Set the PBRT identifier (e.g. "Camera", "Material") and type (e.g.
% "perspective", "plastic") of a node in the PBRT-XML document represented
% by @a idMap, using a standard format for node @a id, @a pbrtIdentifier,
% and @a pbrtType.
%
% @details
% Used internally by ColladaToPBRT().
%
% @details
% Usage:
%   SetType(idMap, id, pbrtIdentifier, pbrtType)
%
% @ingroup ColladaToPBRT
function SetType(idMap, id, pbrtIdentifier, pbrtType)

% create new XML DOM nodes as needed
isCreate = true;

% declare the identifier in the element node name
typePath = {id, '$'};
SetSceneValue(idMap, typePath, pbrtIdentifier, isCreate);

% declare the specific type
typePath = {id, '.type'};
SetSceneValue(idMap, typePath, pbrtType, isCreate);
