%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Convert geometry from a Collada document to a PBRT-XML document.
%   @param id
%   @param stubIDMap
%   @param colladaIDMap
%   @param hints struct of RenderToolbox4 options, see rtbDefaultHints()
%
% @details
% Cherry pick from Collada "geometry", "source", "float_array", and
% "mesh" nodes in the Collada document represented by the given @a
% colladaIDMap, and populate the corresponding node of the stub PBRT-XML
% document represented by the given @a stubIDMap.  @a id is the unique
% identifier of the geometry node.  @a hints is a struct of conversion
% hints.
%
% @details
% Returns true if the conversion was successful.
%
% @details
% Used internally by ColladaToPBRT().
%
% @details
% Usage:
%   isConverted = ConvertGeometry(id, stubIDMap, colladaIDMap, hints)
%
% @ingroup ColladaToPBRT
function isConverted = ConvertGeometry(id, stubIDMap, colladaIDMap, hints)

isConverted = true;

%% Find all the geometry mesh polylists.
% get the geometry's main "mesh" object
%   ignoring "convex_mesh" and "spline" geometries
colladaPath = {id, ':mesh'};
meshElement = SearchScene(colladaIDMap, colladaPath, false);
[attrib, name, meshID] = GetElementAttributes(meshElement, 'id');
polyLists = GetElementChildren(meshElement, 'polylist');
nPolylists = numel(polyLists);
for ii = 1:nPolylists
    % make a name for this polylist
    polyName = sprintf('%s_%d', id, ii-1);
    
    % convert geometry for this polylist
    isPolyConverted = convertPolylist(polyName, polyLists{ii}, ...
        id, stubIDMap, colladaIDMap, hints);
end

% Convert polygons from the given polylist.
function isConverted = convertPolylist(polyName, polyList, ...
    id, stubIDMap, colladaIDMap, hints)

isConverted = true;

%% Find the polylist's "VERTEX" data and "POSITION" data.
% find the "VERTEX" reference and offset
vertexInput = GetElementChildren(polyList, 'input', 'semantic', 'VERTEX');
[attrib, name, vertexID] = GetElementAttributes(vertexInput, 'source');
vertexID = vertexID(vertexID ~= '#');
[attrib, name, vertexOffset] = GetElementAttributes(vertexInput, 'offset');
vertexOffset = StringToVector(vertexOffset);

% follow the "VERTEX" reference to a "POSITION" reference
colladaPath = {vertexID, ':input|semantic=POSITION', '.source'};
positionID = GetSceneValue(colladaIDMap, colladaPath);
positionID = positionID(positionID ~= '#');

% follow the "POSITION" reference to actual vertex position data
%   make sure the data are 3-element XYZ
colladaPath = {positionID, ':technique_common', ':accessor' '.stride'};
stride = str2double(GetSceneValue(colladaIDMap, colladaPath));
if stride ~= 3
    warning('"%s" position data are not packed XYZ, geometry not converted.', id);
    isConverted = false;
    return
end

% read actual position data
colladaPath = {positionID, ':float_array'};
positionString = GetSceneValue(colladaIDMap, colladaPath);
position = reshape(StringToVector(positionString), 3, []);

%% Find the polylist's NORMAL data.
normalInput = GetElementChildren(polyList, 'input', 'semantic', 'NORMAL');
if isempty(normalInput)
    % one normals for all vertices
    colladaPath = {vertexID, ':input|semantic=NORMAL', '.source'};
    normalID = GetSceneValue(colladaIDMap, colladaPath);
    normalID = normalID(normalID ~= '#');
    normalOffset = 0;
else
    % separate normals for each polylist
    [attrib, name, normalID] = GetElementAttributes(normalInput, 'source');
    normalID = normalID(normalID ~= '#');
    [attrib, name, normalOffset] = GetElementAttributes(normalInput, 'offset');
    normalOffset = StringToVector(normalOffset);
end

% follow the "NORMAL" reference to actual vertex normal data
%   make sure the data are 3-element XYZ
colladaPath = {normalID, ':technique_common', ':accessor' '.stride'};
stride = str2double(GetSceneValue(colladaIDMap, colladaPath));
if stride ~= 3
    warning('"%s" normal data are not packed XYZ, geometry not converted.', id);
    isConverted = false;
    return
end

% read actual normal data
colladaPath = {normalID, ':float_array'};
normalsString = GetSceneValue(colladaIDMap, colladaPath);
normal = reshape(StringToVector(normalsString), 3, []);

%% Find the polylist's TEXCOORD (UV) data, if any.
hasTexCoords = false;
texCoordInput = GetElementChildren(polyList, 'input', 'semantic', 'TEXCOORD');
if isempty(texCoordInput)
    % one texcoords for all vertices
    colladaPath = {vertexID, ':input|semantic=TEXCOORD', '.source'};
    texCoordID = GetSceneValue(colladaIDMap, colladaPath);
    texCoordID = texCoordID(texCoordID ~= '#');
    texCoordOffset = 0;
    hasTexCoords = ~isempty(texCoordID);
else
    % take the first set of coordinates, ignoring the "set" attribute
    [attrib, name, texCoordID] = GetElementAttributes(texCoordInput, 'source');
    texCoordID = texCoordID(texCoordID ~= '#');
    [attrib, name, texCoordOffset] = GetElementAttributes(texCoordInput, 'offset');
    texCoordOffset = StringToVector(texCoordOffset);
    hasTexCoords = ~isempty(texCoordID);
end

if hasTexCoords
    % follow the "TEXCOORD" reference to actual texture coordinate data
    %   make sure the data are 2-element UV
    colladaPath = {texCoordID, ':technique_common', ':accessor' '.stride'};
    stride = str2double(GetSceneValue(colladaIDMap, colladaPath));
    if stride ~= 2
        warning('"%s" texture coordinates are not packed UV, coordinates ignored.', id);
        hasTexCoords = false;
    end
end

% read actual texcoord/UV data
if hasTexCoords
    colladaPath = {texCoordID, ':float_array'};
    texCoordString = GetSceneValue(colladaIDMap, colladaPath);
    texCoord = reshape(StringToVector(texCoordString), 2, []);
    
    % flip the V coordinate to agree with Blender and Mitsuba
    texCoord(2:2:end) = 1 - texCoord(2:2:end);
end

%% Account for the polygons in the polylist.
% total number of polygons
[attrib, name, nPolys] = GetElementAttributes(polyList, 'count');
nPolys = StringToVector(nPolys);

% number of vertices in each polygon
vCountsElement = GetElementChildren(polyList, 'vcount');
polyVertexCounts = char(vCountsElement{1}.getTextContent());
polyVertexCounts = StringToVector(polyVertexCounts);

% vertex indices for each polygon
indicesElement = GetElementChildren(polyList, 'p');
polyIndices = char(indicesElement{1}.getTextContent());
polyIndices = StringToVector(polyIndices);

%% Convert to PBRT-style geometry
% There are two big differences between Collada and PBRT geometry:
%   1. Collada uses n-sided polygons, where PBRT needs triangles.  We can
%   convert polygons to equivalent triangles, and use new indices.
%   2. Collada indexes positions and normals separately, then mixes and
%   matches them for each polygon, where PBRT indexes positions and normals
%   jointly.  This makes it hard to reuse position and normal data: a PBRT
%   vertex index corresponds to the *combination* of Collada position index
%   and normal index.

% make PBRT vertices from Collada combinations of position and normal
nVertices = sum(polyVertexCounts);
indexStride = numel(polyIndices) / nVertices;
vertexData = struct( ...
    'position', cell(1, nVertices), ...
    'normal', cell(1, nVertices), ...
    'texCoord', cell(1, nVertices));
vertexCount = 0;
for ii = 1:indexStride:numel(polyIndices)
    % locate Collada position and normal data
    posIndex = 1 + polyIndices(ii + vertexOffset);
    normIndex = 1 + polyIndices(ii + normalOffset);
    
    % save a new PBRT vertex
    vertexCount = vertexCount + 1;
    vertexData(vertexCount).position = position(:,posIndex);
    vertexData(vertexCount).normal = normal(:,normIndex);
    
    % add texCoord data if any
    if hasTexCoords
        texCoordIndex = 1 + polyIndices(ii + texCoordOffset);
        vertexData(vertexCount).texCoord = texCoord(:,texCoordIndex);
    end
end

% convert polygons to equivalent triangels
%   each vertex more than 3 incurs a new triangle
nTriangles = sum(polyVertexCounts - 2);
pbrtIndices = zeros(1, 3*nTriangles);
pbrtCount = 0;
polyStartIndices = 1 + [0; cumsum(polyVertexCounts(1:end-1))];
for ii = 1:nPolys
    nVerts = polyVertexCounts(ii);
    vertIndices = polyStartIndices(ii) + (0:(nVerts-1));
    
    if nVerts == 3
        % already a triangle, copy indices (as zero-based)
        zeroIndices = vertIndices - 1;
        pbrtIndices(pbrtCount + (1:3)) = zeroIndices;
        pbrtCount = pbrtCount + 3;
        
    elseif nVerts > 3
        % compute equivalent triangles for a polygon
        polyData = vertexData(vertIndices);
        polyPos = cat(2, polyData.position)';
        
        % represent arbitrary 3D polygon in 2D
        %   translate vertices to near the origin for FindLinMod()
        meanPos = mean(polyPos, 1);
        meanPosRep = repmat(meanPos, size(polyPos, 1), 1);
        polyPosCentered = polyPos - meanPosRep;
        [basis, coefs] = FindLinMod(polyPosCentered', 2);
        polyPos2D = coefs';
        
        % compute 2D Delaunay triangulation
        triIndices = delaunay(polyPos2D);
        
        % copy indices for each Delaunay triangle (as zero-based)
        %   preserve the winding order of the original polygon
        isPolygonClockwise = IsVerticesClockwise(polyPos);
        nTriangles = size(triIndices, 1);
        for tt = 1:nTriangles
            trianglePos = polyPos(triIndices(tt,:), :);
            isTriangleClockwise = IsVerticesClockwise(trianglePos);
            
            % flip winding order if the triangle came out backwards
            if xor(isPolygonClockwise, isTriangleClockwise)
                windOrder = [1 3 2];
            else
                windOrder = [1 2 3];
            end
            
            % store triangle indices for PBRT
            zeroIndices = vertIndices(triIndices(tt,:)) - 1;
            pbrtIndices(pbrtCount + windOrder) = zeroIndices;
            pbrtCount = pbrtCount + 3;
        end
        
    else
        % not a polygon!
        warning('"%s" polygon #%d has only %d vertices--ignored.', ...
            id, ii, nVerts);
    end
end

%% Write mesh data to a PBRT include file.
%   We could add mesh data directly to the PBRT stub document, but large
%   meshes make it hard for humans to read the document, and very large
%   meshes cause the XML DOM to run out of memory!

% create a new file named like the polylist name
%   put it in the working scenes folder
meshFolder = 'pbrt-mesh-data';
meshFullPath = fullfile(rtbWorkingFolder( ...
    'folderName', 'scenes', ...
    'rendererSpecific', true, ...
    'hints', hints), meshFolder);
if ~exist(meshFullPath, 'dir')
    mkdir(meshFullPath);
end
meshName = sprintf('mesh-data-%s.pbrt', polyName);
meshFilePath = fullfile(meshFullPath, meshName);
fid = fopen(meshFilePath, 'w');
fprintf(fid, '# mesh data %s\n', polyName);

% assemble mesh data and PBRT file format metadata
identifier = 'Shape';
type = 'trianglemesh';
pbrtPositions = cat(1, vertexData.position);
pbrtNormals = cat(1, vertexData.normal);
params = struct( ...
    'name', {'P', 'N', 'indices'}, ...
    'type', {'point', 'normal', 'integer'}, ...
    'value', {pbrtPositions, pbrtNormals, pbrtIndices});

% add texture UV coordinates, if any
if hasTexCoords
    uv.name = 'uv';
    uv.type = 'float';
    uv.value = cat(1, vertexData.texCoord);
    params(end+1) = uv;
end

% fill in the file with a giant PBRT statement
PrintPBRTStatement(fid, identifier, type, params);
fclose(fid);

%% Add to the geometry node with material and geometry to include.
SetType(stubIDMap, id, 'Shape', 'trianglemesh');

% set a material for this polylist?
[attrib, name, materialID] = GetElementAttributes(polyList, 'material');
if ischar(materialID) && ~isempty(materialID)
    % Blender-Collada hack:
    % before blender ~2.6, polylists referred to materials by name, not by
    % id.  Append "-material" to the name to get the id.
    materialIDHack = [materialID '-material'];
    if stubIDMap.isKey(materialIDHack)
        materialID = materialIDHack;
    end
    
    if stubIDMap.isKey(materialID)
        refName = [polyName '-material'];
        AddReference(stubIDMap, id, refName, 'Material', materialID);
    end
end


% include the newly converted geometry
% use relative path for portability
includeName = rtbGetWorkingRelativePath(meshFilePath, 'hints', hints);
AddReference(stubIDMap, id, polyName, 'Include', includeName);

