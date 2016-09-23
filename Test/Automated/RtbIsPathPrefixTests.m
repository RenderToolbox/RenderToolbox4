classdef RtbIsPathPrefixTests < matlab.unittest.TestCase
    
    methods (Test)
        
        function testPrefix(testCase)
            testCase.assertTrue(rtbIsPathPrefix('/foo/bar/', '/foo/bar/baz'));
            testCase.assertTrue(rtbIsPathPrefix('/foo/bar/fileA.txt', '/foo/bar/baz/fileB.png'));
            
            testCase.assertFalse(rtbIsPathPrefix('/foo/bar/baz', '/foo/bar/'));
            testCase.assertFalse(rtbIsPathPrefix('/foo/bar/baz/fileB.png', '/foo/bar/fileA.txt'));
        end
        
        function testEqual(testCase)
            testCase.assertTrue(rtbIsPathPrefix('/foo/bar/', '/foo/bar/fileA.txt'));
            testCase.assertTrue(rtbIsPathPrefix('/foo/bar/fileA.txt', '/foo/bar/'));
        end
        
        function testRemainder(testCase)
            pathA = '/foo/bar/';
            pathB = '/foo/bar/baz/thing.txt';
            [isPrefix, remainder] = rtbIsPathPrefix(pathA, pathB);
            testCase.assertTrue(isPrefix);
            testCase.assertEqual(remainder, 'baz/thing.txt');
            
            reproduction = fullfile(pathA, remainder);
            testCase.assertEqual(reproduction, pathB);
        end
        
    end
end
