%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Copy a Scene DOM path and add attribute path parts.
%   @param basePath Scene DOM path to receive attributes
%   @param names cell array of strings of attribute names
%
% @details
% Copy the given @a basePath and append an attribute path part, once for
% each of the given @a names. 
%
% @a basePath must be a scene DOM path that does not contain an attribute
% '.' operator.  @a names must be a cell array of string attribute names to
% appent to @a basePath.
%
% @details
% Returns a cell array of new scene DOM paths, one for each of the given
% @a names.  Each new path begins with the given @a basePath, with one of
% the given attribute @a names appended as a path part.
%
% @details
% Usage:
%   newPaths = AppendPathAttributes(basePath, names)
%
% @ingroup SceneDOM
function newPaths = AppendPathAttributes(basePath, names)

% make sure the path is in cell representation
basePath = PathStringToCell(basePath);

% create one new path for each name
nPaths = numel(names);
newPaths = cell(1, nPaths);
for ii = 1:nPaths
    attribPart = PrintPathPart('.', names{ii});
    newPaths{ii} = cat(2, basePath, attribPart);
end
