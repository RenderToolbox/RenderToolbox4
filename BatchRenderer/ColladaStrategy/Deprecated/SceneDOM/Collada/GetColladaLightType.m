%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Get the type of a Collada document light element.
%   @param element a light element from a Collada document
%
% @details
% Determines the type of the given Collada document light @a element, based
% on the elements "technique_common" child element.  The type of light may
% be "ambient", "directional", "point", or "spot".  See
%   http://www.khronos.org/collada/
% for more about the Collada XML schema and lights.
%
% @details
% Returns the string node name that determines the light type, either
% "ambient", "directional", "point", or "spot".  If @a element is not a
% Collada light element, or is not a known type of light, returns ''.
%
% @details
% Usage:
%   lightType = GetColladaLightType(element)
%
% @ingroup SceneDOM
function lightType = GetColladaLightType(element)

% unknown or non-lights don't get a type
lightType = '';

if ~isjava(element)
    % not a DOM element
    return;
end

% look under the "technique_common" child element
technique_common = GetElementChildren(element, 'technique_common');
if isempty(technique_common)
    % not a Collada common light
    return;
end

[childNodes, childNames] = GetElementChildren(technique_common{1});
if isempty(childNames)
    % not a valid Collada common light
    return;
end

% check common, known light types
commonTypes = { ...
    'point', ...
    'directional', ...
    'spot', ...
    'ambient', ...
    };
for ii = 1:numel(commonTypes)
    if any(strcmp(commonTypes{ii}, childNames))
        lightType = commonTypes{ii};
        return;
    end
end

