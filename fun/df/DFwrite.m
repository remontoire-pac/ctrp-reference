function err = DFwrite(S, filename, filedir, options, isWithNaN)
% DFWRITE
%        write a tab delimited text file
%
%     err = DFwrite(S, filename, filedir, options, isWithNaN)
%
% parameters
%----------------------------------------------------------------
%     "S"         -  a data frame
%     "filename"  -  char array of the filename or path to the file
%     "filedir"   -  char array of the directory containing the file
%     "options"   -  a structure with a printf-style format string per field
%     "isWithNaN" -  boolean to determine whether NaNs are output as
%                    "" (=false) or "NaN" (default=true)
%     "isRobust"  -  boolean (default=false) to determine whether writing
%                    of cell arrays containing other than strings is
%                    permitted. For example, writing cell arrays of
%                    numbers or recursively writing delimited lists of
%                    vectors or vectors of vectors
% outputs
%----------------------------------------------------------------
%     "err"       - a value (0 if file is written without error)
%----------------------------------------------------------------
%     Notes:
%       1. data frame is a 1x1 structure with fields of Nx1 numerical or cell arrays
%       2. The field options.defaultFmt can hold a default format for
%          non-integer numerical formats
%       3. DFwrite never decreases the precision of integers,
%          regardless of data type
%       4. The goal of DFwrite is to write easy files fast, moderate
%          files well and hard files right.
%
%     OPEN QUESTIONS
%     How and whether to accept structures with fields of varying lengths?
%         Currently not permitted
%
%     Hy Carrinski
%     Based on foutput_v2  28 June 2006
%     requires conv2str.m cell2delim.m

%%
% QC inputs
if nargin<2 || isempty(filename)
    error('ccbr:BadInput','filename missing for DFwrite');
end
if nargin<3 || isempty(filedir)
    filedir = '';
elseif ~isempty(filedir) && ...
   not( strcmp(filedir(end),'\') || strcmp(filedir(end),'/') )
   filedir = [filedir filesep];
end
if nargin < 4 || isempty(options)
   options = struct([]);
elseif not(isstruct(options))
   error('ccbr:BadInput',['"options" is required to be ' ...
         'a structure with a format string per field']);
end
if nargin < 5 || isempty(isWithNaN)
   isWithNaN = true;
end
if nargin < 6 || isempty(isRobust)
    isRobust = true; % PAC 20150226
end
% Ensure that structure is ready for writing
[okayToWrite numRows] = DFverify(S,true,true);
if okayToWrite < 1
    switch okayToWrite
      case  0
        error('ccbr:BadInput','all fields of structure must be same size');
      case -1
        error('ccbr:BadInput','all fields of structure must be column vectors');
      case -2
        if not(isRobust)
            error('ccbr:BadInput',['all fields of structure must be of ', ...
                  'type numeric, logical or cellstr']);
        end
    end
end

% Assign formatting for header
propertyNames = fieldnames(S);
propertyNamesFmtd = headerunrepl(propertyNames);
propNamesFmt = repmat('\t%s',1,numel(propertyNames));
propNamesFmt = [propNamesFmt(3:end) '\n']; % trim first tab and add newline

% Obtain formats for writing out numbers
fmts = getformat(S,propertyNames,options);

% Write the file
fid1= fopen([filedir filename],'Wb');
fprintf(fid1,propNamesFmt,propertyNamesFmtd{:});

if DFisnum(S) && isWithNaN     % FAST
    % convert DF to a matrix and write to file
    fullFmt      = sprintf('%s\\t',fmts{:}); % preserve \t
    fullFmt(end) = 'n';        % replace final tab with new line
    fprintf(fid1,fullFmt,transpose(DFtomat(S)));
elseif not(isRobust)           % WELL
    % preallocate matrix, fill matrix with strings, write to file
    [M isNumIdx] = allocmat(S,fmts,isWithNaN);
    M = fillmat(S,M,propertyNames,fmts,isNumIdx,numRows,1,isWithNaN);
    fprintf(fid1,'%s',M);
else                           % RIGHT
    % write each line of file by recursively converting to a string
    for lineNo = 1:numel(S.(propertyNames{end}))
        fprintf(fid1,'%s\n',writeline(S,lineNo,propertyNames,fmts));
    end
end
% close the file and exit
fclose(fid1);
if ~exist('err','var')
    err = 0;
else
    err = -1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function str = writeline(S,lineNo,propertyNames,fmts)
% WRITELINE
%
%    str = writeline(S,lineNo,propertyNames,fmts)
%
%    recursivelty concatenate each line of output into a string
% 
    vertStr = cell(numel(propertyNames),1);
    for i = 1:numel(propertyNames)
        vertStr{i} = conv2str(S.(propertyNames{i})(lineNo),1,fmts{i});
    end
    str = cell2delim(vertStr,sprintf('\t'));
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function header = headerunrepl(header)
% HEADERUNREPL
%    ensures that all fields of header are the same as they
%    were in an input file
    header = regexprep(header,'JPJ','/' );
    header = regexprep(header,'NPN',':' );
    header = regexprep(header,'QPQ','\.');
    header = regexprep(header,'VPV',')' );
    header = regexprep(header,'XPX','(' );
    header = regexprep(header,'YPY','\"');
    header = regexprep(header,'ZPZ','\ ');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function fmts = getformat(S,propNames,options)
% GETFORMAT
%
%     fmts = getformat(S,propNames,options)
%
%     assigns formats based on the data type contained
%
%     the field options.defaultFmt can hold a default format for
%     non-integer numerical formats
%  

    % initialize constants
    optFields = fieldnames(options);
    if isfield(options,'defaultFmt')
        defaultFmt = options.defaultFmt;
        if isfield(S,'defaultFmt')
           warning('ccbr:BadInput', ...
             ['options.defaultFmt specifies format for all ' ...
              'numerical fields, but file has also has field "defaultFmt"']);
        end
    else
        defaultFmt = '%0.5g';
    end
    if isfield(S,'defaultFmt')
        warning('ccbr:BadInput', ...
        ['options.isRobust is a switch in DFwritem, ' ...
         'but file has also has field "isRobust"']);
    end
    numFmts = numel(propNames);
    fmts    = cell(1,numFmts);

    % assign format for each field
    for i = 1:numFmts
        currName = propNames{i};
        if numel(strmatch(currName,optFields,'exact')) == 1
             fmts{i} = options.(currName);
        elseif isint(S.(currName))
             fmts{i} = '%.0f';      % keep all digits of any "de facto" integers
        elseif iscellstr(S.(currName))
             fmts{i} = defaultFmt;
        else 
            fmts{i} = defaultFmt;   % e.g., decimal
        end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [M isNumIdx]= allocmat(S,fmts,isWithNaN)
% preallocate a character matrix of a size at least large enough to hold S
    strSize  = 0;
    numSize  = 0;
    nullchar = char(0);
    fields   = fieldnames(S);
    isNumIdx = true(size(fields));
    for i = 1:numel(fields)
        currFld = fields{i};
        if iscellstr(S.(currFld))
            isNumIdx(i) = false;
            sizeVec     = cellfun(@numel,S.(currFld));
            strSize      = strSize + sum(sizeVec(:) + 1); % \t -> 1 char
        end
    end
    if any(isNumIdx)
        numFmt      = sprintf('%s\t',fmts{isNumIdx});
        numFmt(end) = sprintf('\n');   % replace final tab with new line
        if isWithNaN
            numSize = numel(sprintf(numFmt, ...
                      transpose( DFtomat(DFkeepcol(S,fields(isNumIdx))) )));
        else
            M       = sprintf(numFmt, ...
                      transpose( DFtomat(DFkeepcol(S,fields(isNumIdx))) ));
            M       = rmnanstr(M);
            numSize = numel(M);
            
        end
    end 
    M = repmat(nullchar, 1, strSize + numSize); % one big row vector

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function M = fillmat(S,M,header,fmts,isNumIdx,numRows,currRow,isWithNaN);
% fill character matrix M, when writing DF's containing strings
% rowGroup is a flexible parameter for buffering calls to sprintf
    idx             = 1;
    rowGroup        = 400;  % number of lines to write together
    sizeAlloc       = numel(M);
    numFldIdx       = transpose(find(    isNumIdx));
    strFldIdx       = transpose(find(not(isNumIdx)));
    fmts(strFldIdx) = {'%s'};
    fmtsOUT         = cell2delim(fmts,'\t');
    fmtsOUT         = [fmtsOUT '\n'];
    toWrite         = cell(numel(header),rowGroup);
    for i = 1:rowGroup:numRows
        isLast = (numRows - i < rowGroup);
        for k = 1:rowGroup
            for j = numFldIdx
                toWrite{j,k} = S.(header{j})(i+k-1);
            end
            for j = strFldIdx
                toWrite{j,k} = S.(header{j}){i+k-1};
            end 
            if isLast && (k > numRows - i)
                toWrite = toWrite(:,1:k);
                break;   
            end
        end 
        currLine              = sprintf(fmtsOUT,toWrite{:});
        if not(isWithNaN) 
            currLine = rmnanstr(currLine);
        end
        spacer                = numel(currLine);
        if (idx + spacer - 1) > sizeAlloc
            warnMsg = sprintf(['Preallocation of %g sufficient to write ', ...
                               'only %g rows of data frame'],sizeAlloc,i);
            warning('ccbr:MemoryError',warnMsg);
        end
        M(idx:(idx+spacer-1)) = currLine;
        idx                   = idx + spacer;
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function M = rmnanstr(M);
% RMNANSTR
%     rmnanstr - remove the substring "NaN" from a string
%
%     find index just BEFORE each "NaN" in dataset

    if strcmp(M(1:4),sprintf('%g\t',nan))               % first element
        nanLocs{1} = 0;
    else
        nanLocs{1} = [];
    end
    if strcmp(M(end:end-3),sprintf('\t%g',nan)) || ...  % last element
       strcmp(M(end:end-3),sprintf('\n%g',nan)) || ...
       ( numel(M) == 3 && strcmp(M(end:end-2),sprintf('%g',nan)) )
        nanLocs{2} = numel(M)-3;            % since numel('NaN') == 3
    else                      % last element within preallocated matrix
        nanLocs{2} = strfind(M,[sprintf('\t%g',nan) char(0)]);
    end
    nanLocs{3} = strfind(M,sprintf('\n%g\t',nan));     % first in row
    nanLocs{4} = strfind(M,sprintf('\t%g\t',nan));     % typical
    nanLocs{5} = strfind(M,sprintf('\t%g\n',nan));     % last in row
    rmLocs     = unique(makevert(nanLocs{:}));
    M([rmLocs + 1; rmLocs + 2; rmLocs + 3]) = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%
%UNIT TEST DESCRIPTION
% Required
% 1. Write a DF as a text file
% 2. Permit types: double, int, logical, cellstr, char (?)
% Optional
% 1. Add index (?)
% 2. Write only specific rows (?)
% 3. Use specific default or field specific output format
