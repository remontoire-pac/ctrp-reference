function S = DFunmerge(S,fields,delim)
% DFUNMERGE
%        unmerges rows from a structure
%
%     SNew = DFunmerge(S,fields,delimiter)
%
% parameters
%----------------------------------------------------------------
%    "S"         - a data frame
%    "fields"    - a cell array of field names in "S" to use to unmerge
%    "delimiter" - a string to be used as a delimiter (default=';')
%
% outputs
%----------------------------------------------------------------
%    "SNew"       - a data frame with multiple rows corresponding to each
%                   unmerged row
%----------------------------------------------------------------
%     Hy Carrinski
%     Broad Institute
%     Depends on enumitems.m

if nargin < 2 || not(isstruct(S)) || not( iscellstr(fields) || ischar(fields) )
    error('ccbr:BadInput','Please check inputs for DFunmerge');
elseif nargin < 3 || not(ischar(delim))
    delim = ';';
end

if ischar(fields)
    fields = cellstr(fields); 
end

allFields = fieldnames(S);
if any(not(ismember(fields,allFields)))
  error('All fields for ummerging must exist in input data frame');
end

% Ensure that each column is 1D and has an equal number of rows
[isDataOkay numRows] = DFverify(S,true);
if isDataOkay < 1
    error('ccbr:BadInput','Fields in S must be arrays of size N x 1');
end
if (numRows == 0)
    return
end

% Generate a cell array such that each row corresponds to
% a row from the input structure, each column corresponds to
% a field which is being unmerged, and in each cell is a cell
% array of strings which have been split by a delimiter 

parsedStr = cell(numRows,numel(fields));
for i = 1:numel(fields)
    parsedStr(:,i)  = cellfun(@(x) strsplithy(delim,x), ...
                      S.(fields{i}),'UniformOutput',false);
end

% partition the structure into the part which is
% already completely unmerged, and the part
% which requires unmerging (is reduntly indexed).

numWords    = cellfun(@numel,parsedStr);
rowsRedund  = find(all(numWords > 1, 2));
SRedund     = DFkeeprow(S,rowsRedund);
isExclude   = true;
S           = DFkeeprow(S,rowsRedund,isExclude);

% count the number of rows which much be unmerged
% and initialize a structure to how this output
numChgdRows = sum(prod(numWords(rowsRedund,:),2));
Sadd        = DFkeeprow(S,ones(numChgdRows,1));

% perform the unmerging operation
parsedStr  = parsedStr(rowsRedund,:);
numWords   = numWords(rowsRedund,:);
currIdx                  = 1;
for i = 1:nnz(rowsRedund)
    numCurrRows = prod(numWords(i,:));
    insertIdx   = makevert( currIdx:(currIdx+numCurrRows-1) );
    SRow        = DFunmergerow(DFkeeprow(SRedund,i),fields,parsedStr(i,:));
    Sadd        = DFinsertrow(Sadd,SRow,insertIdx);
    currIdx     = currIdx + numCurrRows;
end

% Tack unmerge rows onto the end of rows not requiring unmerging
S = DFcat(S,Sadd);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function S = DFinsertrow(S,Sadd,Idx)
    allFields = fieldnames(S);
    for i = 1:numel(allFields)
        S.(allFields{i})(Idx,1) = Sadd.(allFields{i});
    end    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function S = DFunmergerow(S,fields,values)
% DFunmergerow
%     SNew = DFunmergerow(S,fields,values)
%
%     Unmerges a row from a structure
%
% parameters
%----------------------------------------------------------------
%     "S"       - a data frame
%     "fields"  - a cell array of field names in "S"
%     "values"  - a cell array of cell arrays of values for fields of S
%
% outputs
%----------------------------------------------------------------
%     "SNew"    - a data frame
%----------------------------------------------------------------
%     Later: will add 4th parameter:
%     isMatched - boolean (default=false) whether values in a row are:
%         true  -  matched across fields (like subscripts)
%              or
%         false -  to be unmerged combinatorially (rows and columns)
%

    numItems  = cellfun(@numel,values);
    S         = DFkeeprow(S,ones(prod(numItems),1));
    cellStore = enumitems(values);
    for i = 1:numel(numItems)
        S.(fields{i}) = cellStore{i}(:);
    end
