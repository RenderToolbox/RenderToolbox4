classdef RtbConditionsFileTests < matlab.unittest.TestCase
    
    methods (Test)
        
        function testRead(testCase)
            conditionsFile = fullfile(rtbRoot(), 'Test', 'Automated', 'Fixture', 'DragonColorCheckerConditions.txt');
            [names, values] = rtbParseConditions(conditionsFile);
            testCase.assertEqual(names, {'imageName', 'dragonColor'});
            testCase.assertSize(values, [24, 2]);
            testCase.assertEqual(values(1,:), {'macbethDragon-1', 'mccBabel-1.spd'});
            testCase.assertEqual(values(24,:), {'macbethDragon-24', 'mccBabel-24.spd'});
        end
        
        function testRoundTrip(testCase)
            conditionsFile = fullfile(tempdir(), 'RtbConditionsFileTests', 'testConditions.txt');
            names = {'a', 'b', 'c'};
            values = cell(10, numel(names));
            for vv = 1:numel(values)
                values{vv} = sprintf('%f', rand());
            end
            
            rtbWriteConditionsFile(conditionsFile, names, values);
            [namesAgain, valuesAgain] = rtbParseConditions(conditionsFile);
            
            testCase.assertEqual(namesAgain, names);
            testCase.assertEqual(valuesAgain, values);
        end
        
    end
end
