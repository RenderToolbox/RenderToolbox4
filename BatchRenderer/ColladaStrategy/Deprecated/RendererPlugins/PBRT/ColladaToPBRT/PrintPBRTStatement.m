%%% RenderToolbox4 Copyright (c) 2012-2013 The RenderToolbox4 Team.
%%% About Us://github.com/DavidBrainard/RenderToolbox4/wiki/About-Us
%%% RenderToolbox4 is released under the MIT License.  See LICENSE.txt.
%
% Print a standard PBRT scene file statement to a file.
%   @param fid
%   @param identifier
%   @param type
%   @param params
%
% @details
% Write a standard PBRT statement with the given @a identifier, @a type,
% and struct array of @a params.  The given @a fid should be a file
% descriptor as returned from fopen().
%
% @details
% @a identifier should be a string PBRT identifier, like 'Film',
% 'Material', 'Shape', 'etc.  @a type should be a string PBRT object type
% that agrees with the identifier, like 'image', 'plastic', or
% 'trianglemesh'.
%
% @details
% @a params should be a struct array with one element per parameter
% to be listed.  It should have the following fields:
%   - name - the name of a PBRT object parameter like 'xresolution',
%   'roughness', or 'P'
%   - type - a PBRT value type, like 'float', 'point', or 'string'
%   - value - a value to use for the named parameter.  numeric values will
%   be converted to strings.
%   .
% The resulting PBRT scene file statement will look something like this:
%   identifier "type"
%       "params(1).type params(1).name" [params(1).value]
%       "params(2).type params(2).name" "params(2).value"
%   etc...
%
% @details
% Used internally by ColladaToPBRT().
%
% @details
% Usage:
%   PrintPBRTStatement(fid, identifier, type, params)
%
% @ingroup ColladaToPBRT
function PrintPBRTStatement(fid, identifier, type, params)

fprintf(fid, '%s ', identifier);
if ~isempty(type)
    % type, like "perspective"
    fprintf(fid, '"%s" ', type);
end

for ii = 1:numel(params)
    p = params(ii);
    
    % put each param on its own indented line
    fprintf(fid, '\n  ');
    
    % automatically convert numeric values
    p.value = VectorToString(p.value);
    
    % param, like "float fov" [90]
    fprintf(fid, '"%s %s" ', p.type, p.name);
    switch p.type
        case {'string', 'texture'}
            fprintf(fid, '"%s" ', p.value);
            
        case 'spectrum'
            % spectrum may be numeric or string
            if 0 == numel(StringToVector(p.value))
                fprintf(fid, '"%s" ', p.value);
            else
                % numeric spectrum should use space, not colon delimiters
                p.value(':' == p.value) = ' ';
                fprintf(fid, '[%s] ', p.value);
            end
            
        case 'bool'
            if islogical(p.value) || isnumeric(p.value)
                if p.value
                    fprintf(fid, '"true" ');
                else
                    fprintf(fid, '"false" ');
                end
            else
                fprintf(fid, '"%s" ', p.value);
            end
            
        otherwise
            fprintf(fid, '[%s] ', p.value);
    end
end
fprintf(fid, '\n');
