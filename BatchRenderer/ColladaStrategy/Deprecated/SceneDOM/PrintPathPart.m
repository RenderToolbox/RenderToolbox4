%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Print a formatted Scene DOM path.
%   @param operator string Scene DOM path operator
%   @param name string Scene DOM node name (optional)
%   @param checkName string Scene DOM check name (optional)
%   @param checkValue string Scene DOM check value (optional)
%
% @details
% Print a formatted path part, with the given @a operator, and optional @a
% name,  @a checkName, and @a checkValue.
%
% @details
% Returns a single formatted Scene DOM path part string.
%
% @details
% Usage:
%   pathPart = PrintPathPart(operator, name, checkName, checkValue)
%
% @ingroup SceneDOM
function pathPart = PrintPathPart(operator, name, checkName, checkValue)

%% Parameters
if nargin < 2 || isempty(name)
    name = '';
end

if nargin < 3 || isempty(checkName)
    checkName = '';
end

if nargin < 4 || isempty(checkValue)
    checkValue = '';
end

if ~any(strcmp(operator, {'.', ':', '$'}))
    warning('operator "%s" must be ":", ".", or "$".', operator);
    pathPart = '';
    return;
end

%% Assemble the path part
% start with a two-part path
pathPart = [operator name];

if ~isempty(checkName)
    % append the checkName
    pathPart = [pathPart '|' checkName];
end

if ~isempty(checkValue)
    % append the checkValue
    pathPart = [pathPart '=' checkValue];
end