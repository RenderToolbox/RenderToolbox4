classdef kubernetes < handle
    % Interface to remember different kubernetes (kubectl) commands
    %
    properties
     
        % User's name space.  Set when the object is created.
        namespace = '';
        
    end
    
    methods
        function obj = kubernetes(namespace,varargin)
            p = inputParser;
            p.addRequired('namespace',@ischar);
            p.parse(namespace,varargin{:});
            
            obj.namespace = p.Results.namespace;
            
        end
        
        % List the jobs running in your name space
        function [result,status] = jobs(obj,varargin)
            
            p = inputParser;
            p.addParameter('recipeName','*',@ischar);
            p.parse(varargin{:});
            recipeName = p.Results.recipeName;
            % Could also add 'recipeName' and grep on that
            if recipeName == '*'
                cmd = sprintf('kubectl get jobs --namespace=%s',obj.namespace);
            else
                cmd = sprintf('kubectl get jobs --namespace=%s | grep %s',obj.namespace,recipeName);
            end
            
            % cmd = sprintf('kubectl get jobs --namespace=%s | grep %s',obj.namespace,recipeName);
            [status, result] = system(cmd);
        end
        
    end
end
