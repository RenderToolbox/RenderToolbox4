function scene = rtbApplyMexximpMappings(scene, mappings)
%% Apply mappings with the "mexximp" destination directly to the scene.
%
% scene = rtbApplyMexximpMappings(scene, mappings) adjusts the given scene in
% place, by applying the given mappings as scene adjustments.
%
% This generally amounts to locating scene elements of the mexximp scene
% struct and updating their field values based on the mappings properties.
%
% scene = rtbApplyMexximpMappings(scene, mappings)
%
% Copyright (c) 2016 mexximp Team

parser = inputParser();
parser.addRequired('scene', @isstruct);
parser.addRequired('mappings', @isstruct);
parser.parse(scene, mappings);
scene = parser.Results.scene;
mappings = parser.Results.mappings;

%% Select only the mappings targeted at the mexximp struct.
isMexximp = strcmp('mexximp', {mappings.destination});
mexximpMappings = mappings(isMexximp);
nMexximpMappings = numel(mexximpMappings);

%% Update the scene, one mapping at a time.
for mm = 1:nMexximpMappings
    mapping = mexximpMappings(mm);
    
    % find the element to update
    element = rtbFindSceneElement(scene, ...
        'name', mapping.name, ...
        'broadType', mapping.broadType, ...
        'index', mapping.index);
    if isempty(element)
        continue;
    end
    
    % update its property values
    for pp = 1:numel(mapping.properties)
        property = mapping.properties(pp);
        propertyPath = cat(2, element.path, {property.name});
        oldValue = mPathGet(scene, propertyPath);
        newValue = rtbApplyPropertyOperation(property, oldValue);
        scene = mPathSet(scene, propertyPath, newValue);
    end
end
