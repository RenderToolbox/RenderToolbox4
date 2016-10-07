%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Convert a Scene DOM path string to the equivalent cell array.
%   @param pathString Scene DOM path string
%
% @details
% Returns a Scene DOM path cell array that is equivalent to the given @a
% pathString.  If @a pathString is already a cell array, returns it as-is.
%
% @details
% Usage:
%   pathCell = PathStringToCell(pathString)
%
% @ingroup SceneDOM
function pathCell = PathStringToCell(pathString)

% already a cell representation?
if iscell(pathString)
    pathCell = pathString;
    return;
end

% path parts must be delimited by :, ., or $
delimiters = '[\.\:\$]';
delimitIndices = regexp(pathString, delimiters);

if isempty(delimitIndices)
    % path contains only an id
    pathCell = {pathString};
    
else
    % build up the path cell one part at a time
    nParts = numel(delimitIndices);
    pathCell = cell(1, 1+nParts);
    
    % pull the id off the front of the string
    pathCell{1} = pathString(1:(delimitIndices(1)-1));
    
    % get each path part, including the delimiting operators
    %   let the end of the string also count as a delimiter
    delimitIndices(end+1) = 1 + numel(pathString);
    for ii = 1:nParts
        partRange = delimitIndices(ii):(delimitIndices(ii+1)-1);
        pathCell{1+ii} = pathString(partRange);
    end
end