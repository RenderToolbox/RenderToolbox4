%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Clean up a Collada document to for known elements and resource paths.
%   @param colladaDoc Collada Xml document from ReadSceneDOM
%   @param workingFolder path to search for resources like images
%
% @details
% Traverses the given @a colladaDoc and creates a new, cleaned-up Xml
% document based on it.  The cleaned-up document will contain basic scene
% elements including cameras, lights, and geometry.  It will replace
% non-physically based lights and materials with placeholders.  It will
% omit fancier scene elemnets like animations, controllers, force fields,
% and physics.
%
% @details
% Attempts to obey the Collada 1.4 schema, so that the new @a reducedFile
% will be a valid Collada file.  See
%   http://www.khronos.org/collada/
% for more about the Collada XML schema.  This cheat sheet is especially
% useful:
%   http://www.khronos.org/files/collada_reference_card_1_4.pdf
%
% @details
% If @a workingFolder is provided, it should be a folder to search
% recursively for resource files named in the given @a colladaFile.  If a
% resource file is found within the given @a workingFolder, the cleaned-up
% document will use the relative path to the resource, instead of the
% file name.  This is useful in case the folder layout used during
% 3D modeling is different from the folder layout used during rendering.
% This is almost certainly the case when the given @a colladaDoc is from a
% "wild" scene downloaded from the internet.
%
% @details
% Returns a new, cleaned-up Xml document based on the given @a colladaDoc.
%
% @details
% Usage:
%   cleanedUpDoc = WriteReducedColladaScene(colladaFile, reducedFile)
%
% @ingroup SceneDOM
function cleanDoc = CleanUpColladaDocument(colladaDoc, workingFolder)

if nargin < 2 || isempty(workingFolder)
    workingFolder = '';
end

% create a new, empty XML document
colladaRoot = colladaDoc.getDocumentElement();
docName = char(colladaRoot.getNodeName());
cleanDoc = com.mathworks.xml.XMLUtils.createDocument(docName);
cleanRoot = cleanDoc.getDocumentElement();

% define which Collada top-level libraries to ignore
ignoredElements = { ...
    'library_animations', ...
    'library_animation_clips', ...
    'library_controllers', ...
    'library_force_fields', ...
    'library_physics_materials', ...
    'library_physics_models', ...
    'library_physics_scenes', ...
    };

% check each of the top-level Collada nodes
%   skip the ones in the list of ignoredElements
%   copy and modify some as special cases
%   copy the rest as-is
libraryElements = GetElementChildren(colladaRoot);
nElements = numel(libraryElements);
for ii = 1:nElements
    element = libraryElements{ii};
    elementName = char(element.getNodeName());
    
    switch elementName
        case ignoredElements
            % skip fancy scene elements
            continue;
            
%         case 'library_images'
%             if isempty(workingFolder)
%                 continue;
%             end
%             
%             % replace image file names with workingFolder relative path
%             elementClone = cleanDoc.importNode(element, true);
%             cleanRoot.appendChild(elementClone);
%             ConvertColladaImages(elementClone, workingFolder);
            
        case 'library_effects'
            % replace each effect with a physically-based phong effect
            elementClone = cleanDoc.importNode(element, true);
            cleanRoot.appendChild(elementClone);
            ConvertColladaEffects(elementClone);
            
        case 'library_lights'
            % replace ambient lights with directional
            elementClone = cleanDoc.importNode(element, true);
            cleanRoot.appendChild(elementClone);
            ConvertColladaLights(elementClone);
            
        otherwise
            % make deep copies of basic scene elements
            elementClone = cleanDoc.importNode(element, true);
            cleanRoot.appendChild(elementClone);
    end
end