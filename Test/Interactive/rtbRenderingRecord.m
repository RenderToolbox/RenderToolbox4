function record = rtbRenderingRecord(varargin)
% Make a well-formed struct to represent a rendering data file.
%
% The idea is to represent a rendering result using a consistent
% struct format.  This will make it easier to compare sets of renderings
% because we can compare rendering records for equality without worrying
% about fussy syntax details of file names and paths.
%
% record = rtbRenderingRecord() creates a placeholder record with the
% correct fields.
%
% record = rtbRenderingRecord( ... name, value) fills in the record with
% fields based on the given names-value pairs.  Unrecognized names
% will be ignored.
%
%%% RenderToolbox4 Copyright (c) 2012-2017 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.KeepUnmatched = true;
parser.addParameter('recipeName', '', @ischar);
parser.addParameter('rendererName', '', @ischar);
parser.addParameter('imageNumber', [], @isnumeric);
parser.addParameter('imageName', '',@ischar);
parser.addParameter('fileName', '', @ischar);
parser.parse(varargin{:});

% let the parser do all the work
record = parser.Results;
