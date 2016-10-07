%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Convert a "node" node from a Collada document to a PBRT-XML document.
%   @param id
%   @param stubIDMap
%   @param colladaIDMap
%   @param hints struct of RenderToolbox4 options, see rtbDefaultHints()
%
% @details
% Cherry pick from a Collada "node" node in the Collada document
% represented by the given @a colladaIDMap, and populate the corresponding
% node of the stub PBRT-XML document represented by the given @a
% stubIDMap.  @a id is the unique identifier of the "node" node.  @a
% hints is a struct of conversion hints.
%
% @details
% Returns true if the conversion was successful.
%
% @details
% Used internally by ColladaToPBRT().
%
% @details
% Usage:
%   isConverted = ConvertNode(id, stubIDMap, colladaIDMap, hints)
%
% @ingroup ColladaToPBRT
function isConverted = ConvertNode(id, stubIDMap, colladaIDMap, hints)

isConverted = true;

% declare a top-level world object
SetType(stubIDMap, id, 'Attribute', '');

% add spatial transformations from child nodes
[children, names] = GetElementChildren(colladaIDMap(id));
for ii = 1:numel(children)
    
    childPath = GetNodePath(children{ii}, 'sid');
    childNodeName = names{ii};
    [attr, attrName, childSid] = GetElementAttributes(children{ii}, 'sid');
    
    switch childNodeName
        case 'translate'
            value = GetSceneValue(colladaIDMap, childPath);
            AddTransform(stubIDMap, id, childSid, 'Translate', value);
            
        case 'rotate'
            value = getConvertedRotation(colladaIDMap, childPath);
            AddTransform(stubIDMap, id, childSid, 'Rotate', value);
            
        case 'scale'
            value = GetSceneValue(colladaIDMap, childPath);
            AddTransform(stubIDMap, id, childSid, 'Scale', value);
            
        case 'matrix'
            value = getConvertedMatrix(colladaIDMap, childPath);
            AddTransform(stubIDMap, id, childSid, 'ConcatTransform', value);
            
        case 'lookat'
            value = GetSceneValue(colladaIDMap, childPath);
            AddTransform(stubIDMap, id, childSid, 'LookAt', value);
            
    end
end


% Get Collada [x y z angle], convert to PBRT [angle x y z]
function pbrtNum = getConvertedRotation(colladaIDMap, colladaPath)
rotationString = GetSceneValue(colladaIDMap, colladaPath);
rotationNum = StringToVector(rotationString);
pbrtNum = rotationNum([4 1 2 3]);


% Collada gives row-major matrices.  PBRT files seem to want column-major.
function pbrtNum = getConvertedMatrix(colladaIDMap, colladaPath)
matrixString = GetSceneValue(colladaIDMap, colladaPath);
matrixNum = StringToVector(matrixString);
indices = reshape(1:16, 4, 4)';
pbrtNum = matrixNum(indices(:));
