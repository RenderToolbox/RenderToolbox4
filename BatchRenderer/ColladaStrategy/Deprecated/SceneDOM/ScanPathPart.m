%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Scan a Scene DOM path part for its components.
%   @param pathPart one part of a Scene DOM path
%
% @details
% Parse the given Scene DOM @a pathPart into its operator node name,
% check-name, and check-value (if any).
%
% @details
% @a pathPart must be one element from a Scene DOM path cell array.  See
% GetScenePath() for mode about scene paths.
%
% @details
% Returns the string operator node name, check-name, and check-value.  If
% any of these components is missing, returns '' instead.
%
% @details
% Usage:
%   [operator, name, checkName, checkValue] = ScanPathPart(pathPart)
%
% @ingroup SceneDOM
function [operator, name, checkName, checkValue] = ScanPathPart(pathPart)

% operator must always be first
if isempty(pathPart)
    operator = '';
    name = '';
    checkName = '';
    checkValue = '';
    return;
else
    operator = pathPart(1);
end

% up to three words may follow
delimiters = '=\|\.\:\$';
subPattern = sprintf('[%s]?([^%s]+)[%s]?', ...
    delimiters, delimiters, delimiters);
subTokens = regexp(pathPart, subPattern, 'tokens');
switch numel(subTokens)
    case 1
        name = subTokens{1}{1};
        checkName = '';
        checkValue = '';
        
    case 2
        name = subTokens{1}{1};
        checkName = subTokens{2}{1};
        checkValue = '';
        
    case 3
        name = subTokens{1}{1};
        checkName = subTokens{2}{1};
        checkValue = subTokens{3}{1};
        
    otherwise
        name = '';
        checkName = '';
        checkValue = '';
end