%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Add a transformation to a PBRT-XML document.
%   @param idMap
%   @param id
%   @param name
%   @param type
%   @param value
%
% @details
% Adds a transformation to the PBRT-XML document represented by @a
% idMap, using a standard format for node @a id and transformation @a name
% and @a type.  Converts numeric @a values automatically.
%
% @details
% Used internally by ColladaToPBRT().
%
% @details
% Usage:
%   AddTransform(idMap, id, name, type, value)
%
% @ingroup ColladaToPBRT
function AddTransform(idMap, id, name, type, value)

if isempty(name)
    name = type;
end

% create new XML DOM objects as needed
isCreate = true;

% declare the transformation
transPath = {id, [':transformation|name=' name]};
value = VectorToString(value);
SetSceneValue(idMap, transPath, value, isCreate);

% set the transformation type
transPath = {id, [':transformation|name=' name], '.type'};
SetSceneValue(idMap, transPath, type, isCreate);