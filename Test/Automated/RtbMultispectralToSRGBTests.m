classdef RtbMultispectralToSRGBTests < matlab.unittest.TestCase
    
    methods (Test)
        
        function testScaling(testCase)
            multispectralDataFile = fullfile(rtbRoot(), 'Test', 'Automated', 'Fixture', 'CoordinatesTest.mat');
            data = load(multispectralDataFile);
            sRgbImage = rtbMultispectralToSRGB(data.multispectralImage, data.S, ...
                'toneMapFactor', 100, ...
                'isScale', true);
            
            height = size(data.multispectralImage, 1);
            width = size(data.multispectralImage, 2);
            testCase.assertSize(sRgbImage, [height, width, 3]);
            testCase.assertEqual(min(sRgbImage(:)), 0);
            testCase.assertEqual(max(sRgbImage(:)), 255)
        end
        
    end
end
