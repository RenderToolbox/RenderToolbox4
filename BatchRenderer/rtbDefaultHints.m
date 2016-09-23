function hints = rtbDefaultHints(hints)
%% Get a struct of default options for batch rendering.
%
% hints = rtbDefaultHints() Creates a struct of options that affect the
% behavior of RenderToolbox4 utilities.
%
% hints = rtbDefaultHints(hints) updates the given struct of options to
% include all of the default fileds expected by RenderToolbox4 utilities.
%
% Default hint values can be set with Matlab's setpref() function.  For
% example:
%   % default image dimensions
%   setpref('RenderToolbox4', 'imageHeight', 480);
%   setpref('RenderToolbox4', 'imageWidth', 640);
%
%   % review all the hints
%   hints = rtbDefaultHints()
%
% Returns a new or modified struct of batch renderer hints.
%
% hints = rtbDefaultHints(hints)
%
%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

if nargin < 1 || ~isstruct(hints)
    hints = struct();
end

% supplement given hints with default hints
RenderToolbox4 = getpref('RenderToolbox4');
hintNames = fieldnames(RenderToolbox4);
for ii = 1:numel(hintNames)
    name = hintNames{ii};
    if ~rtbIsStructFieldPresent(hints, name)
        % hint is missing, fill in the default
        hints.(name) = getpref('RenderToolbox4', name);
    end
end
