function element = rtbMPbrtBlessAsBumpMap(element, textureName, pbrtScene, varargin)
%% Turn an existing material into a bumpmap material.
%
% element = rtbMPbrtBlessAsBumpMap(element, textureName, pbrtScene)
% creates a new bump map material based on the given material element and
% the given textureName of an existing texture element.
%
% rtbMPbrtBlessAsBumpMap( ... 'scaleTextureName', scaleTextureName)
% specify the name of a "scale" texture that wraps the existing texture.
% The default is to append '-scaled' to the given scaleTextureName.
%
% rtbMPbrtBlessAsBumpMap( ... 'scale', scale) specify the scale factor
% to apply to the existing texture.  The default is 1, don't change the
% scale of the texture.
%
% Here's an example of the PBRT syntax.
%
% We start with a float imagemap texture and a material
% # texture earthTexture
% Texture "earthTexture" "float" "imagemap"
%	"string filename" "earthbump1k-stretch-rgb.exr"
%	"float gamma" [1]
%	"float maxanisotropy" [20]
%	"bool trilinear" "false"
%	"float udelta" [0.0]
%	"float uscale" [1.0]
%	"float vdelta" [0.0]
%	"float vscale" [1.0]
%	"string wrap" "repeat"
% ...
% # material Material-material
% MakeNamedMaterial "Material-material"
%   "string type" "matte"
%   "spectrum Kd" "mccBabel-11.spd"
%
% We enclose the texture in a "scale" texture so that we can
% apply a scale factor.  Then we add this scale texture to the
% existing material.  We also need to sort these elements
% because they depend on each other.
%
% Texture "earthTexture" "float" "imagemap" ...
%
% Texture "earthBumpMap-scaled" "float" "scale"
%    "texture tex1" "earthTexture"
%    "float tex2" [0.1]
%
% # material Material-material
% MakeNamedMaterial "Material-material"
%    "string type" "matte"
%    "spectrum Kd" "mccBabel-11.spd"
%    "texture bumpmap" "earthBumpMap-scaled"
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('element', @isobject);
parser.addRequired('textureName', @ischar);
parser.addRequired('pbrtScene', @isobject);
parser.addParameter('scaleTextureName', '', @ischar);
parser.addParameter('scale', 1, @isnumeric);
parser.parse(element, textureName, pbrtScene, varargin{:});
element = parser.Results.element;
textureName = parser.Results.textureName;
pbrtScene = parser.Results.pbrtScene;
scaleTextureName = parser.Results.scaleTextureName;
scale = parser.Results.scale;

% locate the original texture
originalTexture = pbrtScene.world.find('Texture', 'name', textureName);

% wrap the original texture in a new scale texture
if isempty(scaleTextureName)
    scaleTextureName = [originalTexture.name '_scaled'];
end
scaleTexture = MPbrtElement.texture(scaleTextureName, 'float', 'scale');
scaleTexture.setParameter('tex1', 'texture', originalTexture.name);
scaleTexture.setParameter('tex2', 'float', scale);
pbrtScene.world.prepend(scaleTexture);

% move textures to the front, in dependency order
pbrtScene.world.prepend(scaleTexture);
pbrtScene.world.prepend(originalTexture);

% add the scale texture to the blessed material
element.setParameter('bumpmap', 'texture', scaleTextureName);
