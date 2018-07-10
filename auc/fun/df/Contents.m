% Text Processing Toolbox
% Broad Institute 2009
%
% Essential File I/O
%   DFread    - load a tab delimited text file into a structure of arrays
%   DFwrite   - write a tab delimited text file from a structure of arrays
%   DFkeeprow - make subset of a structure of arrays given row indices
%
% Essential data manipulation
%   DFindex   - generates an index for a structure of arrays for any number of fields
%   DFcat     - concatenates rows from structure of array onto a structure of arrays
%   DFjoin    - performs a join between two files (or structures of arrays)
%   DFkeepcol - keep only listed fields from a structure of arrays
%   DFfrommat - make structure of arrays from a matrix and array of strings
%   DFsort    - sort a structure of arrays based on any number of fields
%   DFtomat   - make a matrix and array of strings from a structure of arrays
%   DFunmerge - Uunmerge rows from a structure
%   DFverify  - test if all arrays in structure of arrays are the same size
%
% Essential Utilities (dependencies)
%   cell2delim    - concatenate a cell array of strings into a delimited char array
%   conv2str      - converts any (non-structure) input to a single string,
%   makevert      - make any dimensional matrix or comma separated list into a column vector
%   strsplithy    - split a string into a cell array based on a single character delimiter
%   uniquenotmiss - find the unique values of a (cell) array (ignore NaN and '', or not, optionally)
%
% Useful functions
%   DFfilter      - filters rows from a structure of arrays
%   DFgetgood     - perform quality control on a data frame or a file path to a tab-text file
%   DFisnum       - determine whether all fields in a data frame have type logical or numeric
%   DFpivot       - pivot a structure of arrays based on values of a field
%   DFrenamecol   - rename fields from a structure of arrays
%   DFrmcol       - remove listed fields from a structure of arrays
%   DFvalues      - structure with fields of unique values from input data frame
%   DFview        - display char matrix representing contents of structure of arrays
%
% Other utilities
%   rowcol2well   - convert arrays of rows and columns to array of wells
%   well2rowcol   - convert cell array of wells to cell array of Rows and vector of Cols
%   getfirst      - returns first element of an array or null
%   getlast       - returns first element of an array or null
%   isint         - true for arrays containing only integer values, regardless of type
%   notindex      - returns list of indices not contained in a list of indices
%   num2colidx    - returns column vector of numbers between one and a given number
%   well2id       - convert cell array of wells to numerical id's in column-major order
%
% Optional functions  
%   DFtostruct    - convert between structure of arrays and array of structures
