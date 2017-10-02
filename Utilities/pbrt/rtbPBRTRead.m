function txtLines = rtbPBRTRead(fname,varargin)
% Return every line of a PBRT file as a cell array
%
%
% In related routines we parse the lines into blocks for decoding and changing
% certain things.
%
% Example
%  
% BW/TL Scienstanford 2017

%% Programming todo
%  Find the Renderer (e.g., Metropolis) block.  Delete it.  Or, replace it with
%  the default and the specification of the pixel samples.
%
%  This is a search through the cells for the Renderer string, and then the
%  block continues until the empty string. Many of the blocks can be found that
%  way.  Maybe rtbPBRTFindBlock(txtLines,blockName)?
% 
%  Apparently, SurfaceIntegrator is another term we want to delete.
% 
%  I am not sure why these don't run properly with our docker version.  The best
%  would be to make them run!
%
%{
  % Find a block
  txtLines = rtbPBRTRead('/home/wandell/pbrt-v2-spectral/pbrt-scenes/sanmiguel.pbrt');
  nLines = length(txtLines);
  for ii=1:nLines
     thisLine = txtLines{ii};
     if length(thisLine) >= length('Renderer')
         if strncmp(thisLine,'Renderer',length('Renderer'))
           fprintf('Renderer on line %d\n',ii)
           for jj=(ii+1):nLines
             if isempty(txtLines{jj})
               fprintf('Block ends at %d\n',jj);
               break;
             end
           end
         end
     end
  end
  % Then we can edit the lines in the block, or just delete the whole thing
  % And then we edit the parameters which have values in brackets - []
%}


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
