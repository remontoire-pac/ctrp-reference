function S = DFkeepcol(S,fields)
% DFRMCOL
%         removes columns from a data frame (a.k.a., fields)
%
%     S = DFrmcol(S,fields)
%
% parameters
%----------------------------------------------------------------
%     "S"         - a data frame
%     "fields"    - a cell array of field names
% output
%----------------------------------------------------------------
%     "S"         - a data frame
%----------------------------------------------------------------
%
%     Hy Carrinski
%     Broad Institute
%     Based on rmfield 


% Error check
if ~isa(S,'struct') 
    error('ccbr:BadInput', 'S must be a data frame.'); 
end
if ischar(fields)
   fields = cellstr(fields); 
elseif not(iscellstr(fields))
   error('ccbr:BadInput',...
      'FIELDNAMES must be a string or a cell array of strings.');
end

% do the action
S = rmfield(S,fields);
