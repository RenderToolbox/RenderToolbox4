%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Group mappings into meaningful objects.
%   @param mappings
%
% @details
% Create a struct array of mappings objects, based on the struct array of
% mappings data as returned from ParseMappings().  Each mappings object
% incorporates one declaration and zero or more property configurations.
% These are taken from mappings that use the same id value and reside
% within the same mappings block.  Returns a new struct array of mappings
% objects.
%
% @details
% Used internally by rtbMakeSceneFiles().
%
% @details
% Usage:
%   objects = MappingsToObjects(mappings)
%
% @ingroup Mappings
function objects = MappingsToObjects(mappings)

% create an object for each id used in mappings
objects = [];
nMaps = numel(mappings);
for ii = 1:nMaps
    % parse mappings for "scene target" info
    map = mappings(ii);
    info = getSceneTargetInfo(map);
    
    % get a new or existing object for the "scene target" id
    if isempty(objects)
        % brand new array of objects
        objects = makeObjectTemplate();
        obj = makeObjectTemplate();
        objectIndex = 1;
        
    else
        isObject = strcmp(info.id, {objects.id});
        if any(isObject)
            % pull out an existing object
            obj = objects(isObject);
            objectIndex = find(isObject, 1, 'first');
            
        else
            % append a brand new object
            obj = makeObjectTemplate();
            objectIndex = numel(objects) + 1;
        end
    end
    
    % fill in object info for this mapping
    obj.id = info.id;
    obj.blockType = map.blockType;
    obj.blockGroup = map.group;
    obj.blockNumber = map.blockNumber;
    if info.isDeclaration
        % fill in object class info
        obj.class = info.name;
        obj.subclass = info.type;
        
    else
        % fill in an object property
        prop = makeProperty(info, map);
        if isempty(obj.properties)
            obj.properties = prop;
        else
            obj.properties(end+1) = prop;
        end
    end
    
    % save the new or updated object
    objects(objectIndex) = obj;
end


% Get a scene target info struct.
function info = getSceneTargetInfo(mapping)
info = struct( ...
    'id', '', ...
    'name', '', ...
    'type', '', ...
    'operator', mapping.operator, ...
    'value', mapping.right.value, ...
    'isDeclaration', isempty(mapping.operator));

% scene target syntax is deliberately similar to scene DOM path syntax
%   so the same parsing function works
mappingParts = PathStringToCell(mapping.left.value);
switch numel(mappingParts)
    case 3
        % extract id, name, and type
        info.id = mappingParts{1};
        [pathOp, info.name] = ScanPathPart(mappingParts{2});
        [pathOp, info.type] = ScanPathPart(mappingParts{3});
        
    case 2
        % extract id and name
        info.id = mappingParts{1};
        [pathOp, info.name] = ScanPathPart(mappingParts{2});
        
    otherwise
        warning('Cannot parse scene target left-hand value "%s".', ...
            mapping.left.value);
        return;
end


% Get an object template.
function object = makeObjectTemplate()
object = struct( ...
    'id', '', ...
    'class', '', ...
    'subclass', '', ...
    'blockType', '', ...
    'blockGroup', '', ...
    'blockNumber', [], ...
    'hints', [], ...
    'properties', []);


% Get an object property.
function property = makeProperty(info, map)
property = struct( ...
    'name', info.name, ...
    'type', info.type, ...
    'value', map.right.value, ...
    'operator', map.operator);
