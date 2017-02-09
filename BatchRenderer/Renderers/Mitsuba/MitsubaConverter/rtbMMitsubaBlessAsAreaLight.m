function element = rtbMMitsubaBlessAsAreaLight(element, varargin)
%% Turn an existing shape into an area emitter.
%
% element = rtbMMitsubaBlessAsAreaLight(element) adds an emitter
% declaration nested within the given element.
%
% rtbMMitsubaBlessAsAreaLight( ... 'radiance', radiance) specify a radiance
% value to assign to the emitter.  The default is the uniform unit
% spectrum.
%
% rtbMMitsubaBlessAsAreaLight( ... 'radianceType', radianceType) specify a
% property type for the radiance value.  The default is 'spectrum'.
%
% rtbMMitsubaBlessAsAreaLight( ... 'emitterId', emitterId) specify an
% element id for the new emitter.  The default is to append '-emitter' to
% the id of the given element.
%
% Here's an example of the Mitsuba syntax.
%
% We start with a shape declaration like this:
% <shape id="LightY-mesh_0" type="serialized">
%   <string name="filename" value="Dragon-001Unadjusted.serialized"/>
%   ...
% </shape>
%
% We add an emitter nested in the mesh like this:
% <shape id="LightY-mesh_0" type="serialized">
%   <string name="filename" value="Dragon-001Unadjusted.serialized"/>
%   <emitter id="LightY-mesh_0-area-light" type="area">
%     <spectrum filename="D65.spd" name="radiance"/>
%   </emitter>
%   ...
% </shape>
%
% element = rtbMMitsubaBlessAsAreaLight(element, varargin)
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('element', @isobject);
parser.addParameter('radiance', 1);
parser.addParameter('radianceType', 'spectrum', @ischar);
parser.addParameter('emitterId', '', @ischar);
parser.parse(element, varargin{:});
element = parser.Results.element;
radiance = parser.Results.radiance;
radianceType = parser.Results.radianceType;
emitterId = parser.Results.emitterId;

if isempty(emitterId)
    emitterId = [element.id '-emitter'];
end

% create the emitter element
emitter = MMitsubaElement(emitterId, 'emitter', 'area');
emitter.setProperty('radiance', radianceType, radiance);

% nest the emitter inside the given element
element.append(emitter);
