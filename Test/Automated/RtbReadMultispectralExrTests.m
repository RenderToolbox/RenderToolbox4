classdef RtbReadMultispectralExrTests < matlab.unittest.TestCase
    
    methods (Test)
        
        function testReadExrBadFileNoCrash(testCase)
            try
                [channelInfo, imageData] = rtbReadMultichannelEXR('no-good.exr');
            catch
                channelInfo = [];
                imageData = [];
            end
            testCase.assertEmpty(channelInfo);
            testCase.assertEmpty(imageData);
        end
        
        function testReadExr(testCase)
            exrFile = fullfile(rtbRoot(), 'Test', 'Automated', 'Fixture', 'CoordinatesTest.exr');
            [channelInfo, imageData] = rtbReadMultichannelEXR(exrFile);
            
            testCase.assertInstanceOf(channelInfo, 'struct');
            testCase.assertNumElements(channelInfo, 31);
            testCase.assertTrue(max(imageData(:)) > 0);
            testCase.assertSize(imageData, [240 320 31]);
        end
        
    end
end
