function mappings = ParseMappings(mappingsFile)
%% Read mappings data from a text file.
%
% mappings = ParseMappings(mappingsFile)
% Reads batch renderer mappings from the given mappingsFile.  See the
% RenderToolbox4 wiki for more about mappings files:
%   https://github.com/DavidBrainard/RenderToolbox4/wiki/Mappings-File-Format
%
% Returns a 1xn struct array with mapping data.  The struct array will have
% one element per mapping, and the following fields:
%   - text - raw text before parsing
%   - blockType - block type, 'Collada', 'Generic', 'Mitsuba', or 'PBRT'
%   - blockNumber - the order of the block in the mappings file
%   - group - name of a set of related blocks
%   - left - a struct of info about the left-hand string
%   - operator - the operator string
%   - right - a struct of info about the right-hand string
%
% Each 'left' or 'right' field will contain a struct with data about a
% string, with the following fields
%   - text - the raw text before parsing
%   - enclosing - the enclosing brackets, if any, '[]', '<>', or ''
%   - value - the text found within enclosing brackets
%   .
%
% mappings = ParseMappings(mappingsFile)
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('mappingsFile', @ischar);
parser.parse(mappingsFile);
mappingsFile = parser.Results.mappingsFile;

%% Make a default mappints struct.
mappings = struct( ...
    'text', {}, ...
    'blockType', {}, ...
    'blockNumber', {}, ...
    'group', {}, ...
    'left', {}, ...
    'operator', {}, ...
    'right', {});

%% Prepare to read the mappings file.
if nargin < 1 || ~exist(mappingsFile, 'file')
    return;
end

fid = fopen(mappingsFile, 'r');
if -1 == fid
    warning('Cannot open mappings file "".', mappingsFile);
    return;
end

%% Define regular expressions to parse mapping syntax.
% comments have % as the first non-whitespace
commentPattern = '^\s*\%';

% blocks start with one word followed by {
blockStartPattern = '([^{\s]+)\s+([^{\s]+)\s*{|([^{\s]+)\s*{';

% blocks end with }
blockEndPattern = '}';

% "operators" might start with +-*\, and must end with =
%   and must be flanked with spaces
opPattern = ' ([\+\-\*/]?=) ';

% "values" must start with a non-space
valuePattern = '(\S.+)';

%% Read one line at a time, look for blocks and mappings.
blockType = '';
blockNumber = 0;
groupName = '';
nextLine = '';
while ischar(nextLine)
    % read a line of the mappings file
    nextLine = fgetl(fid);
    if ~ischar(nextLine)
        break;
    end
    
    % skip comment lines
    if regexp(nextLine, commentPattern, 'once')
        continue;
    end
    
    % enter a new block?
    tokens = regexp(nextLine, blockStartPattern, 'tokens');
    if ~isempty(tokens)
        blockNumber = blockNumber + 1;
        
        if 1 == numel(tokens{1})
            % start a block with no group name
            blockType = tokens{1}{1};
            groupName = '';
            continue;
            
        elseif 2 == numel(tokens{1})
            % start a block with a group name
            blockType = tokens{1}{1};
            groupName = tokens{1}{2};
            continue;
        end
    end
    
    % close the current block?
    if regexp(nextLine, blockEndPattern, 'once')
        blockType = '';
        groupName = '';
        continue;
    end
    
    % read a mapping?
    %   mappings must contain at least one value
    if regexp(nextLine, valuePattern, 'once')
        % append a new mapping struct
        n = numel(mappings) + 1;
        mappings(n).text = nextLine;
        mappings(n).blockType = blockType;
        mappings(n).blockNumber = blockNumber;
        mappings(n).group = groupName;
        
        % look for an operator
        [opStart, opEnd] = regexp(nextLine, opPattern, 'start', 'end');
        if isempty(opStart)
            % no operator, just lone value
            mappings(n).left = unwrapString(nextLine);
            mappings(n).operator = '';
            mappings(n).right = unwrapString('');
            
        else
            % left-hand value, operator, right-hand value
            mappings(n).left = unwrapString(nextLine(1:(opStart-1)));
            mappings(n).operator = nextLine((opStart+1):(opEnd-1));
            mappings(n).right = unwrapString(nextLine((opEnd+1):end));
        end
        
        continue;
    end
end

%% Done with file
fclose(fid);


%% Dig a string out of enclosing braces, if any.
function info = unwrapString(string)
% fill in default info
info.enclosing = '';
info.text = string;
info.value = '';

if isempty(string)
    return;
end

% check for enclosing brackets
if ~isempty(strfind(string, '<'))
    % angle brackets
    info.enclosing = '<>';
    valuePattern = '<(.+)>';
    
elseif ~isempty(strfind(string, '['))
    % square brackets
    info.enclosing = '[]';
    valuePattern = '\[(.+)\]';
    
else
    % plain string, strip some whitespace
    info.enclosing = '';
    valuePattern = '(\S.*\S)|(\S?)';
end

% dig out the value
valueToken = regexp(string, valuePattern, 'tokens');
info.value = valueToken{1}{1};
