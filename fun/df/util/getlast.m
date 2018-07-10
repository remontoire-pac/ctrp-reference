function out = getlast(x)
% GETLAST
%        returns the last element of x, or null if x is empty
%
%     out = getlast(x)
%    
% parameters
%----------------------------------------------------------------
%    "x"    - an array 
% outputs
%----------------------------------------------------------------
%    "out"  - the final element of x
%----------------------------------------------------------------
%
%    Hy Carrinski
%    Broad Institute

if not(isempty(x))
    out = x(end);
else
    out = [];
end
