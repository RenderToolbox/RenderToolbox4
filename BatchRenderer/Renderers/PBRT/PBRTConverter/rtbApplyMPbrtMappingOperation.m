function element = rtbApplyMPbrtMappingOperation(pbrtScene, mapping, varargin)
%% Create/Find/Delete an mPbrt element for the given mapping struct.
%
% element = rtbApplyMPbrtMappingOperation(pbrtScene, mapping) uses the given
% mapping to create, find, or delete an appropriate element of the given
% pbrtScene, as directed by the given mapping.operation.
%
% rtbApplyMPbrtMappingOperation(pbrtScene( ... 'identifier', identifier)
% specify the PBRT identifier to use when searching for elements.  The
% default is the given mapping.broadType.
%
% Returns any element that was found or created, for further processing.
%
% Copyright (c) 2016 mexximp Team

parser = inputParser();
parser.addRequired('pbrtScene', @isobject);
parser.addRequired('mapping', @isstruct);
parser.addParameter('identifier', '', @ischar);
parser.parse(pbrtScene, mapping, varargin{:});
pbrtScene = parser.Results.pbrtScene;
mapping = parser.Results.mapping;
identifier = parser.Results.identifier;

if isempty(identifier)
    identifier = mapping.broadType;
end

%% Locate the element.
[pbrtName, nameMatcher] = mexximpCleanName(mapping.name, mapping.index);
if isempty(nameMatcher)
    searchPattern = '';
else
    searchPattern = sprintf('^%s$|%s', pbrtName, nameMatcher);
end
switch mapping.operation
    case 'delete'
        % remove the node, if it can be found
        pbrtScene.find(identifier, ...
            'name', searchPattern, ...
            'remove', true);
        element = [];
        return;
        
    case 'create'
        % append a brand new element regardless of any existing
        element = MPbrtElement(identifier, ...
            'name', pbrtName, ...
            'type', mapping.specificType);
        pbrtScene.append(element);
        return;
        
    otherwise
        % 'update' and special operations like 'blessAsAreaLight'
        element = pbrtScene.find(identifier, 'name', searchPattern);
        if isempty(element)
            warning('applyMPbrtMappingOperation:nodeNotFound', ...
                'No node found with identifier <%s> and name <%s>', ...
                identifier, searchPattern);
        end
        return;
end
