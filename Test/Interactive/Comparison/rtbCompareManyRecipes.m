function [comparisons, matchInfo] = rtbCompareManyRecipes(folderA, folderB, varargin)
%% Compare paris of renderings across two folders.
%
% comparisons = rtbCompareManyRecipes(folderA, folderB) finds rendering
% data files in the given folderA and folderB and attempts to match up
% pairs of renderings that came from the same recipe and renderer.
% For each pair, computes difference images and statistics.
%
% Returns a struct array of image comparisons, as returned from
% rtbCompareRenderings().
%
% rtbCompareManyRecipes( ... 'fetchReferenceData', fetchReferenceData)
% specify whether to use Remote Data Toolbox to fetch reference data for
% comparison.  The default is true, fetch reference data when there is a
% recipe in folderA that was not found in folderB, and cache the fetched
% data in folderB.
%
%%% RenderToolbox4 Copyright (c) 2012-2017 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.KeepUnmatched = true;
parser.addRequired('folderA', @ischar);
parser.addRequired('folderB', @ischar);
parser.addParameter('fetchReferenceData', true, @islogical);
parser.parse(folderA, folderB, varargin{:});
folderA = parser.Results.folderA;
folderB = parser.Results.folderB;
fetchReferenceData = parser.Results.fetchReferenceData;


%% Identify renderings and recipes to compare.
renderingsA = rtbFindRenderings(folderA, varargin{:});
recipeNames = unique({renderingsA.recipeName});
nRecipes = numel(recipeNames);

renderingsB = rtbFindRenderings(folderB, varargin{:});

%% Compare one recipe at a time, fetch data as necessary.
comparisonsCell = cell(1, nRecipes);
matchInfoCell = cell(1, nRecipes);
for rr = 1:nRecipes
    recipeName = recipeNames{rr};
    fprintf('Comparing renderings for recipe <%s>.\n', recipeName);
    
    isRecipeA = strcmp({renderingsA.recipeName}, recipeName);
    recipeRenderingsA = renderingsA(isRecipeA);
    
    % fetch missing recipe for B?
    if isempty(renderingsB)
        isRecipeB = false;
    else
        isRecipeB = strcmp({renderingsB.recipeName}, recipeName);
    end
    
    if any(isRecipeB)
        recipeRenderingsB = renderingsB(isRecipeB);
    elseif fetchReferenceData
        fprintf('  Fetching reference data to <%s>...\n', folderB);
        recipeRenderingsB = rtbFetchReferenceData(recipeName, ...
            'referenceRoot', folderB, ...
            varargin{:});
        if isempty(recipeRenderingsB)
            fprintf('  ...could not fetch, skipping this recipe.\n');
            continue;
        else
            fprintf('  ...OK.\n');
        end
    else
        fprintf('  Skipping recipe not found in <%s>.\n', folderB);
        continue;
    end
    
    % match pairs of renderings for recipes A and B
    info = matchRenderingPairs(recipeRenderingsA, recipeRenderingsB);
    fprintf('  Found %d matched pairs of renderings.\n', info.nPairs);
    
    % run a comparison for each matched pair
    pairsCell = cell(1, info.nPairs);
    for pp = 1:info.nPairs
        fprintf('    %s.\n', info.matchedA(pp).identifier);
        pairsCell{pp} = rtbCompareRenderings(info.matchedA(pp), info.matchedB(pp), varargin{:});
    end
    comparisonsCell{rr} = [pairsCell{:}];
    matchInfoCell{rr} = info;
    
    % report on unmatched renderings
    if ~isempty(info.unmatchedA)
        nUnmatched = info.unmatchedA;
        fprintf('  %d renderings in A were not matched in B:\n', nUnmatched);
        for uu = 1:nUnmatched
            fprintf('    %s\n', info.info.unmatchedA(uu).identifier);
        end
    end
    
    if ~isempty(info.unmatchedB)
        nUnmatched = info.unmatchedB;
        fprintf('  %d renderings in B were not matched in A:\n', nUnmatched);
        for uu = 1:nUnmatched
            fprintf('    %s\n', info.info.unmatchedB(uu).identifier);
        end
    end
end
comparisons = [comparisonsCell{:}];
matchInfo = [matchInfoCell{:}];


%% For pairs of comparable renderings from two sets.
function info = matchRenderingPairs(renderingsA, renderingsB)
identifiersA = {renderingsA.identifier};
identifiersB = {renderingsB.identifier};
[~, indexA, indexB] = intersect(identifiersA, identifiersB, 'stable');
[~, unmatchedIndexA] = setdiff(identifiersA, identifiersB);
[~, unmatchedIndexB] = setdiff(identifiersB, identifiersA);

info.nPairs = numel(indexA);
info.matchedA = renderingsA(indexA);
info.matchedB = renderingsB(indexB);
info.unmatchedA = renderingsA(unmatchedIndexA);
info.unmatchedB = renderingsB(unmatchedIndexB);
