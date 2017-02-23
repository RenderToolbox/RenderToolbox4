classdef RtbExampleTests < matlab.unittest.TestCase
    % Execute some of the render toolbox examples.
    
    properties
        outputRoot = fullfile(rtbWorkingFolder(), 'RtbExampleTests');
        referenceRoot = fullfile(rtbWorkingFolder(), 'RtbReference');
    end
    
    methods (TestMethodSetup)
        function cleanUpOutput(testCase)
            if 7 == exist(testCase.outputRoot, 'dir')
                rmdir(testCase.outputRoot, 's');
            end
            
            if 7 == exist(testCase.referenceRoot, 'dir')
                rmdir(testCase.referenceRoot, 's');
            end
        end
    end
    
    methods (Test)
        
        function testNotAnExample(testCase)
            results = rtbRunEpicExamples( ...
                'outputRoot', testCase.outputRoot, ...
                'makeFunctions', {'notAnExample.m'});
            testCase.assertFalse(results.isSuccess);
            testCase.assertNotEmpty(results.error);
        end
        
        function testCoordinatesTest(testCase)
            results = rtbRunEpicExamples( ...
                'outputRoot', testCase.outputRoot, ...
                'makeFunctions', {'rtbMakeCoordinatesTest.m'});
            testCase.assertTrue(results.isSuccess);
            testCase.assertEmpty(results.error);
            
            % compare to reference rendering
            comparisons = rtbCompareManyRecipes( ...
                testCase.outputRoot, ...
                testCase.referenceRoot, ...
                'fetchReferenceData', true);
            testCase.assertTrue(all([comparisons.isGoodComparison]));
            
            % Skip check for correlation and pixel differences.
            % Because this scene doesn't specify its own materials, it is
            % sensitive to the default material import behaviors of Assimp,
            % mexximp, mMitsuba, and mPbrt.  So correlations and pixel
            % differences may be large, even though the coordinate systems
            % check out fine (which is the point of this example).
        end
        
        function testDragon(testCase)
            results = rtbRunEpicExamples( ...
                'outputRoot', testCase.outputRoot, ...
                'makeFunctions', {'rtbMakeDragon.m'});
            testCase.assertTrue(results.isSuccess);
            testCase.assertEmpty(results.error);
            
            % compare to reference rendering
            comparisons = rtbCompareManyRecipes( ...
                testCase.outputRoot, ...
                testCase.referenceRoot, ...
                'fetchReferenceData', true);
            testCase.assertTrue(all([comparisons.isGoodComparison]));
            testCase.assertTrue(all([comparisons.corrcoef] > 0.75));
            relNormDiffs = [comparisons.relNormDiff];
            testCase.assertTrue(all([relNormDiffs.max] < 2.5));
            testCase.assertTrue(all([relNormDiffs.mean] < 2.5));
        end
        
        function testMaterialSphereBumps(testCase)
            results = rtbRunEpicExamples( ...
                'outputRoot', testCase.outputRoot, ...
                'makeFunctions', {'rtbMakeMaterialSphereBumps.m'});
            testCase.assertTrue(results.isSuccess);
            testCase.assertEmpty(results.error);
            
            % compare to reference rendering
            comparisons = rtbCompareManyRecipes( ...
                testCase.outputRoot, ...
                testCase.referenceRoot, ...
                'fetchReferenceData', true);
            testCase.assertTrue(all([comparisons.isGoodComparison]));
            testCase.assertTrue(all([comparisons.corrcoef] > 0.75));
            relNormDiffs = [comparisons.relNormDiff];
            testCase.assertTrue(all([relNormDiffs.max] < 2.5));
            testCase.assertTrue(all([relNormDiffs.mean] < 2.5));
        end
        
        function testMaterialSphereRemodeled(testCase)
            results = rtbRunEpicExamples( ...
                'outputRoot', testCase.outputRoot, ...
                'makeFunctions', {'rtbMakeMaterialSphereRemodeled.m'});
            testCase.assertTrue(results.isSuccess);
            testCase.assertEmpty(results.error);
            
            % compare to reference rendering
            comparisons = rtbCompareManyRecipes( ...
                testCase.outputRoot, ...
                testCase.referenceRoot, ...
                'fetchReferenceData', true);
            testCase.assertTrue(all([comparisons.isGoodComparison]));
            testCase.assertTrue(all([comparisons.corrcoef] > 0.75));
            relNormDiffs = [comparisons.relNormDiff];
            testCase.assertTrue(all([relNormDiffs.max] < 2.5));
            testCase.assertTrue(all([relNormDiffs.mean] < 2.5));
        end
    end
end
