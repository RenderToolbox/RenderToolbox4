%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Modify a Collada document once per condition, before applying mappings.
%   @param docNode XML Collada document node Java object
%   @param mappings struct of mappings data from ParseMappings()
%   @param varNames cell array of conditions file variable names
%   @param varValues cell array of variable values for current condition
%   @param conditionNumber the number of the current condition
%   @param hints struct of RenderToolbox4 options
%
% @details
% This function is a template for a RenderToolbox4 "BeforeCondition"
% remodeler function.  A remodeler is a set of user-defined functions for
% modifying Collada parent scene documents.
%
% @details
% By default, RenderToolbox4 does not invoke any remodeler.  If the name of
% a remodeler is specified in the @b hints.remodeler argument passed to a
% function like rtbMakeSceneFiles(), then RenderToolbox4 will automatically
% invoke the named remodeler during scene file generation.
%
% @details
% The name of a BeforeCondition function must match a specific pattern: it
% must begin with "RTB_BeforeCondition_", and it must end with the name of
% a remodeler, for example "SampleRemodeler".  This pattern allows
% RenderToolbox4 to automatically locate the BeforeCondition function for a
% given remodeler.  BeforeCondition functions should be included in the
% Matlab path.
%
% @details
% A BeforeCondition function must accept as its first argument an XML
% document node Java object, as returned from ReadSceneDom().  This @a
% docNode will represent the entire Collada parent scene.  It must accept
% as subsequent arguments: a struct of mappings data as returned from
% ParseMappings(), a cell array of variable names and variable values for
% the current condition, the number of the current condition, and a struct
% of RenderToolbox4 options as returned from rtbDefaultHints().
%
% @details
% A BeforeCondition function may modify the XML document in any way, or not
% at all.  It may use any of the given @a mappings, @a varNames, @a
% varValues, or @a conditionsNumber to make modifications that are specific
% to current condition.  These modifications will be applied once per
% condition, before mappings are applied to the parent scene.  Thus, these
% modifications may affect how mappings are processed, and will apply only
% to the current condition.
%
% @details
% A BeforeCondition function must return the given XML document node Java
% object, or a different XML document node Java object, if desired.
%
% Usage:
%   docNode = RTB_BeforeCondition_SampleRemodeler(docNode, mappings, varNames, varValues, conditionNumber, hints)
%
% @ingroup RemodelerPlugins
function docNode = RTB_BeforeCondition_SampleRemodeler(docNode, mappings, varNames, varValues, conditionNumber, hints)

disp('SampleRemodeler BeforeCondition function.')

disp('docNode is:');
disp(docNode);
disp('mappings is:');
disp(mappings);
disp('varNames is:');
disp(varNames);
disp('varValues is:');
disp(varValues);
disp('conditionNumber is:');
disp(conditionNumber);
disp('hints is:');
disp(hints);