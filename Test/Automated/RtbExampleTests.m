classdef RtbExampleTests < matlab.unittest.TestCase
    % Execute some of the render toolbox examples.
    
    properties
        outputRoot = fullfile(rtbWorkingFolder(), 'RtbExampleTests');
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
            results = rtbRunEpicTest( ...
                'outputRoot', testCase.outputRoot, ...
                'makeFunctions', {'notAnExample.m'});
            testCase.assertFalse(results.isSuccess);
            testCase.assertNotEmpty(results.error);
        end
        
        function testCoordinatesTest(testCase)
            results = rtbRunEpicTest( ...
                'outputRoot', testCase.outputRoot, ...
                'makeFunctions', {'rtbMakeCoordinatesTest.m'});
            testCase.assertTrue(results.isSuccess);
            testCase.assertEmpty(results.error);
        end
        
        function testDragon(testCase)
            results = rtbRunEpicTest( ...
                'outputRoot', testCase.outputRoot, ...
                'makeFunctions', {'rtbMakeDragon.m'});
            testCase.assertTrue(results.isSuccess);
            testCase.assertEmpty(results.error);
        end
        
        function testMaterialSphereBumps(testCase)
            results = rtbRunEpicTest( ...
                'outputRoot', testCase.outputRoot, ...
                'makeFunctions', {'rtbMakeMaterialSphereBumps.m'});
            testCase.assertTrue(results.isSuccess);
            testCase.assertEmpty(results.error);
        end
        
        function testMaterialSphereRemodeled(testCase)
            results = rtbRunEpicTest( ...
                'outputRoot', testCase.outputRoot, ...
                'makeFunctions', {'rtbMakeMaterialSphereRemodeled.m'});
            testCase.assertTrue(results.isSuccess);
            testCase.assertEmpty(results.error);
        end
    end
end
