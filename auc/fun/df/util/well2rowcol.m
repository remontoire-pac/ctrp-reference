function [r c] = well2rowcol(w,isCellOutput)
%  WELL2ROWCOL
%       convert cell array of wells to cell array of Rows and vector of Cols
%
%    [r c] = well2rowcol(w,isCellOutput)
%     
% parameters
%----------------------------------------------------------------
%    "w"            - an nx1 cell array of strings representing wells 
%    "isCellOutput" - rows are output as vectors of characters (default = false)
%                     or as a cell array of strings (true)
% outputs
%----------------------------------------------------------------
%    "r" - an nx1 matrix of chars (or cell array of strings) representing rows 
%    "c" - an nx1 vector of doubles representing columns
%----------------------------------------------------------------
%
%    Hy Carrinski
%    Broad Institute

% QC inputs
if nargin < 2 || isempty(isCellOutput)
    isCellOutput = false;
end

% Convert rows
if isCellOutput == false
    r = cellfun(@(x) x(1), w);
else
    r = cellfun(@(x) x(1), w, 'UniformOutput', false);
end

% Convert columns
c = cellfun(@(x) sscanf(x(2:end),'%d'),w);
