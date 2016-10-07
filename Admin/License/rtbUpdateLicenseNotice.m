function rtbUpdateLicenseNotice(varargin)
%% Insert copyright and license text to all RenderToolbox4 m-files.
%
% rtbUpdateLicenseNotice() Recursively finds all m-files in the
% RenderToolbox4 file tree.  For each m-file, inserts the text in
% licenseNotice.m near the top of the file.
%
% The lines in licenseNotice.m all begin with %%%.  Any lines near the top
% of each m-file that begin with %%% will be replced with the contents of
% licenseNotice.m.  Other lines will be copied as they are.  This prevents
% redundant copyright and license notices, and allows them to be updated.
%
% rtbUpdateLicenseNotice('commit', true) Actually modifies
% RenderToolbox4 files with copyright and license text.  The default is to
% display a preview of each RenderToolbox4 file with copyright and license
% text added.
%
%%% RenderToolbox4 Copyright (c) 2012-2016 The RenderToolbox Team.
%%% About Us://github.com/RenderToolbox/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE file.

parser = inputParser();
parser.addParameter('commit', false, @islogical);
parser.parse(varargin{:});
commit = parser.Results.commit;

% get all the m-files in the RenderToolbox4 source tree
mFiles = rtbFindFiles('root', rtbRoot(), 'filter', '\.m$');

% get the text to insert
noticeFile = fullfile(rtbRoot(), 'Admin', 'License', 'licenseNotice.m');
fid = fopen(noticeFile, 'r');
licenseText = fread(fid, '*char');
fclose(fid);

% append text to all m-files
nFiles = numel(mFiles);
for ii = 1:nFiles
    % skip the license notice itself
    if strcmp(noticeFile, mFiles{ii})
        continue;
    end
    
    % read the original m-file text line by line.  Look for
    %   leading text before the first %%%, to copy
    %   contiguous lines starting with %%%, to replace
    %   trailing lines after the last contiguous %%%, to copy
    fid = fopen(mFiles{ii}, 'r');
    originalText = fread(fid, '*char');
    fclose(fid);
    [starts, ends] = regexp(originalText', '(?m)^%%%(?-s).+(?m)$');
    if isempty(starts)
        continue;
    end
    
    % assemble chunks of text:
    %   original leading text
    %   licence text
    %   original trailing
    leadingRange = 1:starts(1)-1;
    trailingRange = ends(end)+1:numel(originalText);
    newText = cat(1, originalText(leadingRange), licenseText, originalText(trailingRange));
    
    if commit
        % really modify files
        
        % write new text to a temporary file
        tempFile = fullfile(tempdir(), 'rtbUpdateLicenseNotice.m');
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
        if isempty(leadingRange)
            previewStart = 1;
        else
            previewStart = max(leadingRange) - 20;
        end
        previewEnd = previewStart + numel(licenseText) + 40;
        disp(['...' newText(previewStart:previewEnd)' '...'])
        
    end
end