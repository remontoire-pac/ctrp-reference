function [Data sortIndex rowFreq] = DFsort(Data,fields,isAscendVec,isUniq)
% DFSORT
%       Sorts a structure of arrays for any number of fields
%
%    [SortedData sortIndex rowFreq] = DFsort(Data,fields,isAscendVeci,isUniq)
%
% parameters
%----------------------------------------------------------------
%    "Data"       - a dataframe
%    "fields"     - a cell array of field names in "Data"
%    "isAscendVec"- a logical vector whether each column
%                   is sorted ascending (true is default)
%    "isUniq"     - a logical whether only unique rows are
%                   returned (false is default)
%
% outputs
%----------------------------------------------------------------
%    "SortedData" - a sorted version of Data
%    "sortIndex"  - the indices of rows in Data in the sorted order
%    "rowFreq"    - the frequency of each output row
%----------------------------------------------------------------
%
%    Hy Carrinski
%    Broad Institute
%    Note: NaN are treated as equal and '' are treated as equal.
%    so, NaNs are sorted together and not removed, and are
%    merged according to "isUniq"

% QC the input
if nargin < 2 || isempty(fields) || not( iscellstr(fields) || ischar(fields) )
    error('ccbr:BadInput','Second input "fields" must be a cell array');
end
if ischar(fields)
    fields = cellstr(fields); 
end

if nargin < 3 || isempty(isAscendVec)
   isAscendVec = true(numel(fields),1);
else
   isAscendVec = isAscendVec(:);
end

if nargin < 4 || isempty(isUniq)
    isUniq = false;
end

% Make sure fields is a cell array of strings
assert(all(cellfun(@(x) ischar(x), fields)), ...
    'ccbr:BadInput','Cell array fields must contain strings');

% Check that fields are present
assert(all(isfield(Data,fields)), ...
    'ccbr:BadInput','Some requested fields are not present in input');

% Ensure that every column is 1D and has an equal number of rows
[isOkay numRows] = DFverify(Data,true);
assert(isOkay == 1,'ccbr:BadInput','fields must be arrays of size N x 1');
% QC is complete

% Ready to sort
numFields   = numel(fields);
keyIdx      = zeros(numRows,numFields);
isEqualNaNs = true;
for i = 1:numFields
    [ tmpB tmpI keyIdx(:,i) ] = uniquenotmiss(Data.(fields{i}), isEqualNaNs);
end

% Do math to determine sort direction
sortDirection = (double(isAscendVec)*2 - 1).*(1:numFields)';

% Keep all rows (by default)
if not(isUniq)
    % Find sort order using rows of matrix of unique values
    [tmpS sortIndex] = sortrows(keyIdx,sortDirection);
    if nargout == 3
        rowFreq  = ones(numRows,1);
    end
else
    [keyIdx uniqIdx freqIdx] = unique(keyIdx,'rows','first');
    % Find sort order using rows of matrix of unique values
    [tmpS uniqSortIdx] = sortrows(keyIdx,sortDirection);
    sortIndex  = uniqIdx(uniqSortIdx);
    % count row frequency
    if nargout == 3
       uniqFreq = transpose(hist(freqIdx,1:numel(uniqIdx)));
       rowFreq  = uniqFreq(uniqSortIdx);
    end
end 
% Perform sorting
Data = DFkeeprow(Data,sortIndex);
