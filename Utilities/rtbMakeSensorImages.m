function outFiles = rtbMakeSensorImages(inFiles, matchingFunctions, varargin)
%% Write sensor image data files based on multi-spectral data files.
%
% outFiles = rtbMakeSensorImages(inFiles, matchingFunctions)
% Writes new mat-files that contain sensor images, one for each of the
% multi-spectral data files given in inFiles.  inFiles must be a cell array
% of multi-spectral mat-files, as produced by rtbBatchRender().
%
% matchingFunctions and specifies the color matching functions used to
% convert multi-spectral data to sensor imgaes.  matchingFunctions must be
% a cell array, where each element specifies a separate color matching
% function.  Each element may have one of two forms:
%   - a numeric matrix containing color mathing data
%   - the string name of a Psychtoolbox colorimetric data file
%
% outFiles = rtbMakeSensorImages( ... 'matchingS', matchingS)
% Specifies the spectral sampling to use along with the given
% matchingFunctions.  matchingS must be a cell array with the same size as
% matchingFunctions, where each element is a Psychtoolbox "S" samplng
% description (see MakeItS).  matchingS is only used when matchingFunctions
% contains numeric matrices.
%
% outFiles = rtbMakeSensorImages( ... 'names', names)
% Specifies descriptive names to go with the sensor images.  names must be
% a cell array of strings with the same size as matchingFunctions, where
% each element.
%
% outFiles = rtbMakeSensorImages( ... 'hints', hints)
% Specifies RenderToolbox4 "hints" to control things like the working
% folder where output should be written.  The default is rtbDefaultHints().
%
% Returns a cell array of sensor image data file names.  Rows of the
% cell array will correspond to elements of inFiles.  Columns of the
% cell array will corrrespond to elements of matchingFunctions.  Each
% data file name will start with the corresponding inFiles name and end
% with a descriptive suffix.  The suffix will be chosen from available
% sources, in order of preference:
%   - one of the given matchingNames
%   - the name of a Psychtoolbox colorimetric data file
%   - a numeric suffix
%
%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

parser = inputParser();
parser.addRequired('inFiles', @iscell);
parser.addRequired('matchingFunctions', @iscell);
parser.addParameter('matchingS', {}, @iscell);
parser.addParameter('names', {}, @iscell);
parser.addParameter('hints', rtbDefaultHints(), @isstruct);
parser.parse(inFiles, matchingFunctions, varargin{:});
inFiles = parser.Results.inFiles;
matchingFunctions = parser.Results.matchingFunctions;
matchingS = parser.Results.matchingS;
names = parser.Results.names;
hints = rtbDefaultHints(parser.Results.hints);


%% Resolve matching function matrices, spectral samplings, and names.
nMatching = numel(matchingFunctions);
resolvedFunctions = cell(1, nMatching);
resolvedS = cell(1, nMatching);
resolvedNames = cell(1, nMatching);
for ii = 1:nMatching
    % get data, sampling, and possible name
    if ischar(matchingFunctions{ii})
        % load Psychtoolbox colorimetric data and metadata
        [resolvedFunctions{ii}, resolvedS{ii}, ~, name] = ...
            rtbParsePsychColorimetricMatFile(matchingFunctions{ii});
    else
        % take matching function and sampling directly, make up a name
        resolvedFunctions{ii} = matchingFunctions{ii};
        resolvedS{ii} = matchingS{ii};
        name = sprintf('%d', ii);
    end
    
    % use given name or fallback on automatically chosen name
    if ~isempty(names) && ~isempty(names{ii}) && ischar(names{ii})
        resolvedNames{ii} = names{ii};
    else
        resolvedNames{ii} = name;
    end
end

%% Produce a sensor image for each input file and each matching function.
nMultispectral = numel(inFiles);
outFiles = cell(nMultispectral, nMatching);
if hints.isParallel
    % distributed "parfor"
    parfor ii = 1:nMultispectral
        outFiles(ii,:) = makeSensorImages(inFiles{ii}, ...
            resolvedFunctions, resolvedS, resolvedNames, hints);
    end
else
    % local "for"
    for ii = 1:nMultispectral
        outFiles(ii,:) = makeSensorImages(inFiles{ii}, ...
            resolvedFunctions, resolvedS, resolvedNames, hints);
    end
end


%% Produce a sensor image for the input file and each matching function.
function outFiles = makeSensorImages(inFile, ...
    matchFuncs, matchS, matchNames, hints)

nMatching = numel(matchFuncs);
outFiles = cell(1, nMatching);

if ~exist(inFile, 'file')
    return;
end

% read multispectral image and metadata
inData = load(inFile);
[~, inBase, ~] = fileparts(inFile);

% make a sensor image for each mapping function
for ii = 1:nMatching
    % convert multi-spectral to to sensor image
    multispectralImage = inData.multispectralImage;
    imageS = inData.S;
    matchingFunction = matchFuncs{ii};
    matchingS = matchS{ii};
    sensorImage = rtbMultispectralToSensorImage( ...
        multispectralImage, imageS, matchingFunction, matchingS);
    
    % choose a name for the new data file of the form
    %   inputFileName_matchingFunctionName.mat
    outName = [inBase '_' matchNames{ii} '.mat'];
    outFolder = rtbWorkingFolder( ...
        'folderName', 'images', ...
        'rendererSpecific', true, ...
        'hints', hints);
    outFiles{ii} = fullfile(outFolder, outName);
    
    % save sensor image and some metadata
    save(outFiles{ii}, ...
        'sensorImage', ...
        'multispectralImage', ...
        'imageS', ...
        'matchingFunction', ...
        'matchingS');
end