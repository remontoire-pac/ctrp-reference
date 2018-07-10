function idx = notindex(idx,len)
% NOTINDEX
%    notindex generates all indices into a matrix not present in "index" 
%
%       idx = notindex(index,length)
%
% parameters
%----------------------------------------------------------------
%    "index"  - a vector of positive indices or a logical matrix 
%    "length" - the number of elements in the matrix
% outputs
%----------------------------------------------------------------
%    "index"  - a vector of positive indices
%----------------------------------------------------------------
%
%    Hy Carrinski
%    Broad Institute
%    Created  16 July  2009

if isempty(idx)
   idx = num2colidx(len);
elseif islogical(idx) || ...               % binary
       ( isnumeric(idx) && isequal(nnz(idx),nnz(idx==1)) ) 
    if isequal( numel(idx), len)
        idx = find(not(idx));
    else
        error('ccbr:BadInput',[ '"index" is of type logical, '...
                'so it must have "length" elements']);
    end
elseif isnumeric(idx) && ...               % index
       ( max(idx(:)) <= len ) && ...
       ( min(idx(:)) >= 1 ) && ...
       ( isinteger(idx) || isequal(idx,fix(idx)) )
    bits      = true(len,1);
    bits(idx) = false;
    idx       = find(bits);
else
    error('ccbr:BadInput',['"index" is out of range: has values ' ...
           'greater than "length" or less than zero']);
end
