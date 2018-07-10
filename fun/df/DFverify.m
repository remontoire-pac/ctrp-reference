function [isComplete numRows] = DFverify(S,isColumnar,checkType)
% DFVERIFY
%       test whether a structure contains fields of identical sizes
%
%    [isComplete numRows] = DFverify(S,isColumnar,checkType)
% parameters
% ----------------------------------------------------------------
%    "S"          - a 1x1 structure of arrays of any type
%    "isColumnar" - optional boolean to require fields to be column
%                   vectors (default = false)
%    "checkType"  - optional boolean to require fields to be of
%                   supported classes which includes: any numeric
%                   type, logical and cellstr (default = false)
% output
% ----------------------------------------------------------------
%    "isComplete" - values: 1 if all fields are the same size [and columnar]
%                           0 if one or more fields is a different size
%                          -1 if one or more fields is not a column vector,
%                             but all fields are the same size
%                          -2 if there is a field of an unsupported type
%    "numRows"    - number of rows in structure
%                   maximum dimension of array in 1st field of structure
% ----------------------------------------------------------------
%    Useful for verifying input read from or written to delimited text files
%    A DF which is an empty structure returns isComplete = 1 and numRows = 0
% 
%    Hy Carrinski
%    Broad Institute
%    Based on qcRows 2008 March 24

if nargin < 2 || isempty(isColumnar)
    isColumnar = false;
end
if not(isstruct(S)) || numel(S) > 1 
    error('ccbr:BadInput','Input must be a DF (1x1 structure of arrays)');
end
if nargin < 3 || isempty(checkType)
    checkType = false;
end

% Argument checking complete
isComplete = 1;
if isempty(S)
    numRows = 0;
    return
end
flds       = fieldnames(S);
size1st    = size(S.(flds{1}));
for n = 1:numel(flds)
    sizeNth = size(S.(flds{n}));
    if not(checkType) || islogical(S.(flds{n})) || ...
        isnumeric(S.(flds{n})) || iscellstr(S.(flds{n})) 
        if isequal(size1st,sizeNth)                 % same size
            if not(isColumnar) || ...
               isequal( size1st(1), prod(sizeNth) )
                continue;     % success
            else
                isComplete = -1;
            end
        else
            isComplete = 0;
        end
    else
        isComplete = -2;
    end
    numRows = nan;
    return
end
numRows = max(size1st);
