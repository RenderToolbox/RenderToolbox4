%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Apply Mitsuba mappings objects to the adjustments DOM.
%   @param idMap
%   @param objects
%
% @details
% Modify the document represented by the given @a idMap, with the given
% mappings @a objects.  @a objects must be a struct array of mappings
% objects as returned from MappingsToObjects() or
% GenericObjectsToMitsuba().
%
% @details
% Used internally by rtbMakeSceneFiles().
%
% @details
% Usage:
%   ApplyMitsubaObjects(idMap, objects)
%
% @ingroup Mappings
function ApplyMitsubaObjects(idMap, objects)

for ii = 1:numel(objects)
    % pull out one object to apply
    obj = objects(ii);
    
    if regexp(obj.id, '-mesh$')
        % for mesh objects, Mitsuba likes to append a _0 to the id
        %   TODO: can we detect when the suffix should be _1, etc?  I think
        %   this would imply a Collada nodes that share geometry.
        obj.id = [obj.id '_0'];
    end
    
    if strcmp(obj.hints, 'area-light')
        % for area lights,
        %   declare an emitter nested in a shape node
        %   redirect properties to the nested emitter
        
        % add the shape node
        addDeclaration(idMap, obj.id, obj.class);
        
        % add a new, nested area emitter, with its own id
        lightID = [obj.id '-area-light'];
        path = {obj.id, ...
            PrintPathPart(':', 'emitter', 'id', lightID), ...
            PrintPathPart('.', 'type')};
        SetSceneValue(idMap, path, 'area', true, '=');
        
        % add the new emitter to the idMap
        path = {obj.id, ...
            PrintPathPart(':', 'emitter', 'id', lightID)};
        lightNode = SearchScene(idMap, path);
        idMap(lightID) = lightNode;
        
        % redirect properties to the new emitter
        obj.id = lightID;
        obj.class = 'emitter';
        addObject(idMap, obj);
        
    elseif strcmp(obj.hints, 'bumpmap')
        % make a new scale texture that scales the given bump texture
        textureID = GetObjectProperty(obj, 'textureID');
        scale = GetObjectProperty(obj, 'scale');
        scaledID = [obj.id '-scaled'];
        addDeclaration(idMap, scaledID, 'texture', 'scale');
        addConfiguration(idMap, ...
            scaledID, 'value', 'ref', textureID);
        addConfiguration(idMap, ...
            scaledID, 'scale', 'float', scale);
        
        % change id of the given material
        materialID = GetObjectProperty(obj, 'materialID');
        innerMaterialID = [materialID '-inner'];
        innerMaterial = idMap(materialID);
        innerMaterial.setAttribute('id', innerMaterialID);
        idMap(innerMaterialID) = innerMaterial;
        idMap.remove(materialID);
        
        % replace given material with a bump material
        addDeclaration(idMap, materialID, 'bsdf', 'bumpmap');
        addConfiguration(idMap, ...
            materialID, 'texture', 'ref', scaledID);
        addConfiguration(idMap, ...
            materialID, 'bsdf', 'ref', innerMaterialID);
        
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
    addConfiguration(idMap, object.id, ...
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


% Add an object configuration to the DOM.
function addConfiguration(idMap, id, name, type, value)
% make sure the DOM has a node for this object
checkDOMNode(idMap, id, 'merge');

if strcmp(type, 'texture') || strcmp(type, 'ref')
    % Mitsuba textures use a "ref" node type and "id" instead of "value"
    type = 'ref';
    flavor = 'id';
    
elseif 0 == numel(StringToVector(value)) ...
        && ~strcmp('string', type) ...
        && ~strcmp('boolean', type)
    % Mitsuba sometimes takes a "filename" instead of a "value"
    %   detect this as non-numeric value,
    %   with a non-string, non-boolean type
    flavor = 'filename';
    
else
    % Mitsuba stores most things in the "value" attribute.
    flavor = 'value';
end

% set the type in the node name and the "name" attribute
%   store the value in the attribute of the correct flavor
path = {id, ...
    PrintPathPart(':', type, 'name', name), ...
    PrintPathPart('.', flavor)};
SetSceneValue(idMap, path, value, true, '=');
