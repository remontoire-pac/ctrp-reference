function w = rowcol2well(r,c,isCellOutput);
%    ROWCOL2WELL
%       Convert arrays of rows and columns to array of wells
%
%    w = rowcol2well(r,c,isCellOutput);
%
% parameters
%----------------------------------------------------------------
%    "r" - an nx1 matrix of chars (or cell array of strings) representing rows 
%    "c" - an nx1 vector of doubles representing columns
%    "isCellOutput" - wells are output as a cell array of strings (default = true)
%                     or as a matrix of chars (false)
% outputs
%----------------------------------------------------------------
%    "w"            - an nx1 cell array of strings (or nx3 array of chars)
%                     representing wells 
%----------------------------------------------------------------
%
%    Hy Carrinski
%    Broad Institute

% QC inputs
if nargin < 3 || isempty(isCellOutput)
    isCellOutput = true;
end

% convert rows to char matrix
if iscell(r)
    r = cell2mat(r);
end

% account for rare case of columns being in a cell array
if iscell(c)
    c = cell2mat(c);
end

% convert columns to char matrix
c = num2str(c);

% replace white space with zeros
c(c==' ') = '0';

% concatenate rows and columns
w = [r c];

% by default, convert to cell array of strings
if isCellOutput == true
    w = mat2cell(w,ones(size(w,1),1));
end
