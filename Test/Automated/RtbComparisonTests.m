classdef RtbComparisonTests < matlab.unittest.TestCase
    % Test functions that find and compare renderings.
    
    properties
        folderA = fullfile(rtbRoot(), 'Test', 'Automated', 'Fixture', 'Comparison', 'RecipesA');
        folderB = fullfile(rtbRoot(), 'Test', 'Automated', 'Fixture', 'Comparison', 'RecipesB');
        scratchFolder = fullfile(tempdir(), 'RtbComparisonTests');
    end
    
    methods (TestMethodSetup)
        function cleanUpOutput(testCase)
            if 7 == exist(testCase.scratchFolder, 'dir')
                rmdir(testCase.scratchFolder, 's');
            end
        end
    end
    
    
    methods (Test)
        
        function testFindRenderingsSuccess(testCase)
            expectedNames = {'rtbMakeCoordinatesTest', ...
                'rtbMakeMaterialSphereBumps', ...
                'rtbMakeMaterialSphereRemodeled'};
            
            renderingsA = rtbFindRenderings(testCase.folderA);
            recipeNamesA = unique({renderingsA.recipeName});
            testCase.assertEqual(recipeNamesA, expectedNames);
            testCase.assertNumElements(renderingsA, 14);
            
            renderingsB = rtbFindRenderings(testCase.folderB);
            recipeNamesB = unique({renderingsB.recipeName});
            testCase.assertEqual(recipeNamesB, expectedNames);
            testCase.assertNumElements(renderingsA, 14);
        end
        
        function testFindRenderingsSubset(testCase)
            renderings = rtbFindRenderings(testCase.folderA, ...
                'filter', 'CoordinatesTest[^\.]+\.mat$');
            testCase.assertNumElements(renderings, 2);
            recipeNames = {renderings.recipeName};
            testCase.assertEqual(strcmp(recipeNames, 'rtbMakeCoordinatesTest'), true(1,2));
        end
        
        function testFindRenderingsNone(testCase)
            renderings = rtbFindRenderings(testCase.folderA, ...
                'filter', 'notagoodpattern');
            testCase.assertEmpty(renderings);
        end
        
        function fetchReferenceSuccess(testCase)
            renderings = rtbFetchReferenceData('rtbMakeInterreflection', ...
                'referenceRoot', testCase.scratchFolder);
            testCase.assertNumElements(renderings, 6);
            recipeNames = {renderings.recipeName};
            testCase.assertEqual(strcmp(recipeNames, 'rtbMakeInterreflection'), true(1,6));
        end
        
        function fetchReferenceNone(testCase)
            renderings = rtbFetchReferenceData('nosuchrecipe', ...
                'referenceRoot', testCase.scratchFolder);
            testCase.assertNumElements(renderings, 0);
        end
        
        function compareRenderingToSelf(testCase)
            renderings = rtbFindRenderings(testCase.folderA);
            comparison = rtbCompareRenderings(renderings(1), renderings(1));
            testCase.assertEqual(comparison.corrcoef, 1, 'AbsTol', 1e-6);
            testCase.assertEqual(comparison.relNormDiff.max, 0,'AbsTol', 1e-6);
        end
        
        function compareRenderingToOther(testCase)
            renderings = rtbFindRenderings(testCase.folderA);
            comparison = rtbCompareRenderings(renderings(1), renderings(2));
            testCase.assertLessThan(comparison.corrcoef, 1);
            testCase.assertGreaterThan(comparison.relNormDiff.max, 0);
        end
        
        function compareRenderingPlot(testCase)
            renderings = rtbFindRenderings(testCase.folderA);
            comparison = rtbCompareRenderings(renderings(1), renderings(1));
            fig = rtbPlotRenderingComparison(comparison);
            close(fig);
        end
        
        function compareFolderToSelf(testCase)
            comparisons = rtbCompareManyRecipes(testCase.folderA, testCase.folderA, ...
                'fetchReferenceData', false);
            testCase.assertNumElements(comparisons, 14);
            testCase.assertEqual([comparisons.corrcoef], ones(1, 14), 'AbsTol', 1e-6);
            relNormDiff = [comparisons.relNormDiff];
            testCase.assertEqual([relNormDiff.max], zeros(1, 14) ,'AbsTol', 1e-6);
        end
        
        function compareFolderToOther(testCase)
            comparisons = rtbCompareManyRecipes(testCase.folderA, testCase.folderB, ...
                'fetchReferenceData', false);
            testCase.assertNumElements(comparisons, 14);
            % real correlations can be unity, skip correlation test
            relNormDiff = [comparisons.relNormDiff];
            testCase.assertGreaterThan([relNormDiff.max], 0);
        end
        
        function compareFolderToReference(testCase)
            comparisons = rtbCompareManyRecipes(testCase.folderA, testCase.scratchFolder, ...
                'fetchReferenceData', true);
            testCase.assertNumElements(comparisons, 14);
            % real correlations can be unity, skip correlation test
            relNormDiff = [comparisons.relNormDiff];
            testCase.assertGreaterThan([relNormDiff.max], 0);
        end
        
        function compareFolderPlot(testCase)
            comparisons = rtbCompareManyRecipes(testCase.folderA, testCase.folderA, ...
                'fetchReferenceData', false);
            fig = rtbPlotManyRecipeComparisons(comparisons);
            close(fig);
        end
        
        function epicComparisonPlots(testCase)
            [comparisons, ~, figs] = rtbRunEpicComparison(testCase.folderA, testCase.folderA, ...
                'plotSummary', true, ...
                'plotImages', true);
            testCase.assertNumElements(comparisons, 14);
            testCase.assertNumElements(figs, 14 + 1);
            close(figs);
        end
        
        function epicComparisonNoPlots(testCase)
            [comparisons, ~, figs] = rtbRunEpicComparison(testCase.folderA, testCase.folderA, ...
                'plotSummary', false, ...
                'plotImages', false);
            testCase.assertNumElements(comparisons, 14);
            testCase.assertEmpty(figs);
        end
        
        function epicComparisonClosePlots(testCase)
            [comparisons, ~, figs] = rtbRunEpicComparison(testCase.folderA, testCase.folderA, ...
                'plotSummary', true, ...
                'plotImages', true, ...
                'closeSummary', true, ...
                'closeImages', true);
            testCase.assertNumElements(comparisons, 14);
            testCase.assertEmpty(figs);
        end
        
        function epicComparisonSavePlots(testCase)
            [comparisons, ~, figs] = rtbRunEpicComparison(testCase.folderA, testCase.folderA, ...
                'plotSummary', true, ...
                'plotImages', true, ...
                'closeSummary', true, ...
                'closeImages', true, ...
                'figureFolder', testCase.scratchFolder, ...
                'summaryName', 'test-summary');
            testCase.assertNumElements(comparisons, 14);
            testCase.assertEmpty(figs);
            
            % summary should have been saved in scratch folder
            summaryFig = fullfile(testCase.scratchFolder, 'test-summary.fig');
            summaryPng = fullfile(testCase.scratchFolder, 'test-summary.png');
            testCase.assertEqual(exist(summaryFig, 'file'), 2);
            testCase.assertEqual(exist(summaryPng, 'file'), 2);
            
            % images should have been saved in the scratchFolder
            for cc = 1:numel(comparisons)
                identifier = comparisons(cc).renderingA.identifier;
                imageFig = fullfile(testCase.scratchFolder, [identifier '.fig']);
                imagePng = fullfile(testCase.scratchFolder, [identifier '.png']);
                testCase.assertEqual(exist(imageFig, 'file'), 2);
                testCase.assertEqual(exist(imagePng, 'file'), 2);
            end
        end
    end
end
