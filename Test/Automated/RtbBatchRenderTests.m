classdef RtbBatchRenderTests < matlab.unittest.TestCase
    
    methods (Test)
        
        function testRenderNoScenes(testCase)
            scenes = {};
            hints.workingFolder = fullfile(tempdir(), 'RtbBatchRenderTests');
            outputFiles = rtbBatchRender(scenes, 'hints', hints);
            testCase.assertEmpty(outputFiles);
        end
        
        function testRenderSampleRenderer(testCase)
            hints.workingFolder = fullfile(tempdir(), 'RtbBatchRenderTests');
            hints.renderer = 'SampleRenderer';
            hints = rtbDefaultHints(hints);
            
            sceneFile = fullfile(rtbRoot(), 'Test', 'Automated', 'Fixture', 'CoordinatesTest.dae');
            hints.workingFolder = fullfile(tempdir(), 'RtbMakeSceneFilesTests');
            scenes = rtbMakeSceneFiles(sceneFile, 'hints', hints);
            outputFiles = rtbBatchRender(scenes, 'hints', hints);
            testCase.assertNumElements(outputFiles, numel(scenes));
        end
        
    end
end
