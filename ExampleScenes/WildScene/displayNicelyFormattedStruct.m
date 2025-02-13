% Method to display a nicely formatted view of all the fields in a nested structure
%
% This function borrowed from Nicolas Cottaris and UnitTestToolbox. Thanks!
%   https://github.com/isetbio/UnitTestToolbox
%
function s = displayNicelyFormattedStruct(datum, datumName, s, maxFieldWidth)
    s = displayStruct(datum, datumName, s, maxFieldWidth);
end

function s = displayStruct(datum, datumName, s, maxFieldWidth)
    a = whos; theOldStruct = a(1).name;
    dots = find(datumName=='.');
    
    if numel(dots)>0
        datumSize = determineSize(datum);
        datumType = sprintf('%s', class(datum));
        if (ischar(datum) || numel(datum) == 1)
            if (ischar(datum))
                datumSizeAndType = sprintf('%15s  %-8s (''%s'')', datumSize, datumType, datum);
            elseif (isnumeric(datum))
                datumSizeAndType = sprintf('%15s  %-8s (%g)', datumSize, datumType, datum);
            else
                datumSizeAndType = sprintf('%15s  %-8s', datumSize, datumType);
            end
        else
            datumSizeAndType = sprintf('%15s  %-8s', datumSize, datumType);
        end
        newString = sprintf('<strong>%s</strong>', datumName((dots(end)+1):end));
        newString = sprintf('%s%s%s', char(repmat([124 160 160 160 160 160 160],1,numel(dots)-1)), '|---', newString);
        spacePadding = maxFieldWidth - numel(newString);
        for k = 1:spacePadding
            newString = sprintf('%s ', newString);
        end
        if (numel(dots) == 1)
            % add a newline if the field is at top level
            newString = sprintf('|\n%s %s', newString, datumSizeAndType);
        else
            newString = sprintf('%s %s', newString, datumSizeAndType);
        end
        s = sprintf('%s\n%s', s, newString);  
    else
        datumSize = determineSize(datum);
        datumType = sprintf('%s', class(datum));
        datumSizeAndType = sprintf('%15s %-8s', datumSize, datumType);
        newString = sprintf('%s\n<strong>%s</strong>', s, datumName);
        spacePadding = maxFieldWidth - numel(newString);
        for k = 1:spacePadding
            newString = sprintf('%s ', newString);
        end
        s = sprintf('%s  %s', newString, datumSizeAndType);
    end  

    if isstruct(datum)
        theFieldNames = fieldnames(datum);
        for x = 1:numel(theFieldNames)
            s = displayStruct(eval([theOldStruct '.' theFieldNames{x}]), sprintf('%s.%s', datumName,theFieldNames{x}), s, maxFieldWidth);
        end
    end
end

function sz = determineSize(datum)
    datumSize = size(datum);
    k = 0;
    sz = '[';
    while k < numel(datumSize)
        k = k + 1;
        if k < numel(datumSize)
            sz = sprintf('%s%dx', sz, datumSize(k));
        else
            sz = sprintf('%s%d', sz, datumSize(k));
        end
    end
    sz = sprintf('%s]',sz);
end
