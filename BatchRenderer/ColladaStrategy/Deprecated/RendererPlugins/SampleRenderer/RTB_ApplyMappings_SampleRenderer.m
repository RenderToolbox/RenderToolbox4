%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Convert mappings objects to native adjustments for the SampleRenderer.
%   @param objects mappings objects as returned from MappingsToObjects()
%   @param adjustments native adjustments to be updated, if any
%
% @details
% This function is a template for a RenderToolbox4 "ApplyMappings"
% function.
%
% @details
% The name of an ApplyMappings function must match a specific pattern: it
% must begin with "RTB_ApplyMappings_", and it must end with the name of
% the renderer, for example, "SampleRenderer".  This pattern allows
% RenderToolbox4 to automatically locate the ApplyMappings function for
% each renderer.  ApplyMappings functions should be included in the Matlab
% path.
%
% @details
% An ApplyMappings function must read mappings values from the given
% mappings @a objects and create or update @a adjustments in a renderer's
% native format.  @a objects may be empty but will usually contain data
% parsed from a scene mappings file.  @a adjustments will be used by the
% renderer's ImportCollada function to modify the scene following initial
% Collada conversion.
%
% @details
% @a adjustments may have any renderer-specific format.  Some renderers may
% treat @a adjustments as a file name, and read and write adjustments to
% and from that file.  Other renderers may use @a adjustments as a normal
% Matlab variable to store scene adjustments directly.
%
% @details
% If the @a adjustments parameter is empty, an ApplyMappings function must
% create new renderer-native adjustments from scratch and populate it with
% data from the given @a objects.  Otherwise, an ApplyMappings function
% must update the given @a adjustments based on the the given @a objects.
%
% @details
% An ApplyMappings function must return new or updated renderer-native
% @a adjustments, which incorporates data from the given @a objects.
%
% @details
% Usage:
%   adjustments = RTB_ApplyMappings_SampleRenderer(objects, adjustments)
%
% @ingroup RendererPlugins
function adjustments = RTB_ApplyMappings_SampleRenderer(objects, adjustments)

disp('SampleRenderer ApplyMappings function.')
disp('objects is:')
disp(objects)
disp('adjustments is:')
disp(adjustments)

if isempty(adjustments)
    adjustments.description = 'SampleRenderer adjustments';
end