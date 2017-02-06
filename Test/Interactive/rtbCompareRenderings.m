function comparison = rtbCompareRenderings(renderingA, renderingB, varargin)
%% Compare two renderings for difference images and statistics.
%
% comparison = rtbCompareRenderings(renderingA, renderingB) compares the
% given renderingA against the given renderingB.  Each must be a rendering
% record as returned from rtbRenderingRecord() or rtbFindRenderings().
% Returns a comparison struct with many various fields including:
%   - A -- the multispectral image from renderingA
%   - B -- the multispectral image from renderingB
%   - aMinusB -- the multispectral difference image A - B
%   - bMinusA -- the multispectral difference image B - A
%   - relNormDiff -- the min, mean, and max of per-pixel difference
%   - corrcoef -- the overall correlation between A and B
%   - error -- any error encountered during comparisons
%
% The relNormDiff is obtained by normalizing A and B each by its max value,
% taking the absolute difference, and dividing the difference by the
% normalized values of A.  Finally, values of relNormDiff that are less
% than the given denominatorThreshold are set to nan.  This is to avoid
% unfair comparisons when dividing by small values.
%
% rtbCompareRenderings( ... 'denominatorThreshold', denominatorThreshold)
% specify the denominatorThreshold to use when computing the relNormDiff
% image described above.  The default is 0.2.
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('renderingA', @isstruct);
parser.addRequired('renderingB', @isstruct);
parser.addParameter('denominatorThreshold', 0.2, @isnumeric);
parser.parse(renderingA, renderingB, varargin{:});
renderingA = parser.Results.renderingA;
renderingB = parser.Results.renderingB;
denominatorThreshold = parser.Results.denominatorThreshold;

comparison = parser.Results;
comparison.error = '';


%% Load multispectral images.
dataA = load(renderingA.fileName);
dataB = load(renderingB.fileName);

% do we have images?
hasImageA = isfield(dataA, 'multispectralImage');
hasImageB = isfield(dataB, 'multispectralImage');
if hasImageA
    if hasImageB
        % each has an image -- proceed
    else
        comparison.error = ...
            'Data file A has a multispectralImage but B does not.';
        disp(comparison.error);
        return;
    end
else
    if hasImageB
        comparison.error = ...
            'Data file B has a multispectralImage but A does not.';
        disp(comparison.error);
        return;
    else
        comparison.error = ...
            'Neither data file A nor B has a multispectralImage.';
        return;
    end
end
multispectralA = dataA.multispectralImage;
multispectralB = dataB.multispectralImage;


%% Sanity check image dimensions.
if ~isequal(size(multispectralA, 1), size(multispectralB, 1)) ...
        || ~isequal(size(multispectralA, 2), size(multispectralB, 2))
    
    comparison.error = ...
        sprintf('Image A[%s] is not the same size as image B[%s].', ...
        num2str(size(multispectralA)), num2str(size(multispectralB)));
    disp(comparison.error);
    return;
end


%% Sanity check spectral sampling.
hasSamplingA = isfield(dataA, 'S');
hasSamplingB = isfield(dataB, 'S');
if hasSamplingA
    if hasSamplingB
        % each has a sampling "S" -- proceed
    else
        comparison.error = ...
            'Data file A has a spectral sampling "S" but B does not.';
        disp(comparison.error);
        return;
    end
else
    if hasSamplingB
        comparison.error = ...
            'Data file B has a spectral sampling "S" but A does not.';
        disp(comparison.error);
        return;
    else
        comparison.error = ...
            'Neither data file A nor B has spectral sampling "S".';
        return;
    end
end
comparison.samplingA = dataA.S;
comparison.samplingB = dataB.S;

% do spectral samplings agree?
if ~isequal(dataA.S, dataB.S)
    comparison.error = ...
        sprintf('Spectral sampling A[%s] is not the same as B[%s].', ...
        num2str(dataA.S), num2str(dataB.S));
    disp(comparison.error);
    % proceed with comparison, despite sampling mismatch
end

% match images based on sampling depths
[multispectralA, multispectralB] = truncatePlanes( ...
    multispectralA, multispectralB, dataA.S, dataB.S);


%% Sanity Checks OK.
comparison.isGoodComparison = true;


%% Per-pixel difference stats.
normA = multispectralA / max(multispectralA(:));
normB = multispectralB / max(multispectralB(:));
normDiff = normA - normB;
absNormDiff = abs(normDiff);
relNormDiff = absNormDiff ./ normA;
relNormDiff(normA < denominatorThreshold) = nan;

% summarize differnece stats
comparison.subpixelsA = summarizeData(multispectralA);
comparison.subpixelsB = summarizeData(multispectralB);
comparison.normA = summarizeData(normA);
comparison.normB = summarizeData(normB);
comparison.normDiff = summarizeData(normDiff);
comparison.absNormDiff = summarizeData(absNormDiff);
comparison.relNormDiff = summarizeData(relNormDiff);


%% Overall correlation.
r = corrcoef(multispectralA(:), multispectralB(:));
comparison.corrcoef = r(1, 2);


%% Difference images.
comparison.A = multispectralA;
comparison.B = multispectralB;
comparison.aMinusB = multispectralA - multispectralB;
comparison.bMinusA = multispectralB - multispectralA;


%% Truncate spectral planes if one image has more planes.
function [truncA, truncB, truncSampling] = truncatePlanes(A, B, samplingA, samplingB)
nPlanes = min(samplingA(3), samplingB(3));
truncSampling = [samplingA(1:2) nPlanes];
truncA = A(:,:,1:nPlanes);
truncB = B(:,:,1:nPlanes);


%% Summarize a distribuition of data with a struct of stats.
function summary = summarizeData(data)
finiteData = data(isfinite(data));
summary.min = min(finiteData);
summary.mean = mean(finiteData);
summary.max = max(finiteData);
