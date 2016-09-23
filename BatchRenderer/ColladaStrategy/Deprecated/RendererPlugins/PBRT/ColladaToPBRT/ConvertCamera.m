%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Convert a camera from a Collada document to a PBRT-XML document.
%   @param id
%   @param stubIDMap
%   @param colladaIDMap
%   @param hints struct of RenderToolbox4 options, see rtbDefaultHints()
%
% @details
% Cherry pick from a Collada "camera" node in the Collada document
% represented by the given @a colladaIDMap, and populate the corresponding
% node of the stub PBRT-XML document represented by the given @a stubIDMap.
% @a id is the unique identifier of the camera node.  @a hints is a struct
% of conversion hints.
%
% @details
% Returns true if the conversion was successful.
%
% @details
% Used internally by ColladaToPBRT().
%
% @details
% Usage:
%   isConverted = ConvertCamera(id, stubIDMap, colladaIDMap, hints)
%
% @ingroup ColladaToPBRT
function isConverted = ConvertCamera(id, stubIDMap, colladaIDMap, hints)

isConverted = true;

%% Reconcile Collada and PBRT coordinate systems

% default camera points down -z axis, with +y axis being up
lookAt = [0 0 0, 0 0 -1, 0 +1 0];
AddTransform(stubIDMap, id, 'internalLook', 'LookAt', lookAt);

%% What kind of camera is this?
colladaPath = {id, ':optics', ':technique_common' ':perspective'};
isPerspective = ~isempty(SearchScene(colladaIDMap, colladaPath));

colladaPath = {id, ':optics', ':technique_common' ':orthographic'};
isOrthographic = ~isempty(SearchScene(colladaIDMap, colladaPath));

% ignore image aspect ratio from Collada, get it from user
aspect = hints.imageWidth / hints.imageHeight;

% some parameters depend on camera type
if isPerspective
    % declare a perspective camera
    SetType(stubIDMap, id, 'Camera', 'perspective');
    
    % get field of view
    colladaPath = {id, ':optics', ':technique_common', ...
        ':perspective', ':xfov'};
    xFov = str2double(GetSceneValue(colladaIDMap, colladaPath));
    
    % PBRT "fov" refers to the shorter image dimension
    if aspect < 1
        % fov is xfov
        fov = xFov;
    else
        % fov is yfov, scale opposite leg of a right triangle by aspec
        fov = 2*atand(tand(xFov/2) / aspect);
    end
    
    % create fov parameter
    AddParameter(stubIDMap, id, 'fov', 'float', fov)
    
elseif isOrthographic
    % declare an orthographic camera
    SetType(stubIDMap, id, 'Camera', 'orthographic');
    
    % get the x-magnification
    colladaPath = {id, ':optics', ':technique_common', ...
        ':orthographic', ':xmag'};
    xmag = str2double(GetSceneValue(colladaIDMap, colladaPath));
    
    % PBRT ortho camera uses x and y scale factors in screenwindow
    ymag = xmag/aspect;
    xyMag = [-xmag xmag -ymag ymag];
    
    % create screenwindow parameter
    AddParameter(stubIDMap, id, 'screenwindow', 'float', xyMag)
    
else
    warning('"%s" is not perspective or orthographic, not converted.', id);
    isConverted = false;
    return;
end
