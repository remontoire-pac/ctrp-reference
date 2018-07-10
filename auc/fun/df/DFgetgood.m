function [S numRows] = DFgetgood(S);
% DFGETGOOD
%        DFgetgood loads and qc's a file
%
%    [Data numRows] = DFgetgood(filepath)
%
% parameters
%----------------------------------------------------------------
%    "filepath" - path to a file (string) or structure representing file
% outputs
%----------------------------------------------------------------
%    "Data"     - a data frame 
%    "numRows"  - double number of rows in structure.
%----------------------------------------------------------------
%
%    Hy Carrinski
%    Broad Institute
%    Based on getcqdfile 16 July  2009

switch class(S)
   case 'char'
        filepath = S;
        S = DFread(filepath);
   case 'cell'
        filepath = S{1};
        S = DFread(filepath);
   case 'struct'
        filepath = 'First input';
   otherwise
        error('input to getqcdfile is not of an acceptable class');
end
[ isOkay numRows] = DFverify(S,true);
if isOkay < 1
    error('ccbr:BadInput',[filepath ' is not tab-delimited text (failed QC)']);
end
