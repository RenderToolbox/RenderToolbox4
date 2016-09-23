%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Apply PBRT mappings objects to the adjustments DOM.
%   @param idMap
%   @param objects
%
% @details
% Modify the document represented by the given @a idMap, with the given
% mappings @a objects.  @a objects must be a struct array of mappings
% objects as returned from MappingsToObjects() or GenericObjectsToPBRT().
%
% @details
% Used internally by RTB_ApplyMappings_PBRT().
%
% @details
% Usage:
%   ApplyPBRTObjects(idMap, objects)
%
% @ingroup RendererPlugins
function ApplyPBRTObjects(idMap, objects)

for ii = 1:numel(objects)
    % pull out one object to apply
    obj = objects(ii);
    
    if strcmp(obj.hints, 'AreaLightSource')
        % for area lights
        %	write properties to a new light source with a new id
        %   bind the original shape object to the new id
        
        % area light uses two separate ids
        shapeID = obj.id;
        lightID = [obj.id '-area-light'];
        
        % write out a new light object
        obj.id = lightID;
        obj.class = 'AreaLightSource';
        addObject(idMap, obj);
        
        % bind the existing shape object to the light object
        addConfiguration(idMap, shapeID, 'reference', ...
            'area-light', 'AreaLightSource', lightID);
        
    elseif strcmp(obj.hints, 'bumpmap')
        % make a new scale texture that scales the given bump texture
        textureID = GetObjectProperty(obj, 'textureID');
        scale = GetObjectProperty(obj, 'scale');
        scaledID = ['zzz-' obj.id '-scaled'];
        addDeclaration(idMap, scaledID, 'Texture', 'scale');
        addConfiguration(idMap, ...
            scaledID, 'parameter', 'dataType', 'string', 'float');
        addConfiguration(idMap, ...
            scaledID, 'parameter', 'tex1', 'texture', textureID);
        addConfiguration(idMap, ...
            scaledID, 'parameter', 'tex2', 'float', scale);
        
        % assign the scaled texture to the given material's bumpmap
        materialID = GetObjectProperty(obj, 'materialID');
        addConfiguration(idMap, ...
            materialID, 'parameter', 'bumpmap', 'texture', scaledID);
        
    else
        % otherwise, add the object to the DOM as-is
        addObject(idMap, obj);
    end
end


% Make sure the DOM contains a node for the given object.
function checkDOMNode(idMap, id, nodeName)
if ~idMap.isKey(id)
    docNode = idMap('document');
    docRoot = docNode.getDocumentElement();
    objectNode = CreateElementChild(docRoot, nodeName, id, 'first');
    idMap(id) = objectNode;
end


% Add a whole object to the DOM.
function addObject(idMap, object)
addDeclaration(idMap, object.id, object.class, object.subclass);
for ii = 1:numel(object.properties)
    prop = object.properties(ii);
    addConfiguration(idMap, object.id, 'parameter', ...
        prop.name, prop.type, prop.value);
end


% Add an object declaration to the DOM.
function addDeclaration(idMap, id, class, subclass)

if isempty(class)
    return;
end

% make sure the DOM has a node for this object
checkDOMNode(idMap, id, class);

% set the node name
path = {id, PrintPathPart('$')};
SetSceneValue(idMap, path, class, true, '=');

if nargin >= 4
    % set the node type
    path = {id, PrintPathPart('.', 'type')};
    SetSceneValue(idMap, path, subclass, true, '=');
end


% Add an object configuration of a given flavor to the DOM.
function addConfiguration(idMap, id, flavor, name, type, value)
% make sure the DOM has a node for this object
checkDOMNode(idMap, id, 'merge');

% set the property "name" and "type" attributes
path = {id, ...
    PrintPathPart(':', flavor, 'name', name), ...
    PrintPathPart('.', 'type')};
SetSceneValue(idMap, path, type, true, '=');

% set the property value
path = {id, ...
    PrintPathPart(':', flavor, 'name', name)};
SetSceneValue(idMap, path, value, true, '=');
