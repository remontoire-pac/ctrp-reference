function out = getfirst(x)
% GETFIRST
%       returns the first element of x, or null if x is empty
%
%    out = getfirst(x)
%    
% parameters
%----------------------------------------------------------------
%    "x"        - an array 
% outputs
%----------------------------------------------------------------
%    "out"      - the first element of x
%----------------------------------------------------------------
%
%    Hy Carrinski
%    Broad Institute

if not(isempty(x))
    out = x(1);
else
    out = [];
end
