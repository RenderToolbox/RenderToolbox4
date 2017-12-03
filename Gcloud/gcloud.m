classdef gcloud < handle
    %
    %  gcloud(command,varargin)
    %
    %  ls: @gcloud('ls','directory')
    %  rm: @gcloud('rm','fullpath to file')
    %e
    
    properties
        bucket = '';
    end
    
    methods
        function obj = gcloud(varargin)
            p = inputParser;
            p.addParameter('bucket','gs://primal-surfer-140120.appspot.com/',@ischar);
            
            p.parse(varargin{:});
            
            obj.bucket = p.Results.bucket;
        end
        
        function [result, status] = ls(obj,directory)
            if ieNotDefined('directory');
                d = obj.bucket;
            else
                d = fullfile(obj.bucket, directory);
            end
            
            cmd = sprintf('gsutil ls %s\n',d);
            [status,result] = system(cmd);
            result1 = textscan(result,'%s','Delimiter','\n','CollectOutput',true);
            result = result1{1};
            if strncmp(result{1},'CommandException',7)
                disp(result{1})
                return;
            else
                nFiles = size(result,1);
                nSkip = length(obj.bucket);
                for ii=1:nFiles
                    result{ii} = result{ii}((nSkip+1):end);
                end
            end
            
        end
        
        function [result,status] = rm(obj,fname)
            %
            filename = fullfile(obj.bucket, fname);
            cmd = sprintf('gsutil rm %s\n',filename);
            [status,result] = system(cmd);
        end
        
    end
end
