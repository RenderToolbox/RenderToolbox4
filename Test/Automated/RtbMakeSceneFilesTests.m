classdef RtbMakeSceneFilesTests < matlab.unittest.TestCase
    
    methods (Test)
        
        function testMakeNoSceneFiles(testCase)
            sceneFile = '';
            hints.workingFolder = fullfile(tempdir(), 'RtbMakeSceneFilesTests');
            scenes = rtbMakeSceneFiles(sceneFile, 'hints', hints);
            testCase.assertNumElements(scenes, 1);
            testCase.assertEmpty(scenes{1});
        end
        
        function testMakeSceneFilesSampleRemodelerSampleRenderer(testCase)
            hints.workingFolder = fullfile(tempdir(), 'RtbBatchRenderTests');
            hints.renderer = 'SampleRenderer';
            hints.remodeler = 'SampleRemodeler';
            hints = rtbDefaultHints(hints);
            
            scene = fullfile(rtbRoot(), 'Test', 'Automated', 'Fixture', 'CoordinatesTest.dae');
            hints.workingFolder = fullfile(tempdir(), 'RtbMakeSceneFilesTests');
            scenes = rtbMakeSceneFiles(scene, 'hints', hints);
            testCase.assertNumElements(scenes, 1);
        end
        
    end
end
