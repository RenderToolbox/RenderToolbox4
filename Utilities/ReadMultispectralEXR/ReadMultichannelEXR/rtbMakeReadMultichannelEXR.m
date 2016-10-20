function rtbMakeReadMultichannelEXR()
%% Compile and test the MakeReadMultichannelEXR Mex-function.
%
% rtbMakeReadMultichannelEXR() Compiles the ReadMultichannelEXR() mex
% function from source.  Assumes that the OpenEXR libraries have been
% installed on the system at user/, user/local/, or opt/local/.  If the
% libraries are installed somewhere else on your system, you should copy
% this file and edit the  INC and LINC variables to contain the correct
% include and library paths  for your OpenEXR installation.
%
% Attempts to read a sample OpenEXR image and plot channel data in a new
% figure, to verify that the funciton compiled successfully.
%
% On Ubuntu, you may wish to run the following command to get the
% dependencies you need:
%   sudo apt-get install openexr libopenexr-dev libilmbase-dev zlib1g-dev
%
% On OS X, you can probably find a similar command with Homebrew.
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

%% Choose the source and function files
cd(fullfile(rtbRoot(), 'Utilities', 'ReadMultispectralEXR', 'ReadMultichannelEXR'));
source = 'ReadMultichannelEXR.cpp';
output = '-output ReadMultichannelEXR';

%% Choose library files to include and link with.
INC = '-I/usr/local/include/OpenEXR -I/usr/include/OpenEXR -I/opt/local/include/OpenEXR';
LINC = '-L/usr/local/lib -L/usr/lib -L/opt/local/lib';
LIBS = '-lIlmImf -lz -lImath -lHalf -lIex -lIlmThread -lpthread';

%% Build the function.
mexCmd = sprintf('mex %s %s %s %s %s', INC, LINC, LIBS, output, source);
fprintf('%s\n', mexCmd);
eval(mexCmd);

%% Test the function with a sample EXR file.
testFile = 'TestSphereMitsuba.exr';
[sliceInfo, data] = rtbReadMultichannelEXR(testFile);

fprintf('If you see a figure with several images, rtbReadMultichannelEXR() is working.\n');
figure();
rtbPlotSlices(sliceInfo, data);
