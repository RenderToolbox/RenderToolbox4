function element = rtbFindSceneElement(scene, varargin)
%% Search for a scene element, based on the given name, type, and/or index.
%
% element = rtbFindSceneElement(scene, name, broadType, index) searches the
% given mexximp scene for a single element, such as a single camera, light,
% material, mesh, embeddedTexture, or rootNode, or node.
%
% The search process may be strict or flexible, depending on what
% combination of parameters is provided: name, broadType, and/or index.
% The valid combinations are listed below.  Other combinations are not
% valid.
%
% rtbFindSceneElement( ... 'name', name) If only the name is provided, the
% entire scene is searched for an element whose own name is the closest
% match for the given name.  See mexximpStringMatcher().
%
% rtbFindSceneElement( ... 'name', name, 'broadType', broadType) If name and
% broadType are both provided, the broadType is used to limit the scope of
% the name matching to elements of that type.
%
% rtbFindSceneElement( ... 'broadType', broadType) If only the broadType is
% provided, the the first element of that type is returned, if any exists.
%
% rtbFindSceneElement( ... 'broadType', broadType, 'index', index) If the
% broadType and index are both provided, the index-th element of the given
% broadType is returned, if it exists.
%
% See also mexximpStringMatcher
%
% element = rtbFindSceneElement(scene, name, broadType, index)
%
% Copyright (c) 2016 mexximp Team

parser = inputParser();
parser.addRequired('scene', @isstruct);
parser.addParameter('name', '', @ischar);
parser.addParameter('broadType', '', @ischar);
parser.addParameter('index', [], @isnumeric);
parser.parse(scene, varargin{:});
scene = parser.Results.scene;
name = parser.Results.name;
broadType = parser.Results.broadType;
index = parser.Results.index;

%% Figure out what parameters we got then delegate to the the right helper.

% name string matching
if ~isempty(name)
    if isempty(broadType)
        element = findByNameAndType(scene, name, '');
        return;
    else
        element = findByNameAndType(scene, name, broadType);
        return;
    end
end

% index lookup
if ~isempty(broadType)
    if isempty(index)
        element = findByTypeAndIndex(scene, broadType, 1);
        return;
    else
        element = findByTypeAndIndex(scene, broadType, index);
        return;
    end
end

%% If we got this far, we don't know how to search.
element = [];

%% Grab an element by name and type.
function element = findByNameAndType(scene, name, broadType)
elements = mexximpSceneElements(scene);
isBroadType = strcmp(broadType, {elements.type});

if ~any(isBroadType)
    element = [];
    return;
end

nameMatcher = mexximpStringMatcher(name);
q = {'name', nameMatcher};
element = mPathGet(elements(isBroadType), {q});


%% Grab and element by type and index.
function element = findByTypeAndIndex(scene, broadType, index)
elements = mexximpSceneElements(scene);
isBroadType = strcmp(broadType, {elements.type});
typeIndexes = find(isBroadType);

if numel(typeIndexes) < index
    element = [];
    return;
end

element = elements(typeIndexes(index));
