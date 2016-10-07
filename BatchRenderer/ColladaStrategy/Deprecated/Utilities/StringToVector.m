%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.
%
% Convert a string representation of numbers to a 1D matrix.
%   @param string a string with numeric representations
%
% @details
% Scans the given @a string for integer or decimal numeric representations,
% and converts them to numeric form.
%
% @details
% Returns a 1-dimensional double matrix containing the numbers represented
% in @string.  If @a string is not a string, returns the @a string as it
% is.
%
% @details
% Usage:
%   vector = StringToVector(string)
%
% @ingroup Utilities
function vector = StringToVector(string)

if ischar(string)
    vector = sscanf(string, '%f');
    
else
    vector = string;
end
