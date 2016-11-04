function element = rtbApplyMMitsubaMappingOperation(mitsubaScene, mapping, varargin)
%% Create/Find/Delete an mMitsuba element for the given mapping struct.
%
% element = rtbApplyMMitsubaMappingOperation(mitsubaScene, mapping) uses the
% given mapping to create, find, or delete an appropriate element of the
% given mitsubaScene, as directed by the given mapping.operation.
%
% rtbApplyMMitsubaMappingOperation(mitsubaScene( ... 'type', type)
% specify the Mitsuba element type to use when searching for elements.  The
% default is the given mapping.broadType.
%
% Returns any element that was found or created, for further processing.
%
% Copyright (c) 2016 mexximp Team

parser = inputParser();
parser.addRequired('mitsubaScene', @isobject);
parser.addRequired('mapping', @isstruct);
parser.addParameter('type', '', @ischar);
parser.parse(mitsubaScene, mapping, varargin{:});
mitsubaScene = parser.Results.mitsubaScene;
mapping = parser.Results.mapping;
type = parser.Results.type;

if isempty(type)
    type = mapping.broadType;
end

%% Locate the element.

% search for exact name by itself, or formatted index_name pattern
[mitsubaId, idMatcher] = mexximpCleanName(mapping.name, mapping.index);
if isempty(idMatcher)
    searchPattern = '';
else
    searchPattern = sprintf('^%s$|%s', mitsubaId, idMatcher);
end
switch mapping.operation
    case 'delete'
        % remove the node, if it can be found
        mitsubaScene.find(searchPattern, ...
            'type', type, ...
            'remove', true);
        element = [];
        return;
        
    case 'create'
        % append a brand new element regardless of any existing
        element = MMitsubaElement(mitsubaId, type, mapping.specificType);
        mitsubaScene.append(element);
        return;
        
    otherwise
        % 'update' and special operations like 'blessAsAreaLight'
        element = mitsubaScene.find(searchPattern, ...
            'type', type);
        if isempty(element)
            warning('applyMMitsubaMappingOperation:nodeNotFound', ...
                'No node found with type <%s> and id <%s>', ...
                type, searchPattern);
        end
        
        return;
end
