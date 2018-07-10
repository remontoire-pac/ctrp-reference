function idWell = well2id(w,numWells)
%  WELL2ID
%       convert cell array of wells to array id's
%
%    idWell = well2id(w,numWells)
%     
% parameters
%----------------------------------------------------------------
%    "w"            - an nx1 cell array of strings representing wells 
%    "numWells"     - number of wells on a plate (default is 384)
% outputs
%----------------------------------------------------------------
%    "idWell" - an nx1 vector of doubles representing wells
%----------------------------------------------------------------
%    Index is by rows FIRST and then by columns
%
%    Hy Carrinski
%    Broad Institute
%    Based on well2rowcol.m

if nargin < 2
    numWells = 384;
end

if numWells == 384
    sizPlate = [16 24];
elseif numWells == 96
    sizPlate = [8 12];
else
    error('Sorry only plate sizes 96 and 384 currently supported');
end

% Convert rows
r = cellfun(@(x) x(1), w);

rowNames = repmat('ABCDEFGHIJKLMNOP',numel(r),1);
rows     = repmat(r,1,16);
[rowVal J]    = find(transpose(rowNames==rows));

% Convert columns
c = cellfun(@(x) sscanf(x(2:end),'%d'),w);
idWell = sizPlate(2)*(rowVal-1) + c;


