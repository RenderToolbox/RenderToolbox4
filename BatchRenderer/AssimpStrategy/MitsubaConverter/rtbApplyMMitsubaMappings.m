function mitsubaScene = rtbApplyMMitsubaMappings(mitsubaScene, mappings)
%% Apply mappings with the "Mitsuba" destination directly to the scene.
%
% scene = rtbApplyMMitsubaMappings(mitsubaScene, mappings) adjusts the given
% mMitsuba scene place, by applying the given mappings as scene
% adjustments.
%
% This generally amounts to locating scene elements of the scene object and
% updating their field values based on the mappings properties.
%
% mitsubaScene = rtbApplyMMitsubaMappings(mitsubaScene, mappings)
%
% Copyright (c) 2016 mexximp Team

parser = inputParser();
parser.addRequired('mitsubaScene', @isobject);
parser.addRequired('mappings', @isstruct);
parser.parse(mitsubaScene, mappings);
mitsubaScene = parser.Results.mitsubaScene;
mappings = parser.Results.mappings;

%% Select only the mappings targeted at the Mitsuba object.
isMitsuba = strcmp('Mitsuba', {mappings.destination});
mitsubaMappings = mappings(isMitsuba);
nMitsubaMappings = numel(mitsubaMappings);

%% Update the scene, one mapping at a time.
for mm = 1:nMitsubaMappings
    %% Create/find/delete a scene element.
    mapping = mitsubaMappings(mm);
    element = rtbApplyMMitsubaMappingOperation(mitsubaScene, mapping);
    if isempty(element)
        continue;
    end
    
    %% Update element properties.
    if ~isempty(mapping.specificType)
        element.pluginType = mapping.specificType;
    end
    for pp = 1:numel(mapping.properties)
        property = mapping.properties(pp);
        oldValue = element.getProperty(property.name);
        newValue = rtbApplyPropertyOperation(property, oldValue);
        element.setProperty(property.name, property.valueType, newValue);
    end
end
