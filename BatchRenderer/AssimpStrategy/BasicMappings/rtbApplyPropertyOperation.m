function newValue = rtbApplyPropertyOperation(property, oldValue)
%% Apply a mappings property operator to an old value, to make a new value.
%
% newValue = rtbApplyPropertyOperation(property, oldValue) computes a new
% property value based on the given mappings property.value and an old
% value for that property.  The computation depends on the given
% property.operation.
%
% The default operation is simply to replace the old value with the
% new value.
%
% Other operations are also supportd by supplying a Matlab expression to
% evaluate.  The expression may refer to certain variables, which will be
% bound automatically before evaluation:
%   'oldValue' will be bound to the oldValue passed to this function
%   'value' will be bound to the property.value passed to this function
% The new, computed value will be the result of the expression evaluation.
%
% Returns a new value based on the given property.value,
% property.operation, and oldValue.
%
% newValue = rtbApplyPropertyOperation(property, oldValue)
%
% Copyright (c) 2016 mexximp Team

parser = inputParser();
parser.addRequired('property', @isstruct);
parser.addRequired('oldValue');
parser.parse(property, oldValue);
property = parser.Results.property;
oldValue = parser.Results.oldValue;

if isempty(oldValue)
    newValue = property.value;
    return;
end

%% Compute the new value.
isSimpleAssignment = isempty(property.operation) || strcmp('=', property.operation);
if isSimpleAssignment
    if isempty(property.value)
        newValue = oldValue;
    else
        newValue = property.value;
    end
    return;
end

% evaluate the given expression against oldValue and property.value
newValue = evalClean(property.operation, oldValue, property.value);

%% Evaluate in a clean workspace with oldValue and value bound.
function newValue = evalClean(expression, oldValue, value)
newValue = eval(expression);
