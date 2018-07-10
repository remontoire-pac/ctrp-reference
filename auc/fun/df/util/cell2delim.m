function str = cell2delim(c,delim)
% CELL2DELIM
%        converts a cell array of strings to a delimited string
%
%    str = cell2delim(c,delim)
%
% parameters
%----------------------------------------------------------------
%    "c"        - an array of cells containing strings or numbers
%    "delim"    - a multi character delimiter or printf string to
%                 use as a delimiter (default is a single space).
%                 Delimiter will be directly copied to output,
%                 and NOT converted using sprintf
% outputs
%----------------------------------------------------------------
%    "str"      - a char row vector with the elements of "c" delimited by
%                 "delim", and without any trailing delimiter
%----------------------------------------------------------------
%
%    Hy Carrinski
%    Broad Institute
%    Created  16 July  2009

if nargin < 2
    delim = ' ';
end

if iscellstr(c) && ischar(delim)
   c        = vertcat(transpose(c(:)),repmat({delim},1,numel(c)));
   str      = [ c{:} ];
   str((end-numel(delim)+1):end) = [];
else
   error('ccbr:BadInput','cell2delim works on cell arrays of strings');
end
