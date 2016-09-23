classdef RtbParsePsychColorimetricMatFileTests < matlab.unittest.TestCase
    
    methods (Test)
        
        function testCones(testCase)
            matFile = 'T_cones_ss10';
            [data, S, category, name] = rtbParsePsychColorimetricMatFile(matFile);
            
            testCase.assertSize(data, [3, 441]);
            testCase.assertEqual(S, [390, 1, 441]);
            testCase.assertEqual(category, 'T');
            testCase.assertEqual(name, 'cones_ss10');
        end
        
        function testRods(testCase)
            matFile = 'T_rods';
            [data, S, category, name] = rtbParsePsychColorimetricMatFile(matFile);
            testCase.assertSize(data, [1, 81]);
            testCase.assertEqual(S, [380 5 81]);
            testCase.assertEqual(category, 'T');
            testCase.assertEqual(name, 'rods');
        end
    end
end
