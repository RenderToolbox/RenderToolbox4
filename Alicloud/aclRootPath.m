function rootPath=aclRootPath()
%%isetbioRootPath   Return the path to the root isetbio directory
%
% Syntax:
%    rootPath=aclRootPath;
%
% Description:
%    This points at the top level of the acloud tree on the Matlab path.
%    

%% Get path to this function and then walk back up to the isetbio root.
pathToMe = mfilename('fullpath');

%% Walk back up the chain
rootPath = fileparts(pathToMe);

end
