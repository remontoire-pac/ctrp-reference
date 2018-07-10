function S = DFrenamecol(S,oldfields,newfields)
% DFRENAMECOL
%          rename columns in a data frame (a.k.a., fields)
%
%     S = DFrenamecol(S,oldfields,newfields)
%
% parameters
%----------------------------------------------------------------
%     "S"         - a data frame
%     "oldfields" - a cell array of field names to rename
%     "newfields" - a cell array containing the new names
% output
%----------------------------------------------------------------
%     "S"         - a data frame
%----------------------------------------------------------------
%
%     Note: members of oldfields that are missing from S are
%           simply ignored
%
%     Hy Carrinski
%     Broad Institute
%     Based on renameField November 12, 2008

% Error check
if ~isa(S,'struct') 
    error('ccbr:BadInput', 'S must be a data frame.'); 
end
if ischar(oldfields)
   oldfields = cellstr(oldfields); 
elseif not(iscellstr(oldfields))
   error('ccbr:BadInput',...
      'FIELDNAMES must be a string or a cell array of strings.');
end
if ischar(newfields)
   newfields = cellstr(newfields); 
elseif not(iscellstr(newfields))
   error('ccbr:BadInput',...
      'FIELDNAMES must be a string or a cell array of strings.');
end

% permit inclusive rename list (absent fields are ignored)
allfields = fieldnames(S);
idxMissingFields = not(ismember(oldfields,allfields));
if nnz(idxMissingFields) > 0
    oldfields(idxMissingFields) = [];
    newfields(idxMissingFields) = [];
    warning('ccbr:ImperfectInput', ...
        'Certain fields were not renamed, structure changed');
end

% ignore any field that is present in the same position of both lists
if any(strcmp(oldfields,newfields))
    idxIdentical            = find(strcmp(oldfields,newfields));
    oldfields(idxIdentical) = [];
    newfields(idxIdentical) = [];
end

% Ensure old fields and new fields have the same number of members
numOld = numel(oldfields);
numNew = numel(newfields);
if not(isequal(numOld,numNew))
   error('ccbr:BadInput',...
       'oldfields and newfields must have the same number of elements');
end

% further checking for unhandled cases
if any(not(ismember(oldfields,allfields))) || ...
   any(    ismember(allfields,newfields))  || ...
   any(    ismember(oldfields,newfields))  || ...
   not(isequal( numel(unique(oldfields)), numOld )) || ...
   not(isequal( numel(unique(newfields)), numNew ))
    warning('ccbr:BadInput', ...
        'Fields could not be properly renamed, structure unchanged');
    return
end

% rename fields
for i = 1:numel(newfields)
   S.(newfields{i}) = S.(oldfields{i});
   S = rmfield(S,oldfields{i});
end
