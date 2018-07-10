function Vals = DFvalues(S,inclNaNEmpty)
% DFVALUES
%
%         Returns structure with field names matching input data frame,
%         but containing only unique (non-empty) values for each field
%
%     Vals = DFvalues(S)
%
% parameters
% ----------------------------------------------------------------
%    "S"            - a data frame
%    "inclNaNEmpty" - boolean whether to ignore NaNs and empty strings (default=0)
%                     or to set all NaNs equal and all empty strings equal (=1)
% output
% ----------------------------------------------------------------
%    "Values"    - a structure containing field names identical to "S"
%                  but containing unique values from Data.(fieldname)
%                  in ascending order
% ----------------------------------------------------------------
% 
%   Hy Carrinski
%   Broad Institute

if nargin < 2 || isempty(inclNaNEmpty)
   inclNaNEmpty = false;
end

Vals = structfun(@(x) uniquenotmiss(x,inclNaNEmpty),S,'UniformOutput',false);
