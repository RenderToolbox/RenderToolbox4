%% v_acloudTest
%
% Try the different acloud methods and make sure they are all working
%
% ZL Vistasoft Team 2017
clear all;
aliyun = acloud;
disp(aliyun)

%% Create a bucket
bname = 'vistabucket'; % we recommand a unique name for bucketname rather than an ordinary name like 'test' or 'testbucket'
aliyun.bucketCreate(bname);
aliyun.ls % list the buckets

%% upload a local file to the bucket.
aliyun.upload('RenderToolbox4/testfile_acloud.m',bname)
aliyun.ls(bname)% list the contents in the bucket

%% Delete the loacl file first, and Downlaod the file from bucket to local. 
delete('RenderToolbox4/testfile_acloud.m')% You can manually delete the file as well.
aliyun.download(bname,'RenderToolbox4');
% You can find the file again in your current folder.

%% Delete the object in the bucket
aliyun.objectrm('vistabucket/testfile_acloud.m')
aliyun.ls(bname)

%% Delete the bucket
aliyun.bucketrm(bname)
aliyun.ls