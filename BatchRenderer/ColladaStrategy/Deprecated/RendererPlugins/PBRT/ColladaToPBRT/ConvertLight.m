%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Convert a light from a Collada document to a PBRT-XML document.
%   @param id
%   @param stubIDMap
%   @param colladaIDMap
%   @param hints struct of RenderToolbox4 options, see rtbDefaultHints()
%
% @details
% Cherry pick from a Collada "light" node in the Collada document
% represented by the given @a colladaIDMap, and populate the corresponding
% node of the stub PBRT-XML document represented by the given @a
% stubIDMap.  @a id is the unique identifier of the light node.  @a
% hints is a struct of conversion hints.
%
% @details
% Returns true if the conversion was successful.
%
% @details
% Used internally by ColladaToPBRT().
%
% @details
% Usage:
%   isConverted = ConvertLight(id, stubIDMap, colladaIDMap, hints)
%
% @ingroup ColladaToPBRT
function isConverted = ConvertLight(id, stubIDMap, colladaIDMap, hints)


isConverted = true;

% what kind of light is this?
colladaPath = {id, ':technique_common' ':point'};
isPoint = ~isempty(SearchScene(colladaIDMap, colladaPath));
colladaPath = {id, ':technique_common' ':directional'};
isDirectional = ~isempty(SearchScene(colladaIDMap, colladaPath));
colladaPath = {id, ':technique_common' ':spot'};
isSpot = ~isempty(SearchScene(colladaIDMap, colladaPath));
colladaPath = {id, ':technique_common' ':ambient'};
isAmbient = ~isempty(SearchScene(colladaIDMap, colladaPath));

% parameters depend on light type
if isPoint
    % declare a point light
    SetType(stubIDMap, id, 'LightSource', 'point');
    
    % get the light color
    colladaPath = {id, ':technique_common', ':point', ':color'};
    color = GetSceneValue(colladaIDMap, colladaPath);
    
    % create I parameter
    AddParameter(stubIDMap, id, 'I', 'rgb', color);
    
elseif isDirectional
    % declare a distant light
    SetType(stubIDMap, id, 'LightSource', 'distant');
    
    % get the light color
    colladaPath = {id, ':technique_common', ':directional', ':color'};
    color = GetSceneValue(colladaIDMap, colladaPath);
    
    % unrotated Collada distant light points towards -z
    fromPoint = [0 0 0];
    toPoint = [0 0 -1];
    
    % create L, from, and to parameters
    AddParameter(stubIDMap, id, 'L', 'rgb', color);
    AddParameter(stubIDMap, id, 'from', 'point', fromPoint);
    AddParameter(stubIDMap, id, 'to', 'point', toPoint);
    
elseif isSpot
    % declare a spot light
    SetType(stubIDMap, id, 'LightSource', 'spot');
    
    % get the light color
    colladaPath = {id, ':technique_common', ':spot', ':color'};
    color = GetSceneValue(colladaIDMap, colladaPath);
    
    % unrotated Collada spot light points towards -z
    fromPoint = [0 0 0];
    toPoint = [0 0 -1];
    
    % get the angle of the main part of the light code
    colladaPath = {id, ':technique_common', ':spot', ':falloff_angle'};
    cone = GetSceneValue(colladaIDMap, colladaPath);
    if isempty(cone)
        coneNum = 45;
    else
        coneNum = StringToVector(cone)/2;
    end
    
    % get the exponent of falloff outside the main part of the light cone
    %   Collada uses an exponential falloff from the cone where PBRT uses a
    %   linear ramp to 0.  Since the form of the exponential is
    %   undocumented, there's no way to convert.
    %colladaPath = {id, ':technique_common', ':spot', ':falloff_exponent'};
    %coneExp = GetSceneValue(colladaIDMap, colladaPath);
    
    % create I, from, to, coneangle, and conedeltaangle parameters
    AddParameter(stubIDMap, id, 'I', 'rgb', color);
    AddParameter(stubIDMap, id, 'from', 'point', fromPoint);
    AddParameter(stubIDMap, id, 'to', 'point', toPoint);
    AddParameter(stubIDMap, id, 'coneangle', 'float', coneNum);
    %AddParameter(stubIDMap, id, 'conedeltaangle', 'float', coneDelta);
    
elseif isAmbient
    % declare an infinite light
    SetType(stubIDMap, id, 'LightSource', 'infinite');
    
    % get the light color
    colladaPath = {id, ':technique_common', ':ambient', ':color'};
    color = GetSceneValue(colladaIDMap, colladaPath);
    
    % create L parameter
    AddParameter(stubIDMap, id, 'L', 'rgb', color);
    
else
    warning('"%s" is not point, directional, or spot, not converted.', id);
    isConverted = false;
    return;
end
