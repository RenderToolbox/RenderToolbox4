%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Convert mappings objects to native adjustments for the Mitsuba.
%   @param objects mappings objects as returned from MappingsToObjects()
%   @param adjustments native adjustments to be updated, if any
%
% @details
% This is the RenderToolbox4 "ApplyMappings" function for Mitsuba.
%
% @details
% For more about ApplyMappings functions, see
% RTB_ApplyMappings_SampleRenderer().
%
% @details
% Usage:
%   adjustments = RTB_ApplyMappings_Mitsuba(objects, adjustments)
function adjustments = RTB_ApplyMappings_Mitsuba(objects, adjustments)

% Read in the default Mitsuba adjustments file.
if isempty(adjustments)
    [docNode, idMap] = ReadSceneDOM(getpref('Mitsuba', 'adjustments'));
    adjustments.docNode = docNode;
    adjustments.idMap = idMap;
end

if isempty(objects)
    return;
end

% apply low level "path" mappings directly to the adjustments document
if strcmp('Mitsuba-path', objects(1).blockType)
    ApplySceneDOMPaths(adjustments.idMap, objects);
    return;
end

% convert generic mappings object names and values to mitusba-native
if strcmp('Generic', objects(1).blockType)
    objects = GenericObjectsToMitsuba(objects);
end

% add mappings data to the mitsuba adjustments XML file
ApplyMitsubaObjects(adjustments.idMap, objects);