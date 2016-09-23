%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Check the winding order of vertices in 3D space.
%   @param vertices m x 3 matrix of XYZ triples
%
% @details
% Returns true if the given @a vertices are wound in clockwise order.  For
% porposes of this function, "clockwise" is defined arbitrarily and it's
% only meaningful to compare sets of @a vertices for @em differences in
% winding order.
%
% @details
% @a vertices should contain at least 3 XYZ triples.  Only the first 3 will
% be checked for winding order.  Subtracts the first vertex from each of
% the next two vertices, and takes the cross product of the differences.
% If the product has a non-negative z-component, @a vertices are
% "clockwise".  Otherwise they're "counter-clockwise".
%
% @details
% Returns true if @a vertices are wound in clockwise order.
%
% @details
% Usage:
%   isClockwise = IsVerticesClockwise(vertices)
%
% @ingroup Utilities
function isClockwise = IsVerticesClockwise(vertices)

nVertices = size(vertices, 1);
if nVertices < 3
    error('vertices matrix must have 3 or more rows, but has %d.', ...
        nVertices);
end

nComponents = size(vertices, 2);
if nComponents < 3
    error('vertices matrix must have 3 or more columns, but has %d.', ...
        nComponents);
end

% is this triangle wound clockwise or counterclockwise ?
A = vertices(1,:);
B = vertices(2,:);
C = vertices(3,:);
signedArea = cross((B-A), (C-A));
isClockwise = signedArea(3) >= 0;
