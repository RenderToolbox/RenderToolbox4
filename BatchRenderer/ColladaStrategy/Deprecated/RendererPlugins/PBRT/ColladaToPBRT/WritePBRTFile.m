%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Convert a "node" node from a Collada document to a PBRT-XML document.
%   @param PBRTFile name for a new PBRT scene text file
%   @param PBRTXMLFile name of a PBRT-XML file.
%   @param hints struct of RenderToolbox4 options, see rtbDefaultHints()
%
% @details
% Write an new .pbrt text scene file with the given @a PBRTFile name, based
% on the XML document in the given @a PBRTXMLFile.
%
% @details
% @a PBRTXMLFile must be the name of a PBRT-XML file, as created with
% ColladaToPBRT() or rtbMakeSceneFiles().
%
% @details
% @a hints may be a struct of parameters to use in the conversion process.
%
% @details
% Used internally by ColladaToPBRT().
%
% @details
% Usage:
%   WritePBRTFile(PBRTFile, PBRTXMLFile, hints)
%
% @ingroup ColladaToPBRT
function WritePBRTFile(PBRTFile, PBRTXMLFile, hints)

%% Parameters
% scan the PBRT-XML document
[pbrtDoc, idMap] = ReadSceneDOM(PBRTXMLFile);

% open a new text file to write in
pbrtFID = fopen(PBRTFile, 'w');

if nargin < 3
    hints = rtbDefaultHints();
else
    hints = rtbDefaultHints(hints);
end

%% Top-level PBRT configuration

% get the film, integrator, sampler, and filter from document nodes
filmNodeID = getNodesByIdentifier(idMap, 'Film');
if isempty(filmNodeID)
    warning('Scene does not specify a film!');
else
    writeFilm(pbrtFID, idMap, filmNodeID{1}, hints);
end

integreatorNodeID = getNodesByIdentifier(idMap, 'SurfaceIntegrator');
if isempty(integreatorNodeID)
    warning('Scene does not specify a surface integrator!');
else
    writeIntegrator(pbrtFID, idMap, integreatorNodeID{1}, hints);
end

samplerNodeID = getNodesByIdentifier(idMap, 'Sampler');
if isempty(samplerNodeID)
    warning('Scene does not specify a sampler!');
else
    writeSampler(pbrtFID, idMap, samplerNodeID{1}, hints);
end

filterNodeID = getNodesByIdentifier(idMap, 'PixelFilter');
if isempty(filterNodeID)
    warning('Scene does not specify a pixel filter!');
else
    writeFilter(pbrtFID, idMap, filterNodeID{1}, hints);
end

% find the camera node with transforms and params
cameraNodeIDs = getNodesByIdentifier(idMap, 'CameraNode');
if isempty(cameraNodeIDs)
    warning('Scene does not specify a camera!');
else
    cameraNodeID = cameraNodeIDs{1};
    writeCamera(pbrtFID, idMap, cameraNodeID, hints);
end

%% World-level PBRT objects

% open the "world" declaration
fprintf(pbrtFID, 'WorldBegin\n\n');

% decalre named textures
textureNodeIDs = getNodesByIdentifier(idMap, 'Texture');
for ii = 1:numel(textureNodeIDs)
    writeTexture(pbrtFID, idMap, textureNodeIDs{ii}, hints);
end

% declare named materials
materialNodeIDs = getNodesByIdentifier(idMap, 'Material');
for ii = 1:numel(materialNodeIDs)
    writeMaterial(pbrtFID, idMap, materialNodeIDs{ii}, hints);
end

% declare named objects
shapeNodeIDs = getNodesByIdentifier(idMap, 'Shape');
for ii = 1:numel(shapeNodeIDs)
    % declare a new named object
    fprintf(pbrtFID, 'ObjectBegin "%s"\n', shapeNodeIDs{ii});
    writeObject(pbrtFID, idMap, shapeNodeIDs{ii}, hints);
    fprintf(pbrtFID, 'ObjectEnd\n\n');
end

% declare an Attribute block for each "Attribute" node
attribNodeIDs = getNodesByIdentifier(idMap, 'Attribute');
for ii = 1:numel(attribNodeIDs)
    writeAttribute(pbrtFID, idMap, attribNodeIDs{ii}, hints);
end

% finish the "world" declaration
fprintf(pbrtFID, 'WorldEnd\n');

%% all done!
fclose(pbrtFID);


% Get ids for nodes that have a particular PBRT identifier.
function ids = getNodesByIdentifier(idMap, identifier)
ids = {};
keys = idMap.keys();
for ii = 1:numel(keys)
    id = keys{ii};
    node = idMap(id);
    nodeName = char(node.getNodeName());
    if strcmp(identifier, nodeName)
        ids{end+1} = id;
    end
end


% Get the PBRT identifier and type for a node.
function [identifier, type] = getIdentifierAndType(node)
identifier = char(node.getNodeName());
type = char(node.getAttribute('type'));


% Get the parameters stored under a node.
function params = getParameters(node)
nodes = GetElementChildren(node, 'parameter');
nNodes = numel(nodes);
names = cell(1, nNodes);
types = cell(1, nNodes);
values = cell(1, nNodes);
for ii = 1:nNodes
    names{ii} = char(nodes{ii}.getAttribute('name'));
    types{ii} = char(nodes{ii}.getAttribute('type'));
    values{ii} = char(nodes{ii}.getTextContent());
end
params = struct('name', names, 'type', types, 'value', values);


% Get the references stored under a node.
function refs = getReferences(node)
nodes = GetElementChildren(node, 'reference');
nNodes = numel(nodes);
types = cell(1, nNodes);
values = cell(1, nNodes);
for ii = 1:nNodes
    types{ii} = char(nodes{ii}.getAttribute('type'));
    values{ii} = char(nodes{ii}.getTextContent());
end
refs = struct('type', types, 'value', values);


% Get the transformations stored under a node.
function trans = getTransformations(node)
nodes = GetElementChildren(node, 'transformation');
nNodes = numel(nodes);
types = cell(1, nNodes);
values = cell(1, nNodes);
for ii = 1:nNodes
    types{ii} = char(nodes{ii}.getAttribute('type'));
    values{ii} = char(nodes{ii}.getTextContent());
end
trans = struct('type', types, 'value', values);


% Invert selected transformations (i.e. "undo" them)
function trans = invertTransformations(trans, types)
nTrans = numel(trans);
for ii = 1:nTrans
    % is this transformation one of the selected types?
    if ~any(strcmp(types, trans(ii).type))
        continue;
    end
    
    % convert strings to numeric values
    valueNum = StringToVector(trans(ii).value);
    
    switch trans(ii).type
        case {'Transform', 'ConcatTransform'}
            % full inverse of 4x4 matrix
            original = reshape(valueNum, 4, 4);
            valueNum = inv(original);
            
        case 'Rotate'
            % rotate in opposite direction
            valueNum(1) = -1*valueNum(1);
            
        case 'LookAt'
            % look in opposite direction
            valueNum(4:6) = -1*valueNum(4:6);
            
        case {'Translate', 'Scale'}
            % move or scale in opposite directions
            valueNum = -1*valueNum;
    end
    
    % convert back to strings
    trans(ii).value = VectorToString(valueNum);
end


% Write standard PBRT transformations, with TransformBegin optional.
function writeTransformations(fid, transforms, isBegin)
for ii = 1:numel(transforms)
    t = transforms(ii);
    
    stringOut = '';
    if strcmp(t.type, 'Transform') || strcmp(t.type, 'ConcatTransform')
        % matrix transformation, like Transform [0 1 2 ... 15 16]
        stringOut = sprintf('%s [%s]\n', t.type, t.value);
    else
        % regular transformation, like Translate 0 0 10
        stringOut = sprintf('%s %s\n', t.type, t.value);
    end
    
    if isBegin
        % private transformation, with TransformBegin ...
        stringOut = ['TransformBegin ' stringOut];
    end
    fprintf(fid, stringOut);
end

% Write enough TransformEnd to balance writeTransformations(... true).
function writeEndTransformations(fid, transforms)
for ii = 1:numel(transforms)
    fprintf(fid, 'TransformEnd\n');
end


function writeFilm(fid, idMap, filmNodeID, hints)
% scan the film document node
node = idMap(filmNodeID);
[identifier, type] = getIdentifierAndType(node);
params = getParameters(node);

fprintf(fid, '# Film\n');
PrintPBRTStatement(fid, identifier, type, params);
fprintf(fid, '\n');


function writeIntegrator(fid, idMap, integreatorNodeID, hints)
% scan the integrator document node
node = idMap(integreatorNodeID);
[identifier, type] = getIdentifierAndType(node);
params = getParameters(node);

fprintf(fid, '# Integrator\n');
PrintPBRTStatement(fid, identifier, type, params);
fprintf(fid, '\n');


function writeSampler(fid, idMap, samplerNodeID, hints)
% scan the sampler document node
node = idMap(samplerNodeID);
[identifier, type] = getIdentifierAndType(node);
params = getParameters(node);

fprintf(fid, '# Sampler\n');
PrintPBRTStatement(fid, identifier, type, params);
fprintf(fid, '\n');


function writeFilter(fid, idMap, filterNodeID, hints)
% scan the filter document node
node = idMap(filterNodeID);
[identifier, type] = getIdentifierAndType(node);
params = getParameters(node);

fprintf(fid, '# Filter\n');
PrintPBRTStatement(fid, identifier, type, params);
fprintf(fid, '\n');


function writeCamera(fid, idMap, cameraNodeID, hints)
% get the node around the camera
cameraNode = idMap(cameraNodeID);
nodeTransforms = getTransformations(cameraNode);

% invert camera transforms and reverse order to get point of view
nodeTransforms = invertTransformations( ...
    nodeTransforms, {'Translate', 'Rotate', 'ConcatTransform'});
nodeTransforms = nodeTransforms(end:-1:1);

% follow reference to camera internal parameters
cameraRef = getReferences(cameraNode);
cameraID = cameraRef(1).value;
cameraInternal = idMap(cameraID);
[identifier, type] = getIdentifierAndType(cameraInternal);
internalParams = getParameters(cameraInternal);
internalTransforms = getTransformations(cameraInternal);

% orient the camera internally
fprintf(fid, '# %s internal orientation\n', cameraID);
writeTransformations(fid, internalTransforms, false);

% move the camera for the scene point of view
fprintf(fid, '# %s scene orientation\n', cameraNodeID);
writeTransformations(fid, nodeTransforms, false);

% write out camera internal parameters
fprintf(fid, '# %s\n', cameraID);
PrintPBRTStatement(fid, identifier, type, internalParams);
fprintf(fid, '\n');


function writeTexture(fid, idMap, textureNodeID, hints)
fprintf(fid, '# texture %s\n', textureNodeID);

textureNode = idMap(textureNodeID);

% "type" attribute acts as the PBRT "class", such as imagemap
[identifier, class] = getIdentifierAndType(textureNode);
params = getParameters(textureNode);

% "dataType" parameter acts as the PBRT "type", such as float or spectrum
isType = strcmp('dataType', {params.name});
if any(isType)
    % extract the type parameter as a special keyword
    type = params(isType).value;
    params = params(~isType);
    
else
    % default to float texture
    type = 'float';
end

nameTypeClass = sprintf('%s" "%s" "%s', textureNodeID, type, class);
PrintPBRTStatement(fid, 'Texture', nameTypeClass, params);
fprintf(fid, '\n');


function writeMaterial(fid, idMap, materialNodeID, hints)
fprintf(fid, '# material %s\n', materialNodeID);

materialNode = idMap(materialNodeID);
[identifier, type] = getIdentifierAndType(materialNode);
typeParam.name = 'type';
typeParam.type = 'string';
typeParam.value = type;
params = cat(2, typeParam, getParameters(materialNode));
PrintPBRTStatement(fid, 'MakeNamedMaterial', materialNodeID, params);
fprintf(fid, '\n');


function writeObject(fid, idMap, objectNodeID, hints)
fprintf(fid, '# object %s\n', objectNodeID);

% objects refer to named materials and mesh data files
objectNode = idMap(objectNodeID);
refs = getReferences(objectNode);
nRefs = numel(refs);

% invoke named materials in order
for ii = 1:nRefs
    if strcmp('Material', refs(ii).type)
        % set current material
        fprintf(fid, 'NamedMaterial "%s"\n', refs(ii).value);
    end
end

% include geometries in order
isIncluded = false;
for ii = 1:nRefs
    if strcmp('Include', refs(ii).type)
        % include some geometry
        isIncluded = true;
        fprintf(fid, 'Include "%s"\n', refs(ii).value);
    end
end

% if no geometry included, write out a PBRT shape statement
if ~isIncluded
    % write out a statement
    [identifier, type] = getIdentifierAndType(objectNode);
    params = getParameters(objectNode);
    PrintPBRTStatement(fid, identifier, type, params);
end

fprintf(fid, '\n');


function writeLightSource(fid, idMap, lightNodeID, hints)
fprintf(fid, '# light source %s\n', lightNodeID);

lightNode = idMap(lightNodeID);
[identifier, type] = getIdentifierAndType(lightNode);
params = getParameters(lightNode);
PrintPBRTStatement(fid, identifier, type, params);


function writeAttribute(fid, idMap, attribNodeID, hints)
% scan the node
attribNode = idMap(attribNodeID);
attribTrans = getTransformations(attribNode);
attribRefs = getReferences(attribNode);

% comment the node ID
fprintf(fid, '# %s\n', attribNodeID);

% open an Attribute declaration
fprintf(fid, 'AttributeBegin\n');

% apply transformations, using TransformBegin for each
writeTransformations(fid, attribTrans, true);

% locate attribute nodes by type
types = {attribRefs.type};
isLight = strcmp('LightSource', types) | strcmp('AreaLightSource', types);
isObject = strcmp('Object', types);
isShape = strcmp('Shape', types);

% write regular out light sources
for ii = find(isLight)
    writeLightSource(fid, idMap, attribRefs(ii).value, hints);
end

% write out area light sources or invoke named objects
for ii = find(isObject)
    % is the object an area light?
    objectID = attribRefs(ii).value;
    objectNode = idMap(objectID);
    objectRefs = getReferences(objectNode);
    isAreaLight = strcmp('AreaLightSource', {objectRefs.type});
    if any(isAreaLight)
        % ara lights cannot use instanced objects!
        %   write out the light sources and the object directly
        for jj = find(isAreaLight)
            writeLightSource(fid, idMap, objectRefs(jj).value, hints);
        end
        writeObject(fid, idMap, attribRefs(ii).value, hints)
        
    else
        % non-light objects can use object instances
        fprintf(fid, 'ObjectInstance "%s"\n', attribRefs(ii).value);
    end
end

% write out shapes
for ii = find(isShape)
    % is this an area light?
    objectID = attribRefs(ii).value;
    objectNode = idMap(objectID);
    objectRefs = getReferences(objectNode);
    isAreaLight = strcmp('AreaLightSource', {objectRefs.type});
    if any(isAreaLight)
        % write out the light sources
        for jj = find(isAreaLight)
            writeLightSource(fid, idMap, objectRefs(jj).value, hints);
        end
    end
    
    % write out the shape
    objectNode = idMap(attribRefs(ii).value);
    [identifier, type] = getIdentifierAndType(objectNode);
    params = getParameters(objectNode);
    PrintPBRTStatement(fid, identifier, type, params);
end

% finish transformations with TransformEnd
writeEndTransformations(fid, attribTrans);

% close the Attribute declaration
fprintf(fid, 'AttributeEnd\n\n');
