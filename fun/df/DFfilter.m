function [S1 passIdx failIdx ] = DFfilter(S1,file2,filtNames,matchNames)
% DFFILTER
%    [FilteredFile passIdx failIdx ] = DFfilter(file1,file2,filtNames,matchNames)
%
%     DFfilter filters contents of one file based on matching unique rows
%     of another file
%
% parameters
%----------------------------------------------------------------
%    "file1"     - data frame representing file of N rows (or filename)
%    "file2"     - date frame representing file by which to filter (or filename) 
%    "filtNames" - cell array of properties (strings) on which to filter
%    "matchNames"- cell array of properties in file2 corresponding to filtNames
%
% outputs
%----------------------------------------------------------------
%    "FilteredFile" - a 1x1 structure with fields of px1 double, int or cell
%    "passIdx"      - set of p indices from file1 which passed the filter
%    "failIdx"      - set of f indices from file1 which failed the filter
%                     N = p + f
%----------------------------------------------------------------
%
%     Created  15 July  2009
%     Based on DFjoin.m
%     Hy Carrinski
%     Broad Institute
%     Requires DFjoin DFkeeprow DFrenamecol DFgetgood and notindex

% Check input arguments and generate structures S1 and S2
[ S1 numRows ]          = DFgetgood(S1);

% load second file
if not( isempty(file2) )
    [ S2  numFiltRows ] = DFgetgood(file2);
end

% In the case of empty file2, just return S1
if isempty(file2) || ( numFiltRows == 0 )
    passIdx = num2colidx(numRows);
    failIdx = [];
    return;
end
clear file1 file2;

% rename columns in the filter file to match 
if nargin >= 4 && iscellstr(matchNames)
   S2          = DFrenamecol(S2,matchNames,filtNames);
end

% This next line could be more efficient it S2 could be indexed first
[ S1 failIdx ] = DFjoin(S1,S2,filtNames,{},[],'first');
  S1           = DFkeeprow(S1,failIdx,true);

if nargout > 1
    passIdx    = notindex(failIdx,numRows);
end
