classdef RtbSpdPowerTests < matlab.unittest.TestCase
    
    methods (Test)
        
        function testNmToBandsAndBack(testCase)
            powerPerBand = 10:10:1000;
            S = [400 10 100];
            
            powerPerNm = rtbSpdPowerPerWlBandToPowerPerNm(powerPerBand, S);
            testCase.assertEqual(powerPerNm, 1:100);
            
            powerPerBandAgain = rtbSpdPowerPerNmToPowerPerWlBand(powerPerNm, S);
            testCase.assertEqual(powerPerBandAgain, powerPerBand);
        end
        
    end
end
