function mappingsFile = WriteDefaultMappingsFile(colladaFile, varargin)
%% Write a default mappings file for the given Collada parent scene file.
%
% mappingsFile = WriteDefaultMappingsFile(colladaFile)
% Traverses the Collada document in the given colladaFile and writes a
% new mappingsFile suitable for use with rtbBatchRender().  The
% mappingsFile will specify default values, including matte materials and
% daylight light spectra.
%
% WriteDefaultMappingsFile( ... 'mappingsFile', mappingsFile) specifies the
% name of the new mappings file.  By default the name is based on the name
% of the given colladaFile.
%
% WriteDefaultMappingsFile( ... 'includeFile', includeFile) specifies an
% existing Mappings file to copy and append to.  By default, copies and
% appends to RenderData/DefaultMappings.txt.
%
% WriteDefaultMappingsFile( ... 'reflectances', reflectances) specifies a
% list of reflectances to use for materials in the scene.  By default uses
% various Macbeth Color Checker from RenderData/Macbeth-ColorChecker.
%
% WriteDefaultMappingsFile( ... 'lightSpectra', lightSpectra) specifies a
% list of light spectra to use for lights in the scene.  The default is
% RenderData/D65.spd.
%
% WriteDefaultMappingsFile( ... 'excludePattern', excludePattern) specifies
% a regular expression to use for filtering out elements of the scene.
% Only elements whose id matches the given excludePattern will be included
% in the new mappings file.
%
% Returns the name of the new @a mappingsFile.
%
% mappingsFile = WriteDefaultMappingsFile(colladaFile, varargin)
%
%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

parser = inputParser();
parser.addRequired('colladaFile', @ischar);
parser.addParameter('mappingsFile', '', @ischar);
parser.addParameter('includeFile', '', @ischar);
parser.addParameter('reflectances', {}, @iscellstr);
parser.addParameter('lightSpectra', {'D65.spd'}, @iscellstr);
parser.addParameter('excludePattern', '', @ischar);
parser.parse(colladaFile, varargin{:});
colladaFile = parser.Results.colladaFile;
mappingsFile = parser.Results.mappingsFile;
includeFile = parser.Results.includeFile;
reflectances = parser.Results.reflectances;
lightSpectra = parser.Results.lightSpectra;
excludePattern = parser.Results.excludePattern;

if isempty(includeFile)
    includeFile = fullfile(rtbRoot(), ...
        'BatchRenderer', 'Collada', 'Deprecated', 'RenderData', ...
        'DefaultMappings.txt');
end

[colladaPath, colladaBase] = fileparts(colladaFile);
if isempty(mappingsFile)
    mappingsFile = fullfile(colladaPath, [colladaBase 'DefaultMappings.txt']);
end

if isempty(reflectances)
    % find default Color Checker spectrum files
    macbethPath = fullfile(rtbRoot(), 'RenderData', 'Macbeth-ColorChecker');
    spdPaths = rtbFindFiles('root', macbethPath, 'filter', '\.spd$');
    reflectances = cell(size(spdPaths));
    
    % trim off the full path and sort by spectrum number
    for ii = 1:numel(spdPaths)
        [~, spdBase, spdExt] = fileparts(spdPaths{ii});
        fileName = [spdBase spdExt];
        token = regexp(fileName, '([0-9]+)', 'tokens');
        number = StringToVector(token{1}{1});
        reflectances{number} = fileName;
    end
end

%% Scan the Collada file by element id.

% reduce the Collada file to known characters.
collada7Bit = WriteASCII7BitOnly(colladaFile);

% read the document into memory and delete temp file
colladaDoc = ReadSceneDOM(collada7Bit);
delete(collada7Bit);

% clean up elements and resource paths
cleanDoc = CleanUpColladaDocument(colladaDoc);
idMap = GenerateSceneIDMap(cleanDoc);

% choose a specrtum for each material or light
ids = idMap.keys();
nElements = numel(ids);
elementInfo = struct( ...
    'id', ids, ...
    'category', [], ...
    'type', [], ...
    'propertyName', [], ...
    'propertyValue', [], ...
    'valueType', 'spectrum');
nMaterials = 0;
nLights = 0;
for ii = 1:nElements
    id = ids{ii};
    element = idMap(id);
    
    % exclude this element?
    if ~isempty(excludePattern) && ~isempty(regexp(id, excludePattern, 'once'))
        continue;
    end
    
    nodeName = char(element.getNodeName());
    switch nodeName
        case 'material'
            % choose a color for this material
            nMaterials = nMaterials + 1;
            index = 1 + mod(nMaterials-1, numel(reflectances));
            elementInfo(ii).category = 'material';
            elementInfo(ii).type = 'matte';
            elementInfo(ii).propertyValue = reflectances{index};
            elementInfo(ii).propertyName = 'diffuseReflectance';
            
        case 'light'
            % choose a spectrum for this light
            nLights = nLights + 1;
            index = 1 + mod(nLights-1, numel(lightSpectra));
            elementInfo(ii).category = 'light';
            elementInfo(ii).type = GetColladaLightType(element);
            elementInfo(ii).propertyValue = lightSpectra{index};
            elementInfo(ii).propertyName = 'intensity';
    end
end

%% Dump element info into a mappings file.
% start with the generic default mappings file
mappingsFolder = fileparts(mappingsFile);
if ~isempty(mappingsFolder) && 7 ~= exist(mappingsFolder, 'dir')
    mkdir(mappingsFolder);
end
copyfile(includeFile, mappingsFile);
fid = fopen(mappingsFile, 'a');

% add a block with material colors
isMaterial = strcmp('material', {elementInfo.category});
writeMappingsBlock(fid, 'materials', 'Generic', elementInfo(isMaterial));

% add a block with light spectra
isLight = strcmp('light', {elementInfo.category});
writeMappingsBlock(fid, 'lights', 'Generic', elementInfo(isLight));

fclose(fid);

function writeMappingsBlock(fid, comment, blockName, elementInfo)
fprintf(fid, '\n\n%% %s\n', comment);
fprintf(fid, '%s {\n', blockName);
for ii = 1:numel(elementInfo)
    fprintf(fid, '\t%s:%s:%s\n', elementInfo(ii).id, ...
        elementInfo(ii).category, elementInfo(ii).type);
    fprintf(fid, '\t%s:%s.%s = %s\n\n', elementInfo(ii).id, ...
        elementInfo(ii).propertyName, elementInfo(ii).valueType, ...
        elementInfo(ii).propertyValue);
end
fprintf(fid, '}\n');
