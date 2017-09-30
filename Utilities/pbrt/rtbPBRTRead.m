function txtLines = rtbPBRTRead(fname,varargin)
% Return every line of a PBRT file as a cell array
%
%
% In related routines we parse the lines into blocks for decoding and changing
% certain things.
%
% Example
%    txtLines = rtbPBRTRead('/home/wandell/pbrt-v2-spectral/pbrt-scenes/sanmiguel.pbrt')
% BW/TL Scienstanford 2017

%% Programming todo
%  Find the Renderer (e.g., Metropolis) block.  Delete it and replace it with
%  the default and the specification of the pixel samples.
%
%  This is a search through the cells for the Renderer string, and then the
%  block continues until the empty string. Many of the blocks can be found that
%  way.  Maybe rtbPBRTFindBlock(txtLines,blockName)?
%

%%
p = inputParser;
p.addRequired('fname',@(x)(exist(fname,'file')));
p.parse(fname,varargin{:});

%% Open, read, close
fileID = fopen(fname);

tmp = textscan(fileID,'%s','Delimiter','\n');
txtLines = tmp{1};

fclose(fileID);

end
