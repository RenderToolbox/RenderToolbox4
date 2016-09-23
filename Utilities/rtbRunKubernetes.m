function [status, result] = rtbRunKubernetes(command, podSelector, varargin)
%% Run a command in a Kubernetes pod with "kubectl exec"
%
% [status, result] = rtbRunDocker(command, podSelector)
% executes the given command inside a Kubernetes pod, chosen based on the
% given podSelector.
%
% rtbRunDocker( ... 'workingFolder', workingFolder) the working folder to
% use inside the Kubernetes pod container.  The default is none, don't
% change folder inside the pod.
%
% rtbRunDocker( ... 'hints', hints) struct of RenderToolbox4 options, as
% from rtbDefaultHints().
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

parser = inputParser();
parser.addRequired('command', @ischar);
parser.addRequired('podSelector', @ischar);
parser.addParameter('workingFolder', '', @ischar);
parser.addParameter('hints', rtbDefaultHints(), @isstruct);
parser.parse(command, podSelector, varargin{:});
command = parser.Results.command;
podSelector = parser.Results.podSelector;
workingFolder = parser.Results.workingFolder;
hints = rtbDefaultHints(parser.Results.hints);

%% Build command to select a running pod.
podCommand = sprintf('kubectl get pods --selector="%s" --output jsonpath=''{.items[?(@.status.phase=="Running")].metadata.name}''', ...
    podSelector);
[status, result] = system(podCommand);
if 0 ~=status
    return;
end

% take fist pod name and trim
podName = sscanf(result, '%s', 1);


%% Build the command with actual business.

execCommand = command;

% kubectl exec doesn't explicitly support a --workdir like Docker run.
% instead, prepend the command with the cd.
if ~isempty(workingFolder)
    execCommand = sprintf('cd %s && %s', workingFolder, execCommand);
end

kubeCommand = sprintf('kubectl exec -ti %s -- /bin/bash -c "%s"', podName, execCommand);


%% Invoke the Kubernetes command with or without capturing results.
[status, result] = rtbRunCommand(kubeCommand, 'hints', hints);

