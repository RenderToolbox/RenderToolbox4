%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Convert a PBRT-XML "stub" document to receive scene data.
%   @param idMap
%   @param docName
%
% @details
% Create a new XML document based on the given @a idMap of another XML
% document.  @a idMap must be an XML document "id map" as returned from
% ReadSceneDOM().  @a docName is the name for the new document, stored
% internally.
%
% @details
% Returns an XML document reference for a new document, which contains an
% empty "stub" node for each node in idMap.
%
% Also returns an "id map" for the new XML document.
%
% @details
% Used internally by ColladaToPBRT().
%
% @details
% Usage:
%   [stubDoc, stubIDMap] = CreateStubDOM(idMap, docName)
%
% @ingroup ColladaToPBRT
function [stubDoc, stubIDMap] = CreateStubDOM(idMap, docName)

if nargin < 2
    docName = 'stub';
end

%% create a new document
stubDoc = com.mathworks.xml.XMLUtils.createDocument(docName);
stubRoot = stubDoc.getDocumentElement();

%% add a node for each id
ids = idMap.keys();
nIds = numel(ids);
for ii = 1:nIds
    oldNode = idMap(ids{ii});
    name = oldNode.getNodeName();
    
    % ignore the top-level document node
    if strcmp('#document', name)
        continue;
    end
    
    CreateElementChild(stubRoot, name, ids{ii});
end

%% scan the new document for ids and objects
stubIDMap = GenerateSceneIDMap(stubDoc);