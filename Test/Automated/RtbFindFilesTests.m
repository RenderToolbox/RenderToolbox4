classdef RtbFindFilesTests < matlab.unittest.TestCase
    
    methods (Test)
        
        function testFindThisFolder(testCase)
            thisFile = which('RtbFindFilesTests');
            pathHere = fileparts(thisFile);
            fileList = rtbFindFiles('root', pathHere, 'allowFolders', true);
            testCase.assertTrue(any(strcmp(fileList, pathHere)));
        end
        
        function testFindThisFile(testCase)
            thisFile = which('RtbFindFilesTests');
            pathHere = fileparts(thisFile);
            fileList = rtbFindFiles('root', pathHere);
            testCase.assertTrue(any(strcmp(fileList, thisFile)));
        end
        
        function testFindThisFileOnly(testCase)
            thisFile = which('RtbFindFilesTests');
            pathHere = fileparts(thisFile);
            fileList = rtbFindFiles('root', pathHere, ...
                'filter', thisFile, ...
                'exactMatch', true);
            testCase.assertNumElements(fileList, 1);
            testCase.assertEqual(fileList{1}, thisFile);
        end
        
        function testFindTestFiles(testCase)
            toolboxRoot = rtbRoot();
            fileList = rtbFindFiles('root', toolboxRoot, ...
                'filter', 'Tests.m$');
            testCase.assertNotEmpty(fileList);
            nFiles = numel(fileList);
            for ff = 1:nFiles
                fileName = fileList{ff};
                testCase.assertEqual(fileName(end-6:end), 'Tests.m');
            end
        end
        
        function testFindNotAFolder(testCase)
            fileList = rtbFindFiles('root', 'not-a-folder');
            testCase.assertEmpty(fileList);
        end
        
        function testFindImpossibleFilter(testCase)
            toolboxRoot = rtbRoot();
            fileList = rtbFindFiles('root', toolboxRoot, 'filter', 'nononono');
            testCase.assertEmpty(fileList);
        end
    end
end
