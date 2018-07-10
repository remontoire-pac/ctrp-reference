function S = DFkeeprow(S,rowIdx,isExclude)
% DFKEEPROW
%         selects rows from a data frame
%
%     S = DFkeeprow(S,idx)
%     S = DFkeeprow(S,idx,isExclude)
%
% parameters
%----------------------------------------------------------------
%    "S"         - a data frame
%    "rowIdx"    - logical index, then row order is maintained,
%                  integer index, then row order can be changed (e.g., sorting)
%    "isExclude" - boolean (default=false) whether rowIdx is indices to exclude
% output
%----------------------------------------------------------------
%    "S"         - a structure of arrays
%----------------------------------------------------------------
%
%     Hy Carrinski
%     Broad Institute
%     Based on selectrows

if nargin < 3 || isempty(isExclude)
    isExclude = false;
end

fields = fieldnames(S);

if not(isExclude)
    for i = 1:numel(fields)
        S.(fields{i}) = S.(fields{i})(rowIdx);
    end
else
    for i = 1:numel(fields)
        wholeIdx         = true(numel(S.(fields{i})),1);
        wholeIdx(rowIdx) = false;
        S.(fields{i})    = S.(fields{i})(wholeIdx);
    end
end
