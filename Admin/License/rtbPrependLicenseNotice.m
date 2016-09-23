function rtbPrependLicenseNotice(varargin)
%% Prepend copyright and license text to all RenderToolbox4 m-files.
%
% rtbPrependLicenseNotice() Recursively finds all m-files in the
% RenderToolbox4 file tree.  For each m-file, adds the text in
% licenseNotice.m to the top of the file.
%
% The lines in licenseNotice.m all begin with %%%.  Any lines at the top of
% each m-file that begin with %%% will be overwritten.  Subsequent lines
% will be copied as they are.  This prevents redundant copyright and
% license notices, and allows them to be updated.
%
% rtbPrependLicenseNotice('commit', true) Actually modifies
% RenderToolbox4 files with copyright and license text.  The default is to
% display a preview of each RenderToolbox4 file with copyright and license
% text prepended.
%
%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.

parser = inputParser();
parser.addParameter('commit', false, @islogical);
parser.parse(varargin{:});
commit = parser.Results.commit;

% get all the m-files in the RenderToolbox4 source tree
mFiles = rtbFindFiles(rtbRoot(), '\.m$');

% get the text to prepend
noticeFile = fullfile(rtbRoot(), 'licenseNotice.m');
fid = fopen(noticeFile, 'r');
headerText = char(fread(fid))';
fclose(fid);

% append text to all m-files
nFiles = numel(mFiles);
for ii = 1:nFiles
    % skip the license notice itself
    if strcmp(noticeFile, mFiles{ii})
        continue;
    end
    
    % read the original m-file text
    %   skipping leading lines that are empty, or start with %%%
    fid = fopen(mFiles{ii}, 'r');
    skipPosition = ftell(fid);
    line = fgetl(fid);
    while ischar(line) && (isempty(line) || ~isempty(regexp(line, '^%%%')))
        skipPosition = ftell(fid);
        line = fgetl(fid);
    end
    fseek(fid, skipPosition, 'bof');
    mFileText = char(fread(fid))';
    fclose(fid);
    
    % prepend the header text to m-file text
    newText = cat(2, headerText, mFileText);
    
    if commit
        % really modify files
        
        % write new text to a temporary file
        tempFile = 'tempFile.m';
        fid = fopen(tempFile, 'w');
        fwrite(fid, newText);
        fclose(fid);
        
        % replace the original file
        copyfile(tempFile, mFiles{ii});
        
        % done with the temp file
        delete(tempFile);
        
    else
        % preview file changes
        disp(' ')
        disp('----')
        disp(mFiles{ii})
        disp(' ')
        extent = min(numel(newText), 2*numel(headerText));
        disp([newText(1:extent) '...'])
        
    end
end