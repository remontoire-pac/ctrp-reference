function [Data Meta] = DFaddindex(Data,fields,indexNames,inclNaNEmpty)
% DFADDINDEX
%       addindexs a structure of arrays for any number of fields
%
%    [IndexedData Meta] = DFaddindex(Data,fields,indexNames,inclNaNEmpty)
%
% parameters
%----------------------------------------------------------------
%    "Data"       - a dataframe
%    "fields"     - a cell array of field names in "Data" to index
%    "indexnames" - a cell array of names for the indexed fields, a single
%                   name results in one index, multiple names result in
%                   on index per name, if empty (default), results in a single
%                   index per name, with the ith name being "id<fields{i}>"
%    "inclNaNEmpty" - boolean whether to ignore NaNs and empty strings (default=0)
%                     or to set all NaNs equal and all empty strings equal (=1)
%
% outputs
%----------------------------------------------------------------
%    "IndexedData" - an indexed version of Data
%    "Meta"        - a cell array of data frames, where each cell contains
%                    a LUT between values and index
%----------------------------------------------------------------
%
% Note: if NaN's or empty strings should be included in the indexing,
%       it is suggested to set inclNaNEmpty=true, otherwise, all rows
%       containing any NaNs will receive an index of 0.
%
%    Hy Carrinski
%    Broad Institute
%    Based on DFindex

% QC the input
if nargin < 2 || isempty(fields) || not( iscellstr(fields) || ischar(fields) )
    error('ccbr:BadInput','Second input "fields" must be a cell array');
end
if ischar(fields)
    fields = cellstr(fields); 
end

if nargin < 3 || isempty(indexNames) 
   indexNames = cellfun(@(x) ['id' upper(x(1)) x(2:end) ], fields, 'UniformOutput',false);
end
if ischar(indexNames)
    indexNames = cellstr(indexNames); 
end

if nargin < 4 || isempty(inclNaNEmpty)
   inclNaNEmpty = false;
end

% Check that fields are present
if not(all(isfield(Data,fields)))
    error('ccbr:BadInput','Some requested fields are not present in Data');
end

% Check that no fields will be overwritten
if any(isfield(Data,indexNames))
    error('ccbr:BadInput','Cannot create a field that already exists in Data');
end

% Check whether there is a single index field or an equal number of index fields
if numel(fields) == numel(indexNames)
    isIndividualIndex = true;
elseif numel(indexNames) == 1
    isIndividualIndex = false;
else
    error('ccbr:BadInput','Number of indices must be 1 or equal to number of index fields');
end

% Ensure that every relevant column is 1D and has an equal number of rows
[isOkay numRows] = DFverify(DFkeepcol(Data,fields),true);
if isOkay < 1
    error('ccbr:BadInput','fields in Data must be arrays of size N x 1');
end
% QC is complete

% Index
numFields = numel(fields);
if isIndividualIndex
    Meta      = cell(numFields,1);
    for i = 1:numFields
        [ Meta{i}.(fields{i}) tmpI Data.(indexNames{i}) ] = ...
                                       uniquenotmiss(Data.(fields{i}),inclNaNEmpty);
          Meta{i}.(indexNames{i}) = transpose(1:numel(tmpI));
    end
else
    keyIdx    = zeros(numRows,numFields);
    for i = 1:numFields
        [ vals{i} tmpI keyIdx(:,i) ] = uniquenotmiss(Data.(fields{i}),inclNaNEmpty);
    end
    % when NaNs and empties are included, they are treated like any other value
    % from here on, if they are not included, a single NaN results in an index
    % of 0 for the entire row
    badRows = find(any(keyIdx == 0, 2));
    if isempty(badRows)
        [ uniqKey tmpI Data.(indexNames{1}) ] = unique(keyIdx,'rows');
    else
        % flag rows of keyIdx for which any element is 0
        keyIdx(badRows,:) = 0;
        [ uniqKey tmpI Data.(indexNames{1}) ] = unique(keyIdx,'rows');

        % adjust indexing so that these rows index to 0.
        indexOfZero = 1;
        uniqKey(indexOfZero,:) = [];
        tmpI(indexOfZero)      = [];
        Data.(indexNames{1})   = Data.(indexNames{1}) - indexOfZero;
    end
    if nargout > 1
        for i = 1:numFields
            Meta{1}.(fields{i}) = vals{i}(uniqKey(:,i));
        end
        Meta{1}.(indexNames{1}) = transpose(1:numel(tmpI));
    end
end

