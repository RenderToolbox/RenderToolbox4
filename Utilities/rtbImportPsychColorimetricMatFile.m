function outFiles = rtbImportPsychColorimetricMatFile(inFile, outFile, varargin)
%% Convert a Psychtooblox colorimetric mat-file to text spd-files.
%
% outFiles = rtbImportPsychColorimetricMatFile(inFile, outFile) Converts
% the Psychtoolbox colorimetric mat-file inFile to one or more
% text spd-files named outFile.  Text spd-files are suitable for use
% with physically based renderers like PBRT and Mitsuba.
%
% inFile should be the name of a mat-file which obeys Psychtoolbox
% colorimetric mat file conventions.  The name should use a descriptive
% prefix, followed by an underscore, followed by a specific name.  For
% example, RenderToolbox includes "sur_mccBabel.mat":
%   - the prefix "sur" describes the data a surface reflectance
%   - the name "mccBabel" refers to Macbetch Color Checker data from the
%   BabelColor company.
%
% Returns a cell array of file names for new text spd-files.
%
% For more about Psychtooblox colorimetric mat-files and conventions, see
% the Psychtoolbox web documentation
%   http://docs.psychtoolbox.org/PsychColorimetricMatFiles
% or the file
%   Psychtoolbox/PsychColorimetricData/PsychColorimetricMatFiles/Contents.m
%
% If inFile contains measurements for just one object, the new text file
% will have the given name outFile.  If inFile contains measurements
% for multiple objects, a separate text file will be written for each
% object, using the base name of outFile, plus a numeric suffix.  For
% example, "sur_mccBabel.mat" would produce a file named "mccBabel-24.spd".
%
% By convention, all Psychtoolbox colorimetric mat-files describe power
% spectra as power-per-wavelength-band.  This differs from text .spd files,
% which should describe power spectra as power-per-nanometer.  If inFile
% obeys Psychtoolbox conventions for spectral power mat-files, spectrum
% samples will be divided by the spectral band width to put them in units
% of power-per-nanometer.  Psychtoolbox conventions for power spectra
% include using prefix "spd", and storing data with one column per object.
%
% rtbImportPsychColorimetricMatFile( ... 'divideBands', divideBands)
% specifies whether to divide spectrum samples by their band widths.  The
% default value is 'psychtoolbox', which will attempt to follow the
% Psychtoolbox conventions above.  The value 'yes' will divide samples by
% their band widths unconditionally.  The value 'no' will leave samples
% alone unconditionally.
%
%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

parser = inputParser();
parser.addRequired('inFile', @ischar);
parser.addRequired('outFile', @ischar);
parser.addParameter('divideBands', 'psychtoolbox', @ischar);
parser.parse(inFile, outFile, varargin{:});
inFile = parser.Results.inFile;
outFile = parser.Results.outFile;
divideBands = parser.Results.divideBands;

[outPath, outBase, outExt] = fileparts(outFile);

if strcmp('psychtoolbox', divideBands)
    isObeyPsychConvention = true;
    isDivideBands = false;
elseif strcmp('yes', divideBands)
    isObeyPsychConvention = false;
    isDivideBands = true;
else
    isObeyPsychConvention = false;
    isDivideBands = false;
end


%% Read and interpret the Psychtoolbox data.
% determine the format of spectral data from Psychtoolbox conventions
[psychData, psychS, psychPrefix] = ...
    rtbParsePsychColorimetricMatFile(inFile);
psychWavelengths = SToWls(psychS);

% reformat specrtal data respecting Psychtoolbox conventions
%   for current purposes, want objects in matrix columns, and may need to
%   scale power units to be Power per Unit Wavelength
switch psychPrefix
    case {'B', 'den', 'sur', 'srf'}
        % for basis functions, optical densities, and reflectance spectra,
        % objects are already in data columns and there is no need to scale
        % data by sampling bandwidth.
        
    case 'spd'
        % for power distributins, objects are already in data columns but
        % we need to scale data by sampling bandwidth.
        if isObeyPsychConvention
            isDivideBands = true;
        end
        
    case 'T'
        % for matching functions and sensitivities, transpose data to put
        % objects in data columns, but there is no need to scale data by
        % sampling bandwidth.
        psychData = psychData';
        
    otherwise
        warning('Unknown Psychtooblox data prefix "%s" for file\n  %s', ...
            psychPrefix, inFile);
end

% "divide out" of Psychtoolbox convention of Power per Wavelength Band
if isDivideBands
    psychData = rtbSpdPowerPerWlBandToPowerPerNm(psychData, psychS);
end

%% Write data to new text .spd files.

% create the output folder as needed
if ~exist(outPath, 'dir')
    mkdir(outPath);
end

% write a text file for the object in each data column
nObjects = size(psychData, 2);
outFiles = cell(1, nObjects);
for ii = 1:nObjects
    % choose a name for this output file
    if nObjects > 1
        outName = sprintf('%s-%d%s', outBase, ii, outExt);
    else
        outName = [outBase, outExt];
    end
    outFiles{ii} = fullfile(outPath, outName);
    
    % write a line for each wavelength sampled
    fid = fopen(outFiles{ii}, 'w');
    for w = 1:numel(psychWavelengths)
        fprintf(fid, '%d %f\n', psychWavelengths(w), psychData(w,ii));
    end
    fprintf(fid, '\n');
    fclose(fid);
end