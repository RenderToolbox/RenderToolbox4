function [string, isChanged] = rtbSubstituteStringVariables(string, names, values, varargin)
%% Replace (name) syntax with named variable values.
%
% string = rtbSubstituteStringVariables(string, names, values)
% Scans the given string for occurrences of named variable syntax, for
% example, 'bar bar (foo) baz baz'.  When found, the given cell array of
% names will be searched for the variable name, for example 'foo'.  The
% variable syntax will be replaced with the corresponding element of the
% given cell array of values.
%
% rtbSubstituteStringVariables( ... 'variableExpression', variableExpression)
% specifies the regular expression to use when finding and replacing for
% variable syntax.  The default is '\([\w]+\)', which matches strings
% like '(foo)', and '(barbaz)', but not '()' or '(bar baz)'.
%
% rtbSubstituteStringVariables( ... 'defaultValue', defaultValue) specifies a
% default value to use in case some variable syntax does not match one of
% the given names.  The default is ''.
%
% Returns the given string, which may have been altered.  Also returns the
% a logical flag, true if the string was changed.
%
% string = rtbSubstituteStringVariables(string, names, conditionValues, varargin)
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addRequired('string', @ischar);
parser.addRequired('names', @iscellstr);
parser.addRequired('values', @iscellstr);
parser.addParameter('variableExpression', '\([\w]+\)', @ischar);
parser.addParameter('defaultValue', '', @ischar);
parser.parse(string, names, values, varargin{:});
string = parser.Results.string;
names = parser.Results.names;
values = parser.Results.values;
variableExpression = parser.Results.variableExpression;
defaultValue = parser.Results.defaultValue;

%% Search for occurrences of variable syntax.
[starts, ends] = regexp(string, variableExpression, 'start', 'end');
nMatches = numel(starts);

%% Replace each
isChanged = false;
for vv = nMatches:-1:1
    ss = starts(vv);
    ee = ends(vv);
    name = string(ss+1:ee-1);
    [value, isMatched] = rtbGetNamedValue(names, values, name, defaultValue);
    if isMatched
        string = [string(1:ss-1) value string(ee+1:end)];
        isChanged = true;
    end
end
