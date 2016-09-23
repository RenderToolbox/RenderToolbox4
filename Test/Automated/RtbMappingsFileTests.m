classdef RtbMappingsFileTests < matlab.unittest.TestCase
    
    methods (Test)
        
        function testRead(testCase)
            mappingsFile = fullfile(rtbRoot(), 'Test', 'Automated', 'Fixture', 'DragonColorCheckerMappings.json');
            mappings = rtbLoadJsonMappings(mappingsFile);
            testCase.assertInstanceOf(mappings, 'struct');
            testCase.assertNumElements(mappings, 6);
        end        
    end
end
