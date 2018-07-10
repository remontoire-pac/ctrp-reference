function [SNew errmsg] = DFtostruct(S,isReverse)
% DFTOSTRUCT
%       Converts a data frame to an array of structures
%
%    [SNew errmsg] = DFtostruct(S,isReverse)
% parameters
% ----------------------------------------------------------------
%    "S"         -  a DF or a structure array
%    "isReverse" -  boolean (default=false) whether struct to DF
% output
% ----------------------------------------------------------------
%    "SNew"      -  a structure array or a DF depending on "isReverse"
%    "errmsg"    -  error message
% ----------------------------------------------------------------
% 
%    Hy Carrinski
%    Broad Institute
%    Based on structConvert 28 June 2006

fields = fieldnames(S);

% default (=false) outputs a structure of cell arrays
if nargin < 2
    isReverse = false;
end

%try
    if not(isReverse)
        % DF --> array of structures
        [isOkay numRows] = DFverify(S);
        % initialize output structure
        SNew(numRows) = struct(fields{1},[]);    
        for i = 2:numel(fields)
            currFld = fields{i};
            SNew(numRows).(currFld) = [];
        end
        % populate fields
        for i = 1:numRows
            for j = 1:numel(fields)
                currFld = fields{j};
                SNew(i).(currFld) = S.(currFld)(i);
            end
        end
        numRowsNew = numel(SNew);
    else
        % array of structures --> DF
        if numel(S) < 2
            error('Input must be a structure array with greater than one element');
        end
        numRows = numel(S);
        % initialize output structure
        SNew = struct([]);    
        for i = 1:numel(fields)
            currFld = fields{i};
            SNew(1).(currFld) = vertcat(S.(currFld)); 
        end
        [isOkayNew numRowsNew] = DFverify(SNew);
    end
    if not(isequal(numRows,numRowsNew))
       errmsg = sprintf(['Could not convert S: S had %g rows and SNew ' ...
                'had %g rows'], numRows, numRowsNew);
     
       error('ccbr:BadInput',errmsg);
    end
    errmsg ='';
%catch
%    SNew = S;
%    errmsg = sprintf('Structure unchanged');
%end
