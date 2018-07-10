function [isNum numRows] = DFisnum(S)
% DFISNUM
%        Test whether input is a DF with fields of type numeric or logical
%
%     [isNum numRows] = DFisnum(S)
% parameters
% ----------------------------------------------------------------
%    "S"        - a 1x1 structure of arrays of any type
% output
% ----------------------------------------------------------------
%    "isNum"    - boolean, true only when all fields are Nx1
%                 and of type numeric or logical
%    "numRows"  - number of rows in structure (NaN when isNum is false)
% ----------------------------------------------------------------
% 
%   Hy Carrinski
%   Broad Institute

isNum   = true;
flds    = fieldnames(S);
size1st = size(S.(flds{1}));
for n = 1:numel(flds)
    sizeNth = size(S.(flds{n}));
    if isequal(size1st     ,sizeNth )      && ...          % same size
       isequal(max(size1st),prod(sizeNth)) && ...          % vector
       isequal(max(size1st),size1st(1))    && ...          % column vector
       (isnumeric(S.(flds{n})) || islogical(S.(flds{n})) ) % numeric or logical
        continue;
    else
        isNum = false;
        numRows = nan;
        return
    end
end
numRows = max(size1st);
