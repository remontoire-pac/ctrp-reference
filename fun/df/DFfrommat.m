function S = DFfrommat(M,header)
% DFFROMMAT
%    Converts a nxm matrix M and mx1 cell array header of strings
%    to a 1x1 structure S of m fields called each of which is nx1
%
%    S = DFfrommat(M,header)
%
% parameters
% ----------------------------------------------------------------
%    "M"      - a matrix of type numeric or logical
%    "header" - a cell array of strings of column headers
% output
% ----------------------------------------------------------------
%    "S"      - a 1x1 structure of arrays of any type
% ----------------------------------------------------------------
%
%    Hy Carrinski
%    Broad Institute
%    Created 05Mar2008

% QC
[n m] = size(M);
if m ~= numel(header) || ~iscellstr(header)
   error('ccbr:BadInput', ...
       'DFfrommat requires a matrix and a cell array of strings as input');
end

% Generate structure
for i = 1:numel(header)
    S.(header{i}) = M(:,i);
end

