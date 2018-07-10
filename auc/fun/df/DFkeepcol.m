function S = DFkeepcol(S,fields,isReorder)
% DFKEEPCOL
%         selects columns from a data frame (a.k.a., fields)
%
%     S = DFkeepcol(S,fields)
%     S = DFkeepcol(S,fields,isReorder)
%
% parameters
%----------------------------------------------------------------
%    "S          - a data frame
%    "fields"    - a cell array of field names or a list of column indices
%    "isReorder" - boolean (default=false) whether fields in S are
%                  reordered according to "fields"
% output
%----------------------------------------------------------------
%    "S"         - a data frame
%----------------------------------------------------------------
%
%     Hy Carrinski
%     Broad Institute
%     Based on keepField September 27, 2006

% Error check
if ~isa(S,'struct') 
    error('ccbr:BadInput', 'S must be a data frame.'); 
end
if ischar(fields)
   fields = cellstr(fields); 
elseif isnumeric(fields)
   fldIdx   = fields;
   fields   = fieldnames(S);
   fields   = fields(fldIdx);
elseif not(iscellstr(fields))
   error('ccbr:BadInput',...
      'FIELDNAMES must be a string, a cell array of strings, or an index of columns.');
end
if nargin < 3
    isReorder = false;
end

% get fieldnames of struct
allFields    = fieldnames(S);
removeFields = allFields(not(ismember(allFields,fields)));

% perform a little error checking
absentFields = fields(not(ismember(fields,allFields)));
if not(isempty(absentFields))
    warning('ccbr:BadInput',['The following fields are missing from ' ...
                             'data frame S: ' cell2delim(absentFields)]); 
    if isReorder
        error('ccbr:BadInput',['Re-ordering requires all fields to ' ...
                               'be present in S: structure unchanged']);
    end
end

% do the action
if isReorder
    S = orderfields(rmfield(S,removeFields),fields);
else
    S = rmfield(S,removeFields);
end
