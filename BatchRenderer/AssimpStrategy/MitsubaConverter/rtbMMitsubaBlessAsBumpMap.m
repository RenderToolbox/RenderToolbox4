function element = rtbMMitsubaBlessAsBumpMap(element, textureId, mitsubaScene, varargin)
%% Turn an existing material into a bumpmap material.
%
% element = rtbMMitsubaBlessAsBumpMap(element, textureId, mitsubaScene)
% creates a new bump map material based on the given material element and
% the given textureId of an existing texture element.
%
% rtbMMitsubaBlessAsBumpMap( ... 'innerMaterialId', innerMaterialId)
% specify how to rename the given element, so that its original id can be
% transferred to the new bump map material.  The default is to append
% '-inner' to the original element id.
%
% rtbMMitsubaBlessAsBumpMap( ... 'scaleTextureId', scaleTextureId)
% specify the name of a "scale" texture that wraps the existing texture.
% The default is to append '-scaled' to the given scaleTextureId.
%
% rtbMMitsubaBlessAsBumpMap( ... 'scale', scale) specify the scale factor
% to apply to the existing texture.  The default is 1, don't change the
% scale of the texture.
%
% Here's an example of the Mitsuba syntax.
%
% We start with an existing texture and existing material.
%
% <texture id="earthTexture" type="bitmap">
%	<float name="gamma" value="1"/>
%	<float name="maxAnisotropy" value="20"/>
%	<float name="uoffset" value="0.0"/>
%	<float name="uscale" value="1.0"/>
%	<float name="voffset" value="0.0"/>
%	<float name="vscale" value="1.0"/>
%	<string name="filename" value="/home/ben/render/VirtualScenes/MiscellaneousData/Textures/earthbump1k-stretch-rgb.exr"/>
%	<string name="filterType" value="ewa"/>
%	<string name="wrapMode" value="repeat"/>
% </texture>
% ...
% <bsdf id="Material-material" type="roughconductor">
% 	<float name="alpha" value="0.4"/>
% 	<spectrum filename="Au.eta.spd" name="eta"/>
% 	<spectrum filename="Au.k.spd" name="k"/>
% </bsdf>
%
% We rename the material because we will want existing shapes
% to refer to a new material that we're about to make, instead
% of the original material.
%
% <bsdf id="Material-material-inner" type="roughconductor">
% 	...
% </bsdf>
%
% We wrap the texture in a "scale" texture so that we can apply
% a scale factor to the bumps.
%
% <texture id="earthBumpMap-scaled" type="scale">
%   <float name="scale" value="0.1"/>
%   <ref id="earthTexture" name="value"/>
% </texture>
%
% Finally, we make a new "bumpmap" material which wraps our
% scale texture and the renamed original material.  We use the
% id of the original material so that existing shapes will
% refer to this new, "blessed" material instead of the
% original.
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('element', @isobject);
parser.addRequired('textureId', @ischar);
parser.addRequired('mitsubaScene', @isobject);
parser.addParameter('innerMaterialId', '', @ischar);
parser.addParameter('scaleTextureId', '', @ischar);
parser.addParameter('scale', 1, @isnumeric);
parser.parse(element, textureId, mitsubaScene, varargin{:});
element = parser.Results.element;
textureId = parser.Results.textureId;
mitsubaScene = parser.Results.mitsubaScene;
innerMaterialId = parser.Results.innerMaterialId;
scaleTextureId = parser.Results.scaleTextureId;
scale = parser.Results.scale;

% rename the original material
originalMaterialId = element.id;
if isempty(innerMaterialId)
    innerMaterialId = [originalMaterialId '-inner'];
end
element.id = innerMaterialId;

% locate the original texture
originalTexture = mitsubaScene.find(textureId, 'type', 'texture');
originalTextureId = originalTexture.id;
if isempty(scaleTextureId)
    scaleTextureId = [originalTextureId '-scaled'];
end

% wrap the original texture in a new scale texture
scaleTexture = MMitsubaElement(scaleTextureId, 'texture', 'scale');
scaleTexture.append(MMitsubaProperty.withData('', 'ref', ...
    'id', originalTextureId, ...
    'name', 'value'));
scaleTexture.setProperty('scale', 'float', scale);

% wrap original material and scaled texture in a "bumpmap" material
bumpmap = MMitsubaElement(originalMaterialId, 'bsdf', 'bumpmap');
bumpmap.append(MMitsubaProperty.withData('', 'ref', ...
    'id', innerMaterialId, ...
    'name', 'bsdf'));
bumpmap.append(MMitsubaProperty.withData('', 'ref', ...
    'id', scaleTextureId, ...
    'name', 'texture'));

% move objects to front in the right order such that:
%   - things that are independent come first
%   - thigs that have "ref" properties come next
%   - elements of the same type are grouped together
%       because our XML writer will group them anyway,
%       and we want the textures to come first
mitsubaScene.prepend(bumpmap);
mitsubaScene.prepend(element);
mitsubaScene.prepend(scaleTexture);
mitsubaScene.prepend(originalTexture);
