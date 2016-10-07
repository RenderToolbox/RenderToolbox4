%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Add a parameter to a PBRT-XML document.
%   @param idMap
%   @param id
%   @param name
%   @param type
%   @param value
%
% @details
% Adds a parmater to the PBRT-XML document represented by @a idMap,
% using a standard format for node @a id and paramter @a name and @a type.
% Converts numeric @a value automatically to string representations.
%
% @details
% Used internally by ColladaToPBRT().
%
% @details
% Usage:
%   AddParameter(idMap, id, name, type, value)
%
% @ingroup ColladaToPBRT
function AddParameter(idMap, id, name, type, value)

% create new XML DOM nodes as needed
isCreate = true;

% declare the parameter
paramPath = {id, [':parameter|name=' name]};
value = VectorToString(value);
SetSceneValue(idMap, paramPath, value, isCreate);

% set the parameter type
paramPath = {id, [':parameter|name=' name], '.type'};
SetSceneValue(idMap, paramPath, type, isCreate);
