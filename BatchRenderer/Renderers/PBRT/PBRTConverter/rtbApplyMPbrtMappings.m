function pbrtScene = rtbApplyMPbrtMappings(pbrtScene, mappings)
%% Apply mappings with the "PBRT" destination directly to the scene.
%
% scene = rtbApplyMPbrtMappings(pbrtScene, mappings) adjusts the given mPbrt
% pbrtScenein place, by applying the given mappings as scene adjustments.
%
% This generally amounts to locating scene elements of the scene object and
% updating their field values based on the mappings properties.
%
% pbrtScene = rtbApplyMPbrtMappings(pbrtScene, mappings)
%
% Copyright (c) 2016 mexximp Team

parser = inputParser();
parser.addRequired('pbrtScene', @isobject);
parser.addRequired('mappings', @isstruct);
parser.parse(pbrtScene, mappings);
pbrtScene = parser.Results.pbrtScene;
mappings = parser.Results.mappings;

%% Select only the mappings targeted at the PBRT object.
isPbrt = strcmp('PBRT', {mappings.destination});
pbrtMappings = mappings(isPbrt);
nPbrtMappings = numel(pbrtMappings);

%% Update the scene, one mapping at a time.
for mm = 1:nPbrtMappings
    %% Create/find/delete a scene element.
    mapping = pbrtMappings(mm);
    element = rtbApplyMPbrtMappingOperation(pbrtScene, mapping);
    if isempty(element)
        continue;
    end
    
    %% Update element properties.
    if ~isempty(mapping.specificType)
        element.type = mapping.specificType;
    end
    for pp = 1:numel(mapping.properties)
        property = mapping.properties(pp);
        oldValue = element.getParameter(property.name);
        newValue = rtbApplyPropertyOperation(property, oldValue);
        element.setParameter(property.name, property.valueType, newValue);
    end
end
