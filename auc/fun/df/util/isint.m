function flagTest = isint(inMat)
% ISINT
%        test matrix for containing only integer values of
%        type integer, double, single or logical
%
%    flagTest = isint(inMat)
%
% parameters
%----------------------------------------------------------------
%    "inMat"     - any matrix
% output
%----------------------------------------------------------------
%    "flagTest"  - logical reporting whether matrix passes test
%----------------------------------------------------------------
%Based on isindex

%test for positive integers
if isinteger(inMat)==true     %actual integer data type
    flagTest = true;
elseif islogical(inMat)
    flagTest = true;
elseif isnumeric(inMat) && ...
       isequalwithequalnans(inMat,fix(inMat))  %de-facto integers
    flagTest = true;
else
    flagTest = false;
end
