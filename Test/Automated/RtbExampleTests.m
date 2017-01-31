classdef RtbExampleTests < matlab.unittest.TestCase
    % Execute some of the render toolbox examples.
    
    properties
        outputRoot = fullfile(tempdir(), 'RtbExampleTests');
    end
    
    methods (TestMethodSetup)
        function cleanUpOutput(testCase)
            if 7 == exist(testCase.outputRoot, 'dir')
                rmdir(testCase.outputRoot, 's');
            end
        end
    end
    
    methods (Test)
        
        function testNotAnExample(testCase)
            results = rtbTestAllExampleScenes( ...
                'outputRoot', testCase.outputRoot, ...
                'makeFunctions', {'notAnExample.m'});
            testCase.assertFalse(results.isSuccess);
            testCase.assertNotEmpty(results.error);
        end
        
        function testCoordinatesTest(testCase)
            results = rtbTestAllExampleScenes( ...
                'outputRoot', testCase.outputRoot, ...
                'makeFunctions', {'rtbMakeCoordinatesTest.m'});
            testCase.assertTrue(results.isSuccess);
            testCase.assertEmpty(results.error);
        end
        
        function testDragon(testCase)
            results = rtbTestAllExampleScenes( ...
                'outputRoot', testCase.outputRoot, ...
                'makeFunctions', {'rtbMakeDragon.m'});
            testCase.assertTrue(results.isSuccess);
            testCase.assertEmpty(results.error);
        end
        
        function testMaterialSphereBumps(testCase)
            results = rtbTestAllExampleScenes( ...
                'outputRoot', testCase.outputRoot, ...
                'makeFunctions', {'rtbMakeMaterialSphereBumps.m'});
            testCase.assertTrue(results.isSuccess);
            testCase.assertEmpty(results.error);
        end
        
        function testMaterialSphereRemodeled(testCase)
            results = rtbTestAllExampleScenes( ...
                'outputRoot', testCase.outputRoot, ...
                'makeFunctions', {'rtbMakeMaterialSphereRemodeled.m'});
            testCase.assertTrue(results.isSuccess);
            testCase.assertEmpty(results.error);
        end
    end
end
