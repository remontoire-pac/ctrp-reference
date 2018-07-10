function [M header] = DFtomat(S)
% DFTOMAT
%       Converts a dataframe with m fields, each of which is nx1,
%       into a nxm matrix M and mx1 cell array of strings
%
%    [M Header] = DFtomat(S)
%
% parameters
% ----------------------------------------------------------------
%    "S"      - a data frame
% output
% ----------------------------------------------------------------
%    "M"      - a matrix of type numeric or logical
%    "header" - a cell array of strings (column headers)
% ----------------------------------------------------------------
%
%    Hy Carrinski
%    Broad Institute

% QC
[isNum numRows] = DFisnum(S);
assert(isNum==true,'ccbr:BadInput', ...
    'DFtomat requires a data frame of numeric or logical arrays as input');

% Generate header
header = fieldnames(S);
M      = nan( numRows, numel(header) );
for i = 1:numel(header)
    M(:,i) = S.(header{i});
end
