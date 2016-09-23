classdef RtbRecipeTests < matlab.unittest.TestCase
    
    methods (Test)
        
        function testLifecycle(testCase)
            % build a recipe
            configureScript = '';
            executive = {@rtbMakeRecipeSceneFiles, @rtbMakeRecipeRenderings, @rtbMakeRecipeMontage};
            parentSceneFile = fullfile(rtbRoot(), 'Test', 'Automated', 'Fixture', 'CoordinatesTest.dae');
            conditionsFile = fullfile(rtbRoot(), 'Test', 'Automated', 'Fixture', 'SimpleConditions.txt');
            mappingsFile = fullfile(rtbRoot(), 'Test', 'Automated', 'Fixture', 'DragonColorCheckerMappings.txt');
            hints.workingFolder = fullfile(tempdir(), 'RtbRecipeTests');
            hints.renderer = 'SampleRenderer';
            
            recipe = rtbNewRecipe( ...
                'configureScript', configureScript, ...
                'executive', executive, ...
                'parentSceneFile', parentSceneFile, ...
                'conditionsFile', conditionsFile, ...
                'mappingsFile', mappingsFile, ...
                'hints', hints);
            
            testCase.assertInstanceOf(recipe, 'struct');
            testCase.assertNumElements(recipe, 1);
            
            % execute the recipe
            recipe = rtbExecuteRecipe(recipe, 'throwException', false);
            testCase.assertInstanceOf(recipe.log, 'struct');
            allErrorData = [recipe.log.errorData];
            if ~isempty(allErrorData)
                rethrow(allErrorData(1));
            end
        end
        
        function testReadWrite(testCase)
            % build a recipe
            recipe = rtbNewRecipe();
            testCase.assertInstanceOf(recipe, 'struct');
            testCase.assertNumElements(recipe, 1);
            
            % write to disk and read it back
            archiveName = fullfile(tempdir(), 'RtbRecipeTests', 'recipe.mat');
            rtbPackUpRecipe(recipe, archiveName);
            sameRecipe = rtbUnpackRecipe(archiveName);
            testCase.assertInstanceOf(recipe, 'struct');
            testCase.assertNumElements(recipe, 1);
            
            testCase.assertEqual(sameRecipe, recipe);
        end
        
        function testConcurrentReadWrite(testCase)
            % build a recipe
            recipe = rtbNewRecipe();
            testCase.assertInstanceOf(recipe, 'struct');
            testCase.assertNumElements(recipe, 1);
            
            % write to disk and read it back, a lot
            nLots = 10;
            parfor ll = 1:nLots
                archiveName = fullfile(tempdir(), 'RtbRecipeTests', sprintf('recipe-%d.mat', ll));
                
                rtbPackUpRecipe(recipe, archiveName);
                sameRecipe = rtbUnpackRecipe(archiveName);
                testCase.assertInstanceOf(recipe, 'struct');
                testCase.assertNumElements(recipe, 1);
                
                testCase.assertEqual(sameRecipe, recipe);
            end
        end
    end
end
