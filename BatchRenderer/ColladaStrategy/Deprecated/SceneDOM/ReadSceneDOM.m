%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Read a scene XML document from file.
%   @param sceneFile file name or path to read
%   @param excludePattern regular expression to filter document elements
%
% @details
% Read the given XML @a sceneFile (.dae or .xml).  The @a sceneFile should
% be a Collada scene file, or a renderer adjustments file.  <a
% href="https://collada.org/mediawiki/index.php/COLLADA_-_Digital_Asset_and_FX_Exchange_Schema">Collada</a>
% is is an XML-based format for exchanging 3D models and assets.  Renderer
% <a
% href="https://github.com/DavidBrainard/RenderToolbox4/wiki/Adjustments-Files">Adjustments
% Files</a> introduce scene elements that Collada doesn't know about.
%
% @details
% Returns an XML Document Object Model (DOM) document node.  DOM is a
% programmatic interface for XML files that takes advantage of XML document
% structure and takes care of reading and writing files.
%
% @details
% Also returns an "id map" that represent the document in terms of elements
% that have unique identifiers (id attributes).  If @a excludePattern is
% provided, it must be a regular expression to match against element node
% names.  Elements whose names match @a excludePattern will not be added to
% the id map.
%
% @details
% Usage:
%   [docNode, idMap] = ReadSceneDOM(sceneFile, excludePattern)
%
% @ingroup SceneDOM
function [docNode, idMap] = ReadSceneDOM(sceneFile, excludePattern)

if nargin < 2
    excludePattern = '';
end

docNode = [];
idMap = [];

try
    % open the file for parsing
    docNode = xmlread(sceneFile);
catch err
    disp(['Error reading XML file: ' sceneFile])
    disp(err.message)
    return;
end

% scan the document for nodes that have ids
idMap = GenerateSceneIDMap(docNode, excludePattern);