function [dataIndex Values sparseIdx] = ...
    DFindex(Data,fields,excludeIdx,Values,isND,inclNaNEmpty)
% DFINDEX
%        Generates an index for a structure of arrays for any number of fields
%
%    [dataIndex ] = DFindex(Data,fields) 
%    [dataIndex Values ] = DFindex(Data,fields) 
%    [dataIndex Values sparseIdx] = DFindex(Data,fields) 
%    [dataIndex Values sparseIdx] = ...
%            DFindex(Data,fields,excludeIdx,Values,isND,inclNaNEmpty) 
%
% parameters
%----------------------------------------------------------------
%    "Data"         - a data frame
%    "fields"       - a cell array of field names in "Data"
%    "excludeIdx"   - an optional list of indices to remove from consideration
%    "Values"       - a structure to override the output "Values" 
%    "isND"         - boolean whether dataIndex is N-dim (default=1) or linear 
%    "inclNaNEmpty" - boolean whether to ignore NaNs and empty strings (default=0)
%                     or to set all NaNs equal and all empty strings equal (=1)
%
% outputs
%----------------------------------------------------------------
%    "dataIndex" - an N-dim or linear cell array of sets of indices: each set of
%                  indices represents a unique coordinate of values from "fields"
%                  if sparseIdx is defined (nargout=3), then dataIndex is linear,
%                  has zero empty cells, and requires sparseIdx for indexing
%    "Values"    - a structure containing field names from "fields" and containing
%                  unique values from Data.(fieldname) in ascending order
%    "sparseIdx" - a M by N matrix of subscripts. Each row of N values are subscripts
%                  into a unique coordinate of N-Dimensional dataIndex. M is the
%                  number of non-empty coordinates of dataIndex
%----------------------------------------------------------------
%    
%  Note: the order of the sets is ascending by Values such that:
%        dataIndexNDim = reshape(dataIndex,structfun(@numel,Values)');
%        This function requires uniquenotmiss and DFverify in order to run
%
%    Hy Carrinski
%    Broad Institute
%    Created  21Jan2007
%    Modified 16Nov2008


% QC the input
if nargin < 2 || isempty(fields)
    error('ccbr:BadInput','DFindex requires at least two inputs');
end
if not(iscellstr(fields))
   if ischar(fields)
        fields = cellstr(fields); 
   else
       error('ccbr:BadInput','fields must be a cell array');
   end
end
% Allow index to match other data structure
if nargin < 4 || isempty(Values) || ~isstruct(Values)
    isInputValues = 1;
else
    isInputValues = 0;
    if not(all(structfun(@issorted,Values)))
        error('ccbr:BadInput','Values must be sorted in ascending order');
    end
end
% Allow single dimensional output (default is multidimensional)
if nargin < 5 || isempty(isND)
    isND = 1;
end
if nargin < 6 || isempty(inclNaNEmpty)
   inclNaNEmpty = false;
end

% Make sure fields is a cell array of strings
if not(iscellstr(fields))
    error('ccbr:BadInput','Cell array fields must contain strings');
end

% Check that fields are present
if any(not(isfield(Data,fields)))
    error('ccbr:BadInput','Some requested fields are not present in Data');
end

% Ensure that every column is 1D and has an equal number of rows
[isOkay numRows] = DFverify(Data,true);
if isOkay < 1
    error('ccbr:BadInput','Fields in Data must be arrays of size N x 1');
end

%Find class of each field to be able to exclude some rows
numFields = numel(fields);
formats = cell(numFields,1);
for i = 1:numFields
    formats{i} = class(Data.(fields{i}));
    if strcmpi(formats{i},'double') && exist('excludeIdx','var') 
        Data.(fields{i})(excludeIdx) = NaN;  % Ignore these entire rows
    elseif strcmpi(formats{i},'cell') && exist('excludeIdx','var') 
        Data.(fields{i})(excludeIdx) = {''}; % Ignore these entire rows
    end 
end
if isInputValues
    for i = 1:numFields
         Values.(fields{i}) = uniquenotmiss(Data.(fields{i}),inclNaNEmpty);
    end
else
    Values = DFkeepcol(Values,fields); % Limit Values to input field names
    UnsortedValues = Values;
    for i = 1:numFields
         Values.(fields{i}) = uniquenotmiss(Values.(fields{i}),inclNaNEmpty);
    end
    if not(isequalwithequalnans(Values,UnsortedValues))
        warning('ccbr:Paradox','elements in DF Values sorted by DFindex');
    end
    Values = orderfields(Values,fields);
    if not(isequalwithequalnans(Values,UnsortedValues))
        warning('ccbr:BadInput','fields in structure Values re-ordered by input fields');
    end
end

% Generate vectors of indices into Values ( "keys" ) for each
% pair ("field name", "unique value") from Data
% tmpB must contain the unique members from Values.(fields{i})
% in the same order
% We want keyIdx to contain numbers that correctly map
% to an index of Values.(Field)
keyIdx = zeros(numRows,numFields);
for i = 1:numFields
    [ tmpB tmpI tmpJ ] = uniquenotmiss(Data.(fields{i}),inclNaNEmpty);
    matchB             = ismember(tmpB,Values.(fields{i}));
    % remove values from tmpB and tmpI
    tmpB(not(matchB))  = [];
    tmpI(not(matchB))  = [];
    matchValInt        = find(ismember(Values.(fields{i}),tmpB));
    matchBInt          = double(matchB);
    % because tmpB and Values are both sorted in ascending order
    matchBInt(matchB)  = matchValInt;
    % pad first element of matchBInt (for tmpJ == 0)
    matchBInt          = [0; matchBInt];
    % offset tmpJ by one ( min(tmpJ+1) == 1 ) and index into
    keyIdx(:,i)        = matchBInt(tmpJ+1);    
end

% flag rows of keyIdx for which any element is 0.
goodRows                = all(keyIdx,2); % a logical vector
keyIdx(not(goodRows),:) = 0;

% Row vector containing size of each dimension (input for sub2ind)
sizFullIdx = structfun(@numel,Values)';

% Ensure that the size input to a function such
% as "cell" has greater than one element
if numel(sizFullIdx) == 1
    sizFullIdx = [sizFullIdx 1];
end

% Reverse columns so UNIQUE sorts rows properly
[B,I,J] = unique(keyIdx(:,end:-1:1),'rows');
% B contains the unique rows of keyIdx
% J has the index of B in the order of keyIdx (i.e., group id for rows of keyIdx)
% i.e., B(J,:) equals keyIdx

% If rows contain any NaN or empty strings, B(1,:) equals 0
% remove those rows, and make those indices of J to contain 0's
if not(all(goodRows))
    B(1,:) = [];
    I(1,:) = [];
    J      = J - 1;
end
% Check whether B is now empty
if isempty(B)
    dataIndex = {};
    sparseIdx = {};
    warning('ccbr:EmptyArray','DataIdx is empty');
    return
end

% Restore column ordering to match field order
% and convert matrix to cell array of columns
cellB = num2cell(B(:,end:-1:1),1);

% Generate 1-dim list of present indices from full n-dim index
presentIdx = sub2ind(sizFullIdx,cellB{:});
% cellB{:} produces a comma separated list
% this use of sub2ind is similar to the command find

% Modify J to hold indices to full n-dim index
J(goodRows) = presentIdx(J(goodRows));

% Sort J into the same order as presentIdx
[ idGroup sortIdxJ ] = sort(J,'ascend');

% Remove rows for which J is 0
sortIdxJ(idGroup==0) = [];
idGroup( idGroup==0) = [];

% Find the size of the blocks in the sorted J
sizGroup = diff(find([1; diff(idGroup); 1])); 

% Convert the index into the unsorted J to a cell array
dataList = mat2cell(sortIdxJ,sizGroup);

% Check whether sparse case
if nargout < 3
    % Initialize index
    dataIndex = cell(prod(sizFullIdx),1);

    % Loop over full dataIndex to fill each cell with matching indices (if any)
    for i = 1:numel(presentIdx)
        dataIndex{presentIdx(i)} = dataList{i};
    end
    % convert output to an N-dimensional cell array
    if isND
        dataIndex = reshape(dataIndex,sizFullIdx);
    end
else
    dataIndex = dataList;
    sparseIdx = B(:,end:-1:1);
end
