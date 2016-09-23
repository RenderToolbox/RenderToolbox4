classdef RtbMakeMontageTests < matlab.unittest.TestCase
    
    methods (Test)
        
        function testVerticalPanels(testCase)
            multispectralDataFile = fullfile(rtbRoot(), 'Test', 'Automated', 'Fixture', 'CoordinatesTest.mat');
            inFiles = {multispectralDataFile; ...
                multispectralDataFile; ...
                multispectralDataFile;};
            hints.workingFolder = fullfile(tempdir(), 'RtbMakeMontageTests');
            
            outFile = fullfile(tempdir(), 'RtbMakeMontageTests', 'test.png');
            sRgbImage = rtbMakeMontage(inFiles, ...
                'outFile', outFile, ...
                'hints', hints);
            testCase.assertSize(sRgbImage, [3 * 240, 320, 3]);
            
            pngData = imread(outFile);
            testCase.assertSize(pngData, [3 * 240, 320, 3]);
        end
    end
end
