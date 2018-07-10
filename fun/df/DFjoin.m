function [S1 unJoinedIdx1 unJoinedIdx2] = ...
            DFjoin(file1,file2,joinOnNames,keepNames,newNames,joinWhich,inclNaNEmpty)
% DFJOIN
%         joins one file on a another file
%
%    [JoinedFile unJoinedIdx1 unJoinedIdx2] = ...
%         DFjoin(file1,file2,joinOnNames,keepNames,newNames,joinWhich,inclNaNEmpty)
%
% parameters
%----------------------------------------------------------------
%    "file1"        - filename or structure representing file to which to join 
%    "file2"        - filename or structure representing file to join 
%    "joinOnNames"  - cell array of properties (strings) on which to perform join
%    "keepNames"    - cell array of properties from file2 to keep.
%                     Specific cases:
%                     {} or {''}  --> keep no property from file2
%                     []          --> keep all properties from file2
%    "newNames"     - cell array of new names for properties in keepNames
%                     {} or {''} or [] --> rename no properties from file2
%    "joinWhich"    - string containing "first", "last", "all", "empty" or "" (default)
%                     join "all" option generates additional rows and REMOVES
%                     unjoined rows
%    "inclNaNEmpty" - boolean whether to ignore NaNs and empty strings (default=false)
%                     or to set all NaNs equal and all empty strings equal (true)
% outputs
%----------------------------------------------------------------
%    "JoinedFile"   - a 1x1 structure with fields is nx1 double, int or cell
%    "unJoinedIdx1" - vector of indices from file1 which were not joined
%    "unJoinedIdx2" - vector of indices from file2 which were not joined
%----------------------------------------------------------------
%    Notes:
%       Does not join any column from file2 which is present is file1,
%       (unless it is renamed via newNames)
%
%    Hy Carrinski
%    Broad Institute
%    Based on fJoin_v2 27 June  2007
%    Requires DFread DFindex DFgetgood makevert notindex

% Check input arguments and generate structures S1 and S2

[S1 numRows         ] = DFgetgood(file1);
[S2 numRowsJoinFile ] = DFgetgood(file2);
clear file1 file2;

fields1 = fieldnames(S1);
fields2 = fieldnames(S2);

if nargin < 4 || not(iscell(keepNames)) % note: {} is valid
    keepNames = fields2;
end
if nargin < 5 || not(iscell(newNames)) || ...
    isequal(newNames,{}) || isequal(newNames,{''})
    newNames = keepNames;
end
if nargin < 6 || isempty(joinWhich)     % note: {} is valid
    joinWhich = '';
end
if nargin < 7 || isempty(inclNaNEmpty)
    inclNaNEmpty = false;
end

if not(isequal( numel(newNames), numel(unique(newNames)) ))
    warning('ccbr:BadInput', ...
        'New field names must be unique. Joining only unique names');
    newNames = unique(newNames);
end
if not(isequal( numel(newNames), numel(keepNames) ))
    error('ccbr:BadInput', ...
        'Number of columns to keep and to rename must be the same');
end

% Ensure that joinOnNames present in both files
if any(not(ismember(joinOnNames,fields1))) || ...
   any(not(ismember(joinOnNames,fields2)))
   error('ccbr:BadInput','Names to join missing from file1 or file2');
end

numDim   = numel(joinOnNames);
typeData = cell(numDim,1);
isNum    = true(numDim,1);
useAll   = false;           % initialized here, may be modified below

% Check formats of columns to join
for i = 1:numDim
    typeData{i} = class(S1.(joinOnNames{i})); 
    if ~strcmp(typeData{i},class(S2.(joinOnNames{i}))); %
        error('ccbr:BadInput','Data types must match between file1 and file2');
    end
    if strcmp(typeData{i},'cell')
        isNum(i) = false;
    elseif not(strcmp(typeData{i},'double'))
        error('ccbr:BadInput',['Data type ' typeData{i} ' is not supported for joins']);
    end
end

% QC the field names from
% fields1, fields2, joinOnNames, keepNames, newNames
% New structure has fields: fields1 + newNames
badNameIdx = ismember(newNames,fields1);
if any(badNameIdx)
   warning('ccbr:IncompleteJoin',['Cannot join new field names which already exist in file1: ' ...
             cell2delim(newNames(badNameIdx))]);
end

% Actually remove those names so they are not joined
newNames( badNameIdx) = [];
keepNames(badNameIdx) = [];

missNameIdx = not(ismember(keepNames,fields2));
if any(not(ismember(keepNames,fields2)))
   warning('ccbr:IncompleteJoin',['Cannot not join field names missing from file2: ' ...
             cell2delim(fields2(missNameIdx))]);
end

% Build index for first file, then use those values to index second file
[idxS1 NamesS1 spIdxS1] = DFindex(S1,joinOnNames,[],[],[],inclNaNEmpty);
[idxS2 NamesS2 spIdxS2] = DFindex(S2,joinOnNames,[],NamesS1,[],inclNaNEmpty);

if isempty(idxS2)
    % This conditional added for sparse implementation
    warning('ccbr:BadJoin','Joined failed because join files share zero matching indices');
    unJoinedIdx1 = notindex(fromS1,numRows); %commented at bottom
    unJoinedIdx2 = notindex(fromS2,numRowsJoinFile);
    return
end

if any(makevert( cellfun('prodofsize',idxS2) > 1 ))
   switch lower(joinWhich)
     case {'','empty'}
       error('Join file has redundant indexing');
     case 'first'
       idxS2 = cellfun(@getfirst, idxS2, 'UniformOutput',false);
     case 'last'
       idxS2 = cellfun(@getlast,  idxS2, 'UniformOutput',false);
     case 'all'
       useAll = true;
     otherwise
       error('ccbr:BadInput', ...
             'joinWhich allows values: "first", "last", "all" or "empty"');
   end
end


% Remove unused coordinates

% Sparse implementation
[matchedRows matchIdxS1 matchIdxS2] = intersect(spIdxS1,spIdxS2,'rows');
idxS1 = idxS1(matchIdxS1);
idxS2 = idxS2(matchIdxS2);

% Copy elements of idxS2 to line up with idxS1
idxS2Rep = cellfun(@(x,y) repmat(y,numel(x),1), ...
           idxS1, idxS2, 'UniformOutput', false);

% join "all" case is new
if useAll
   idxS1Rep = cellfun(@(x,y) makevert(repmat(x',numel(y),1)), ...
              idxS1, idxS2, 'UniformOutput', false);
else
   idxS1Rep = idxS1;
end

% Generate commensurate join indices
fromS1 = makevert(idxS1Rep{:});
fromS2 = makevert(idxS2Rep{:});

% Check join indices
if not(isequal( numel(fromS1), numel(fromS2) ))
    error('Join indices differ in number of elements');
end

if useAll
    % For each field in S2 which is not in S1, the values are added
    % for rows in the join index. Rows in S1 which are not in the join
    % index are removed and rows for which more than one row from S2
    % match a single row in S1, the rows in S1 are replicated
    % this is a whole new algorithm for join "all" case
    % this new method may have very poor memory management
    S1 = DFkeeprow(S1,fromS1);
    S2 = DFkeeprow(DFkeepcol(S2,keepNames),fromS2);
    for i = 1:numel(newNames)
        currFld = newNames{i};
        S1.(currFld) = S2.(keepNames{i});
    end
else
    % For each field in S2 which is not in S1, the values are added
    % for rows in the join index. Rows in S1 which are not in the join
    % index are left blank (NaN for double and {''} for cell) 
    for i = 1:numel(newNames)
        currFld = newNames{i};
        switch class(S2.(keepNames{i}))
            case 'double'
                S1.(currFld) = nan(numRows,1);
            case 'cell'
                S1.(currFld) = repmat({''},numRows,1);
            otherwise
                error('ccbr:BadInput',['Data type ' class(S2.(keepNames{i})) ...
                    ' is not supported for joins']);
                return
        end
        if not(any( isempty(S2.(keepNames{i})(fromS2)) ))
            S1.(currFld)(fromS1) = S2.(keepNames{i})(fromS2);
        else
            error('ccbr:BadInput','File not joined');
        end
    end
end

if nargout > 1
    % Keep track of unjoined rows from S1
    unJoinedIdx1     = notindex(fromS1,numRows);
    if nargout > 2
        % Keep track of unjoined rows from S2
        unJoinedIdx2 = notindex(fromS2,numRowsJoinFile);
    end
end
