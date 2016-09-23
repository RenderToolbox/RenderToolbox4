%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Convert effect nodes to physically-based types.
%   @param libraryEffects "library_effects" element a Collada document
%
% @details
% Ensures that each effect element within the given @a libraryEffects will
% use a physically-based subset of the "phong" type of effect.  This means
% only diffuse, specular, and index_of_refraction parameters of phong will
% be included.  Others, like ambient, will be omitted.
%
% @details
% For the diffuse and specular parameters, either an RGB color or a texture
% may be included.
%
% @details
% Returns nothing, but updates the given @a libraryEffects
%
% @details
% Usage:
%   ConvertColladaEffects(libraryEffects)
%
% @ingroup SceneDOM
function ConvertColladaEffects(libraryEffects)

if ~isjava(libraryEffects)
    % not a DOM element
    return;
end

% check each effect element and coerce as needed
colladaDoc = libraryEffects.getOwnerDocument();
effectNodes = GetElementChildren(libraryEffects, 'effect');
nEffects = numel(effectNodes);
for ii = 1:nEffects
    
    % does this effect use the standard "common profile"
    profiles = GetElementChildren(effectNodes{ii}, 'profile_COMMON');
    if isempty(profiles)
        continue;
    end
    profile = profiles{1};
    
    % take profile children as-is, except technique
    [childNodes, childNames] = GetElementChildren(profile);
    nChildren = numel(childNodes);
    for jj = 1:nChildren
        childNode = childNodes{jj};
        childName = childNames{jj};
        
        if strcmp('technique', childName)
            % build a physically-based phong
            coerceToPhong(childNode, colladaDoc);
        end
    end
end

% Coerce phong, blinn, lambert, or constant to physically-based phong
function coerceToPhong(technique, colladaDoc)
[childNodes, childNames] = GetElementChildren(technique);
nChildren = numel(childNodes);
for jj = 1:nChildren
    childNode = childNodes{jj};
    childName = childNames{jj};
    
    if any(strcmp({'phong', 'blinn', 'lambert', 'constant'}, childName))
        colladaDoc.renameNode(childNode, [], 'phong');
        prunePhong(childNode);
        return;
    end
end

% Prune a phong node to use a physically-based subset of parameters.
function prunePhong(phong)
[childNodes, childNames] = GetElementChildren(phong);
nChildren = numel(childNodes);
for jj = 1:nChildren
    childNode = childNodes{jj};
    childName = childNames{jj};
    
    % keep this subset of parameters
    if any(strcmp({'diffuse', 'specular', 'index_of_refraction'}, childName))
        continue;
    end
    
    % delete other parameters
    phong.removeChild(childNode);
end
