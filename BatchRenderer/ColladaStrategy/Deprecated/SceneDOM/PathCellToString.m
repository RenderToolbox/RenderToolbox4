%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Convert a Scene DOM path cell array to the equivalent string.
%   @param pathCell Scene DOM path cell array
%
% @details
% Returns a Scene DOM path string that is equivalent to the given @a
% pathCell.  If @a pathCell is already a string, returns it as-is.
%
% @details
% Usage:
%   pathString = PathCellToString(pathCell)
%
% @ingroup SceneDOM
function pathString = PathCellToString(pathCell)

% already a string representation?
if ischar(pathCell)
    pathString = pathCell;
    return;
end

% converting to string is just concatenation
pathString = [pathCell{:}];