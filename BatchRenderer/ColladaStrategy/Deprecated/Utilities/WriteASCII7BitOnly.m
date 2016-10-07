%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Remove characters from the given text file that are not 7-bit ASCII.
%   @param fileName file name of path of an existing text file
%   @param newFileName file name of path for a new text file
%
% @details
% Reads the text file at the given @a fileName, and writes a new file at
% the given @a newFileName that contains only 7-bit ASCII characters.
% These characters include the usual alphanumerics and some punctuation.
% Try:
% @code
%   ASCII7Bit = char(0:127)
% @endcode
%
% @details
% Returns the name of the new file.
%
% @details
% Usage:
%   newFileName = WriteASCII7BitOnly(fileName, newFileName)
%
% @ingroup Utilities
function newFileName = WriteASCII7BitOnly(fileName, newFileName)

[filePath, fileBase, fileExt] = fileparts(fileName);

if nargin < 2
    newFileName = fullfile(filePath, [fileBase '-7bit' fileExt]);
end

% read the whole input file
fid = fopen(fileName, 'r');
bytes = fread(fid);
fclose(fid);

% filter out big characters
ASCII7BitBytes = bytes(bytes <= 127);

% write the new file
fid = fopen(newFileName, 'w');
fwrite(fid, ASCII7BitBytes);
fclose(fid);