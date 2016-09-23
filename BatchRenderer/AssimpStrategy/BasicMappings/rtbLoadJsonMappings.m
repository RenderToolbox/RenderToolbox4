function mappings = rtbLoadJsonMappings(fileName)
%% Read mappings from a JSON file and fill in default fields.
%
% mappings = rtbLoadJsonMappings(fileName) reads mappings from JSON stored
% in the given fileName.  Fills in any default fields that were omitted
% from the JSON and ignores fields that are recognized mappings fields.
% Returns a struct array with standard mappings fields and one element per
% mapping.
%
% JSON for mappings must start with a top-level JSON array (ie square
% brackets [...]).  The elements of the top-level array must be JSON
% objects (ie curly braces {...}).  Each JSON object may contain any of the
% top-level mappings fields (see below).  Each JSON object may also contain
% a "properties" field which contains a
%
% mappings = rtbLoadJsonMappings(fileName)
%
% Copyright (c) 2016 mexximp Team

%% Read the given json into a struct.
argParser = inputParser();
argParser.addRequired('fileName', @ischar);
argParser.parse(fileName);
fileName = argParser.Results.fileName;

if 2 == exist(fileName, 'file')
    originalMappings = loadjson(fileName);
else
    originalMappings = {};
end

if ~iscell(originalMappings)
    error('parseJsonMappings:invalidJson', ...
        'Could not load mappings cell from JSON <%s>\n', fileName);
end

mappings = rtbValidateMappings(originalMappings);
