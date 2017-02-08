function element = rtbMPbrtBlessAsAreaLight(element, pbrtScene, varargin)
%% Turn an existing Object into an AreaLightSource.
%
% element = rtbMPbrtBlessAsAreaLight(element, pbrtScene) changes an Object
% declratation into an Attribute with an AreaLightSource.
%
% rtbMPbrtBlessAsAreaLight( ... 'L', L) specify an L value to assign to the
% AreaLightSource.  The default is the uniform unit spectrum.
%
% rtbMPbrtBlessAsAreaLight( ... 'nSamples', nSamples) specify the number of
% lighting samples to use for the new AreaLightSource.  The default is 8.
%
% rtbMMitsubaBlessAsAreaLight( ... 'lType', lType) specify a
% property type for the L value.  The default is 'spectrum'.
%
% Here's an example of the PBRT syntax.
%
% We start with an Object declaration and invokation:
% # 1_LightX
% ObjectBegin "1_LightX"
%	NamedMaterial "1_ReflectorMaterial"
%	Include "pbrt-geometry/1_LightX.pbrt"
% ObjectEnd
% ...
% # 1_LightX
% AttributeBegin
%	ConcatTransform [-0.500001 0.000000 -0.866025 0.000000 0.000000 1.000000 0.000000 0.000000 0.866025 0.000000 -0.500001 0.000000 -11.000000 0.000000 11.000000 1.000000]
%	ObjectInstance "1_LightX"
% AttributeEnd
%
% We combine these into one Attribute with an AreaLightSource:
% AttributeBegin
% 	ConcatTransform [-0.500001 0.000000 -0.866025 0.000000 0.000000 1.000000 0.000000 0.000000 0.866025 0.000000 -0.500001 0.000000 -11.000000 0.000000 11.000000 1.000000]
%	AreaLightSource "diffuse"
%       "spectrum L" "D65.spd"
%       "integer nsamples" [8]
%	NamedMaterial "1_ReflectorMaterial"
%	Include "pbrt-geometry/1_LightX.pbrt"
% AttributeEnd%
%
% element = rtbMPbrtBlessAsAreaLight(element, pbrtScene, varargin)
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('element', @isobject);
parser.addRequired('pbrtScene', @isobject);
parser.addParameter('L', '300:1 800:1');
parser.addParameter('nSamples', 8, @isnumeric);
parser.addParameter('lType', 'spectrum', @ischar);
parser.parse(element, pbrtScene, varargin{:});
element = parser.Results.element;
pbrtScene = parser.Results.pbrtScene;
L = parser.Results.L;
lType = parser.Results.lType;
nSamples = parser.Results.nSamples;

% remove the original Object
object = pbrtScene.find('Object', ...
    'name', element.name, ...
    'remove', true);

% locate the object's enclosing Attribute
attribute = pbrtScene.find('Attribute', ...
    'name', element.name);

% remove the original ObjectInstance
attribute.find('ObjectInstance', ...
    'remove', true);

% declare the AreaLightSource in place of the Object
areaLight = MPbrtElement('AreaLightSource', ...
    'name', element.name, ...
    'type', 'diffuse');
areaLight.setParameter('L', lType, L);
areaLight.setParameter('nsamples', 'integer', nSamples);
attribute.append(areaLight);

% move over the original material
material = object.find('NamedMaterial');
attribute.append(material);

% move over the original include file
include = object.find('Include');
attribute.append(include);
