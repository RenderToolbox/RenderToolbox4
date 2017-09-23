function [status,kubePath] = rtbKubectlConfig
% Test whether kubectl is on the PATH inherited by Matlab
%
%    status = rtbKubectlConfig;
%    
% If status = 0 means it is found
%    result is the path
% 
% Wandell, 2017

% See if it is there
[status, kubePath] = system('which kubectl');

% If not, try this default place
if status
    initPath = getenv('PATH');
    kubePath = fullfile(getenv('HOME'),'google-cloud-sdk','bin');
    if exist(fullfile(kubePath,'kubectl'),'file')
        fprintf('Adding %s to PATH.\n',kubePath);
        setenv('PATH', [kubePath,':',initPath]);
        status = 0;
    else
        % If not there, tell the user.
        fprintf('Could not find kubectl on your system.\n');
        return;
    end
else
    % It was found. Yippee.
    fprintf('Found kubectl at %s\n',kubePath');
end

end


