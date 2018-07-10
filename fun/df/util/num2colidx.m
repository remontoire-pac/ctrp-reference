function colIdx  = num2colIdx(num)
% NUM2COLIDX
%       generates the index from 1 to num as a column vector
%
%    colIdx  = num2colIdx(num)
%
% parameters
% ----------------------------------------------------------------
%    "num"    - scalar number
% outputs
% ----------------------------------------------------------------
%    "colIdx" - a column vector containing the indices from 1 to num
% ----------------------------------------------------------------
%
%    Hy Carrinski
%    Broad Institute
%    07 Feb 2009

colIdx = (1:num)';
