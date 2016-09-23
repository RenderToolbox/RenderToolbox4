classdef RtbMakeSensorImagesTests < matlab.unittest.TestCase
    
    methods (Test)
        
        function testColorimetricMatFile(testCase)
            multispectralDataFile = fullfile(rtbRoot(), 'Test', 'Automated', 'Fixture', 'CoordinatesTest.mat');
            inFiles = {multispectralDataFile, multispectralDataFile};
            matchingFunctions = {'T_cones_ss10', 'T_rods'};
            hints.workingFolder = fullfile(tempdir(), 'RtbMakeSensorImagesTest');
            
            outputFiles = rtbMakeSensorImages(inFiles, matchingFunctions, ...
                'hints', hints);
            testCase.assertSize(outputFiles, [numel(inFiles), numel(matchingFunctions)]);
        end
        
        function testMatrix(testCase)
            multispectralDataFile = fullfile(rtbRoot(), 'Test', 'Automated', 'Fixture', 'CoordinatesTest.mat');
            inFiles = {multispectralDataFile, multispectralDataFile};
            matchingFunctions = {zeros(10, 10), ones(10, 10)};
            matchingS = {[400 10 10], [400 10 10]};
            names = {'zeros', 'identity'};
            hints.workingFolder = fullfile(tempdir(), 'RtbMakeSensorImagesTest');
            
            outputFiles = rtbMakeSensorImages(inFiles, matchingFunctions, ...
                'matchingS', matchingS, ...
                'names', names, ...
                'hints', hints);
            testCase.assertSize(outputFiles, [numel(inFiles), numel(matchingFunctions)]);
            
            zeroData = load(outputFiles{1});
            testCase.assertEqual(sum(zeroData.sensorImage(:)), 0);
            
            identityData = load(outputFiles{end});
            testCase.assertTrue(sum(identityData.sensorImage(:)) > 0);
        end
        
    end
end
