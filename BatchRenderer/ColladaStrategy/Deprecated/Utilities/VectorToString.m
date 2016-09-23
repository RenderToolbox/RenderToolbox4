%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Convert a 1D matrix of numbers to string representation.
%   @param vector numeric 1-dimensional matrix
%
% @details
% Prints the given @a vector to a string with space-separated decimal
% representations.  If all elements of the vector are integers, prints
% integer representations.  Treats @a vector as 1-dimensional.
%
% @details
% Returns a string that contains representations of all the elements of @a
% vector.  If @a vector is not numeric, returns the @a vector as it is.
%
% @details
% Usage:
%   string = VectorToString(vector)
%
% @ingroup Utilities
function string = VectorToString(vector)

if isnumeric(vector) && ~isempty(vector)
    if all(vector == round(vector))
        format = '%d ';
    else
        format = '%f ';
    end
    string = sprintf(format, vector);
    
    % remove the trailing space
    string = string(1:end-1);
    
else
    string = vector;
end
