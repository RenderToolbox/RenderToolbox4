%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Write a scene XML document to file.
%   @param sceneFile file name or path to write
%   @param docNode XML document node object 
%
% @details
% Write a new XML scene file with the given @a sceneFile name (which use
% the extension .dae or .xml).  The given @a domDoc must be an XML document
% node as returned from ReadSceneDOM().
%
% @details
% Usage:
%   WriteSceneDOM(sceneFile, docNode)
%
% @ingroup SceneDOM
function WriteSceneDOM(sceneFile, docNode)

xmlwrite(sceneFile, docNode);