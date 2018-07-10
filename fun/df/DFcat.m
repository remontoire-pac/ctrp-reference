function S = DFcat(S,varargin)
% DFCAT
%     S = DFcat(S,Sadd,isCheck)
%     S = DFcat(S,Sadd1,Sadd2,Sadd3,...,Saddk)
%
%     Concatenates rows of one data frame onto another data frame
%
% parameters
%----------------------------------------------------------------
%    "S"       -  DF, possibly empty (e.g., "struct([])"), to which to append rows
%    "Sadd"    -  DF containing rows to append
%    "isCheck" -  boolean (default = true) to confirm integrity of Sadd (deprecated)
% outputs
%----------------------------------------------------------------
%    "S"       -  DF including all rows from inputs
%----------------------------------------------------------------
% 
% Concatenates rows from DF Sadd onto DF S
% Hy Carrinski
% Broad Institute
% Based on catStruct 02 Apr 2007

if not(isstruct(S))
   error('ccbr:BadInput','bad inputs for DFcat');
end

if nargin < 2
    warning('ccbr:BadInput','DFcat expects 2 inputs, returning original data frame');
    return
end

numToCat = numel(varargin);
isAllStruct  = cellfun(@isstruct,varargin);
if (numToCat > 1) && not(isAllStruct(2))
    isAllStruct(2) = [];
    varargin{2}    = [];
    numToCat         = numToCat - 1;
end

if not(all(isAllStruct)) 
   error('ccbr:BadInput','bad inputs for DFcat');
end

if (numToCat == 1)
   S = DFsinglecat(S,varargin{1});
else
   S = DFmultcat(S,varargin);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function S = DFsinglecat(S,Sadd)
% Concatenates rows from DF Sadd onto DF S

    if isempty(Sadd)
        return
    elseif isempty(S)
        S = Sadd;
        return
    end

    fields1 = fieldnames(S);
    fields2 = fieldnames(Sadd);

    if not(isequal( numel(fields1),numel(fields2) )) || ...
       not(all( ismember(fields1,fields2) ))
       error('Fields between S and Sadd must match');
    end

    % Ensure that each column is 1D and has an equal number of rows
    isOkay = DFverify(Sadd,true);
    if isOkay < 1
        error('ccbr:NotDF','Each field must be an equal length column vector');
    end
    % passed QC

    % Perform concatenation
    for i = 1:numel(fields1)
       currFld = fields1{i};
       S.(currFld) = cat(1,S.(currFld),Sadd.(currFld));
    end    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function S = DFmultcat(S,CellSadd)
% Concatenates rows from cell array of DF CellSadd onto DF S

    % Verify inputs and identify empty data frames (zero rows)
    [ isOkayS numRowS ] = DFverify(S,true);
    for i = numel(CellSadd):-1:1
        [isOkaySadd(i) numRowSadd(i) ] = DFverify(CellSadd{i},true);
    end
    % Ensure that each column is 1D and has an equal number of rows
    if isOkayS < 1 || any(isOkaySadd < 1)
        error('ccbr:NotDF','Each field must be an equal length column vector');
    end
    % passed initial QC

    % handle empty CellSadd elements
    if any(numRowSadd == 0)
        if all(numRowSadd == 0)
           return;
        end
        CellSadd(  numRowSadd == 0) = [];
        numRowSadd(numRowSadd == 0) = [];
    end
    
    % handle empty S
    if (numRowS == 0)
       S             = CellSadd{1};
       numRowS       = numRowSadd(1);
       CellSadd(1)   = [];
       numRowSadd(1) = [];
    end

    % All empty data frames have been removed
    numToCat = numel(CellSadd);
    fieldS   = fieldnames(S);
    for i = numToCat:-1:1
        fieldSadd{i} = fieldnames(CellSadd{i});
        if not(isequal( numel(fieldS),numel(fieldSadd{i}) )) || ...
            not(all( ismember(fieldS,fieldSadd{i}) ))
            error('ccbr:BadInput', ...
            'Concatenation only among data frames with matching fields');
        end
    end
    % passed final QC

    % Perform concatenation
    for i = 1:numel(fieldS)
        holder      = cell(numToCat,1);
        currFld     = fieldS{i};
        for j = 1:numToCat
            holder{j} = CellSadd{j}.(currFld);
        end
        S.(currFld) = cat(1,S.(currFld),holder{:});
    end    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
