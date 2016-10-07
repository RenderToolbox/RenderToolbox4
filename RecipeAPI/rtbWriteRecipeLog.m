function rtbWriteRecipeLog(recipe, fileName)
%% Write a recipe's log as formatted text to a text file.
%
% rtbWriteRecipeLog(recipe, fileName) writes verbose log data from the
% given recipe to a text file at the fileName.
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('recipe', @isstruct);
parser.addParameter('fileName', @ischar);
parser.parse(recipe, fileName);
recipe = parser.Results.recipe;
fileName = parser.Results.fileName;


%% Get the verbose log summary.
summary = rtbPrintRecipeLog(recipe, 'verbose', true);

%% Write it out to disk.
fid = fopen(fileName, 'w');
err = [];
try
    fwrite(fid, summary);
    fclose(fid);
catch err
    % replaces placeholder, rethrow below
end

if any(fid == fopen('all'))
    fclose(fid);
end

if ~isempty(err)
    rethrow(err)
end

