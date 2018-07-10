function [Data rawData Err origHeader] = DFread(filename,filedir,readLength, ...
               options,isColNames,isFormat,numCommLines,isRobust,robustDelim)
% DFREAD
%        load in a tab delimited text file
%
%    Data = DFread(filename)
%    Data = DFread(filename,filedir)
%    Data = DFread(filename,[],[],options)
%    [Data rawData Err] = DFread(filename,filedir,readLength,...
%             options,isColNames,isFormat,numCommLines,isRobust,delim)
%
% parameters
%----------------------------------------------------------------
%    "filename"      -  char array of the filename or path to the file
%    "filedir"       -  char array of the directory containing the file
%    "readLength"    -  number of lines of file to determine column formats
%    "options"     -  structure with fields to override default formats
%                       fields are cell arrays of strings and are self
%                       descriptive: "str" "num" "ignore" and "keep"
%                        "isCSV"      - use comma rather than tab and NOT preserve quotes
%                        "maxLines"   - maximum number of lines of data to read (default=-1)
%                        "isColNames" -  boolean (default=true) column names in a header row
%                        "isFormat"   -  boolean (default=true) formats determined from file,
%                                        or, false, each element treated as a string
%                        "numCommLines"
%                        "isRobust"
%                        "robustDelim"
%                       ADDITIONAL field for option TO BE implemented:
%                        "isAllNum"    - can use faster methods when reading only numbers
%                       currently, some options can be accessed using other fields of options
%    "isColNames"    -  boolean (default=true) column names in a header row
%    "isFormat"      -  boolean (default=true) formats determined from file,
%                       or, false, each element treated as a string
%    "numCommLines"  -  scalar number of lines to ignore at head of file
%    "isRobust"      -  read file line by line and parse each column into a
%                       cell array (default=false). Use of format string with
%                       this option is not yet implemented. Typically used ONLY
%                       when parsing badly formatted (e.g., instrument) files.
%    "robustDelim"   -  optional delimiter character (default=sprintf('\t'), tab)
% outputs
%----------------------------------------------------------------
%    "Data"       - a data frame: a 1x1 structure where each field is a
%                   column vector of type double, logical, int or cell string
%    "rawData"    - a 2D cell array which is the raw output from textscan
%    "Err"        - status of read: (displayed if value is not "0")
%                       "0" is good
%                       "1" columns are of different lengths
%                       "2" number of rows read do not match number of lines in file
%                       "3" both 1 and 2
%    "origHeader"  - a cell array of strings of the original header 
%----------------------------------------------------------------
%     column names -> field names in a structure
%     column values to arrays within fields of the structure
%
%     columns for which every row is a number or is blank --> double array
%     columns which do not meet this criterion --> cell array of strings
%
%     readLength is a number, typically between 100 and 1000, which defines
%     how many lines from the file will be used to determine the format of
%     each column.
% 
%     DFread depends on DFverify, strsplithy
%     Broad Institute
%     Hy Carrinski
%
% See also DFwrite.m DFview.m
%
% Add method to consider columns with same names and blank columns
% Potential bugs in the data frame toolbox:
%     If a column name is repeated, that might cause an error
%     The output formatting may not be identical to the input
%     formatting for every number.
%
% Possible: options may also be implemented with case-insensitive,
%     abbreviation allowing, parameter-value pair system like
%     gridfit and many built-in matlab functions

% QC inputs
if nargin<1 || isempty(filename)
    error('ccbr:BadInput','Filename must be given to function DFread');
end
if nargin<2 || isempty(filedir)
    filedir = [];
elseif ~strcmp(filedir(end),'\') || ~strcmp(filedir(end),'/') 
    filedir = [filedir filesep];
end
filepath = [filedir filename];

% support wildcards in filename
if not(isempty(strfind(filepath,'*')))
    filestruct = dir(filepath);
    if ( numel(filestruct) ~= 1 ) 
        error('ccbr:BadInput',['path does not match a unique file: ' filepath]); 
    end
    filedir    = fileparts(filepath);
    filepath   = [ filedir filesep filestruct.name ];
end
if nargin<3 || isempty(readLength)
    readLength = 16384;  %default number of lines
end
if nargin<4 || isempty(options)
    options = struct([]);
end
valueConflictMsg = @(str) ...
    sprintf('conflict in value of parameter %s, please check inputs',str);
if nargin<5 || isempty(isColNames) %&& not(strcmp(listOfOptions(idxDefOptions)),'isColNames')
    if isfield(options,'isColNames')
        isColNames = options.isColNames;
    else
        isColNames = true; % true if Column names exist
    end
elseif isfield(options,'isColNames') && not(isequal(options.isColNames,isColNames))
     error('ccbr:BadInput', valueConflictMsg('isColNames')); 
end
if nargin<6 || isempty(isFormat)
    if isfield(options,'isFormat')
         isFormat = options.isFormat;
    else
         isFormat = true;   % true if formats are to be found, otherwise string format assumed 
    end
elseif isfield(options,'isFormat') && not(isequal(options.isFormat,isFormat))
    error('ccbr:BadInput', valueConflictMsg('isFormat')); 
end
if nargin<7 || isempty(numCommLines)
    if isfield(options,'numCommLines')
         numCommLines = options.numCommLines;
    elseif isColNames
        numCommLines = 1; % 1 if Column names exist
    else
        numCommLines = 0; % 0 if Column names do not exist
    end
elseif isfield(options,'numCommLines') && not(isequal(options.numCommLines,numCommLines))
    error('ccbr:BadInput', valueConflictMsg('numCommLines')); 
end
if nargin<8 || isempty(isRobust)
    if isfield(options,'isRobust')
        isRobust = options.isRobust;
    else
        isRobust = false; % please set to true if unable to read otherwise
    end
elseif isfield(options,'isRobust') && not(isequal(options.isRobust,isRobust))
    error('ccbr:BadInput', valueConflictMsg('isRobust')); 
end
if nargin<9 || isempty(robustDelim)
    if isfield(options,'robustDelim')
        robustDelim = options.robustDelim;
    else
        robustDelim = sprintf('\t'); 
    end
elseif isfield(options,'robustDelim') && not(isequal(options.robustDelim,robustDelim))
    error('ccbr:BadInput', valueConflictMsg('robustDelim')); 
end

if isfield(options,'isCSV')
    isCSV = isequal(true,options.isCSV);
else
    isCSV = false;
end 
if isfield(options,'maxLines')
    maxLines = options.maxLines;
else
    maxLines = -1; % textscan docs require N > 0, but N = 0 and N = -1 presently work 
end
if isfield(options,'isAllNum')
    isAllNum = isequal(true,options.isAllNum);
else
    isAllNum = false;
end

fid = fopen(filepath,'rt');
if fid < 0
    error(['File: ' filepath ' could not be opened']);
end
if maxLines < 0
    filelength = getfilelength(fid,filepath,maxLines);
else
    filelength = getfilelength(fid,filepath,maxLines + numCommLines);
end
% QC is complete

% Read in a tab delimited text file with column names
formats = '%s';                          % initialize formats
if isFormat
    [formats headerIdx] = ... 
         checkformats(fid,options,readLength,isColNames,numCommLines,isCSV);
end
if isColNames
    % discard comment lines before line of headers
    for i = 1:(numCommLines-1)
        header         = fgetl(fid);
    end
    % read header
    if isCSV
        header = strread(char(fgetl(fid)), '%q','delimiter',',');
    else
        header = strread(char(fgetl(fid)), '%s','delimiter','\t');
    end
    origHeader = header;
else
    header= makeheader(fid,readLength,numCommLines,robustDelim);
end

if not(isequal(numel(header), numel(unique(header))))
    error('ccbr:BadInput','DFread requires that each input column possess a unique column name')
end

% Correct for parentheses in header
header = headerrepl(header);
if isFormat
    header = header(headerIdx);
end

if isCSV && isColNames
    formats = csvformatreplace(formats);
    rawData = textscan(fid, formats, maxLines,'delimiter', ',', 'headerlines', 0);
elseif not(isRobust) && isColNames
    rawData = textscan(fid, formats, maxLines,'delimiter', '\t', 'headerlines', 0);
else
    frewind(fid);
    rawData = lineread(fid, formats, numel(header), numCommLines,robustDelim,maxLines);
    % note: CURRENT implementation of lineread IGNORES formats
end
fclose(fid);

Data = cell2struct(rawData,header,2); % operates along 2nd dimension: columns
Err  = checklength(filelength,Data,isColNames,numCommLines);
if Err > 1
    Err
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ formats headerIdx ] = checkformats(fid,userInput,readLength,isColNames,numCommLines,isCSV)
% CHECKFORMATS  determines formats of columns of tab-delimited text file
%    and returns a format string
%     
%    [ formats headerIdx ] = checkformats(fid,userInput,readLength,isColNames,numCommLines,isCSV)
%    
%    Format choices are based on priority given below:
%
%    1. userInput = struct('str',{'ColA','ColB'},'num',{'Col1','Col2'},'ignore',{''},'keep',{''});
%    2. Column header names
%    3. Search readLength lines
%
%    Hy Carrinski
%    Created 29 June 2006

if nargin < 2 || isempty(userInput)
    userInput = struct('str',{''},'num',{''},'ignore',{''},'keep',{''});
else
    NeededFields = ~isfield(userInput,{'str','num','ignore','keep'});
    if NeededFields(1)
        userInput.str    = '';
    end
    if NeededFields(2)
        userInput.num    = '';
    end
    if NeededFields(3)
        userInput.ignore = '';
    end
    if NeededFields(4)
        userInput.keep = '';
    end
end

% Initialize column names
ColNames = struct('str',[],'num',[]);
ColNames.num = struct('userInput',[],'known',[],'general',[],'specific',[]);
ColNames.str = struct('userInput',[],'known',[],'general',[],'specific',[]);

% Populate column names
if ~isempty(userInput.str)
    ColNames.str.userInput  = userInput.str(:);
end
ColNames.str.general    = {'Plate';'PlateName';'Type';'CompoundName';'Rep';'Row';'Well'};
ColNames.str.specific   = {'Method';'ExptID'};

if ~isempty(userInput.num)
    ColNames.num.userInput  = userInput.num(:);
end
ColNames.num.general    = {'Col';'Conc';'RawValue';'BSubValue';'ZScore'};
ColNames.num.specific   = {'LambdaEx';'LambdaEm';'LambdaAbs';'RawValueA';...
    'BSubValueA';'ZScoreA';'RawValueB';'BSubValueB';'ZScoreB';...
    'RawValueC';'BSubValueC';'ZScoreC';'CompositeZ';...
    'Mock_Mean';'Mock_StdDev';'SigmaAssay';'BSubValue_N'};

% Join the column names in priority order and return error if redundant
ColNames = makeknown(ColNames);

% Now look at only those column names not previously assigned a format
formats        = '';                       % initialize formats
unknownFormats = '';
frewind(fid);
if isColNames
    for i = 1:(numCommLines-1)             % discard comment lines
        header         = fgetl(fid);
    end
    if isCSV
        header = strread(char(fgetl(fid)), '%q','delimiter',',');
    else
        header = strread(char(fgetl(fid)), '%s','delimiter','\t');
    end
else
    header  = makeheader(fid,readLength,numCommLines);
end

% Correct for parentheses in header
header = headerrepl(header);

cellFormats = cell(numel(header),1);
for i = 1:numel(header)
    if any(strcmp(header{i},ColNames.str.known))
        cellFormats{i}  = '%s';
        unknownFormats = [unknownFormats ' %*s'];
    elseif any(strcmp(header{i},ColNames.num.known))
        cellFormats{i}  = '%f';
        unknownFormats = [unknownFormats ' %*f'];
    else
        unknownFormats = [unknownFormats ' %s'];
    end
end

% find the unknown formats and return the complete formats
% This is the most important line in this function
% no need to rewind before running this function
% can avoid running if all formats are already known
if any(cellfun('isempty', cellFormats))
    [cellFormats{cellfun('isempty', cellFormats)}] = ...
        findformat(unknownFormats,fid,readLength,...
        header(cellfun('isempty', cellFormats)),isCSV);
end
frewind(fid);

% In case we miss any formats,
% the user will know which ones to input manually 
missingFormats = find(cellfun('isempty', cellFormats));
if ~isempty(missingFormats)
    errorStr = '';
    for i = 1:numel(missingFormats)
        errorStr = [errorStr ', ' header(missingFormats(i))];
    end            
    error(['These formats are missing: ' errorStr(3:end)]);
end
% all formats have been found
% keeping columns has priority over removing columns
% remove columns to be ignored  (may not ignore columns with parentheses)
if isempty(userInput.keep)  % if not char, then not empty
    ignoreIdx = find(    ismember(header,userInput.ignore));
else
    ignoreIdx = find(not(ismember(header,userInput.keep)));
end
for i = 1:numel(ignoreIdx)
    if strcmp(cellFormats{ignoreIdx(i)},'%f')
        cellFormats{ignoreIdx(i)} = '%*f';
    else
        cellFormats{ignoreIdx(i)} = '%*s';
    end
end
% ensure that header matches kept columns
headerIdx            = true(size(header));
headerIdx(ignoreIdx) = false;
formats              = [ cellFormats{:} ];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [varargout] = findformat(unknownFormats,fid,readLength,fields,isCSV)
    % find formats and return a comma separated list
    % fields is likely "header"
    % assumes file is at correct start place (just below header row)

    if isCSV
        unknownFormats = csvformatreplace(unknownFormats);
        sampleData = textscan(fid,unknownFormats,readLength,...
            'delimiter',',','headerlines',0);
    else
        sampleData = textscan(fid,unknownFormats,readLength,...
            'delimiter','\t','headerlines',0);
    end
    Data = convertformats(sampleData,fields);
    cellFmt = cell(1,numel(fields));
    for i = 1:numel(fields)
        switch class(Data.(fields{i}))
            case 'cell'
                cellFmt{i} = '%s';
            case 'double'
                cellFmt{i} = '%f';
            case 'char'
                cellFmt{i} = '%s';
            otherwise
                error('class not supported')
        end
    end
    varargout = cellFmt; % Returns a comma separated list

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ColNames = makeknown(ColNames)
    % requires that every leaf node of ColNames is a column vector
    % Make non-redundant lists of formats according to priority
    strForSure  = ColNames.str.userInput;
    strLikely   = setdiff(ColNames.str.specific, ColNames.num.userInput);
    strPossibly = setdiff(ColNames.str.general, ...
                  [ColNames.num.userInput; ColNames.num.specific] );

    numForSure  = ColNames.num.userInput;
    numLikely   = setdiff(ColNames.num.specific,ColNames.str.userInput);...
    numPossibly = setdiff(ColNames.num.general, ...
                  [ColNames.str.userInput; ColNames.str.specific] );

    ColNames.str.known = unique([ strForSure; strLikely; strPossibly]);
    ColNames.num.known = unique([ numForSure; numLikely; numPossibly]);
    if any(ismember(ColNames.str.known,ColNames.num.known))
        error('ccbr:BadInputs','Format redundancy');
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Data = convertformats(rawData,fields)
% CONVERTFORMATS
%     Cycle through cells containing column vectors of cells or doubles
%     and convert each column vector to vector of type double or cellstring.
%
%     If all NaNs in a vector match the string lower(NaN) in the original
%     field or are empty, then the field is considered to be numeric.
%
%     If all elements in a vector are NaN, the string format is chosen
%     to be more conservative when reading the entire file.
%
%     Hy Carrinski
%     Created 28 June 2006
%

Data = struct(fields{1},[]);
for i = 1:numel(fields)
    asNum      = str2double(rawData{i});     % conversion
    nanIdxConv = isnan(asNum);               % converted
    nanIdxReal = strcmpi('nan',rawData{i});  % explicit
    % numeric all nans are either empty or written as nan
    if ( isequal(nanIdxConv, nanIdxReal) || ...
     all(strcmp('',rawData{i}(nanIdxConv))) )
        Data.(fields{i})      = asNum;       % formats as double array
    % Postpone conversion until DataFrame supports char array
    elseif false && iscellstr(rawData{i}) && ...
     ( numel(unique(cellfun(@numel,rawData{i}))) == 1 )
        Data.(Data.fields{i}) = char(rawData{i});
    else
        Data.(fields{i})      = rawData{i};  % format remains cell array of strings
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [header origHeader]  = makeheader(fid,readLength,numCommLines,robustDelim)
%   header = makeheader(fid,readLength,numCommLines,robustDelim)
%   generates a header of equal length column names for data without a header
%   new modification permit names longer than 63 characters, and even keep
%   the original names

    if nargin < 4
        robustDelim = sprintf('\t');
    end
    frewind(fid) % Go to file beginning
    colsPerLine = zeros(readLength,1);
    linedata    = textscan(fid, '%s', readLength, 'delimiter', '\n', ...
                'whitespace', '','headerlines',numCommLines);
    for i = 1:numel(linedata{1})
        if not(isempty(linedata{1}{i}))
            colsPerLine(i) = numel(strsplithy(robustDelim, linedata{1}{i}));
        end
    end
    numCols  = max(colsPerLine);
    header   = makeheadernames(numCols);

    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function header = makeheadernames(numCols)
%   header = makeheadernames(numCols)
%   makes columns names for a given number of columns
    part1               = repmat('Column', numCols, 1);
    part2               = num2str(transpose((1:numCols)));
    part2(part2 == ' ') = '0'; % replace spaces with zeros
    header              = mat2cell([part1 part2],ones(numCols,1));
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function rawData = lineread(fid, formats, numFields, numCommLines,robustDelim,maxLines)
% LINEREAD
%      rawData = lineread(fid, formats, numFields, numCommLines,robustDelim,maxLines)
%      currently ignores "formats"
    linedata   = textscan(fid, '%s', maxLines, 'delimiter', '\n', ...
                 'whitespace', '', 'headerlines', numCommLines);
    rawArray    = cell(numel(linedata{1}), numFields);
    rawArray(:) = {''};
    for i = 1:numel(linedata{1})
        if not(isempty(linedata{1}{i}))
            oneLine = strsplithy(robustDelim, linedata{1}{i}); % good solution
            % textscan can drop trailing tab
            % truncates lines possessing more  elements than file's columns
            if not(isempty(oneLine))
               oneLine = oneLine(1:min(numel(oneLine),numFields)); 
               rawArray(i,1:numel(oneLine)) = oneLine;
            else
               rawArray(i,1) = linedata{1}{i}; % Maybe obsolete, what is its effect?
            end
        end
    end
    clear linedata
    for j = numFields:-1:1
        rawData{1,j}  = rawArray(:,j);
        rawArray(:,j) = [];
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function header = headerrepl(header)
% HEADERREPL
%    ensures that all fields of header are okay for matlab fieldnames
%    first performs simple replacement, then calls genvarname
    hdrLength = cellfun(@numel,header);
    if any(hdrLength>63 | hdrLength == 0)
        header = makeheadernames(numel(header));
        warning('ccbr:BadInput','Column headers empty or more than 63 characters, please see fourth output of DFread');
        return
    end
    header = regexprep(header,'/' ,'JPJ');
    header = regexprep(header,'#' ,'KPK');
    header = regexprep(header,':' ,'NPN');
    header = regexprep(header,'\.','QPQ');
    header = regexprep(header,')' ,'VPV');
    header = regexprep(header,'(' ,'XPX');
    header = regexprep(header,'\"','YPY');
    header = regexprep(header,'\ ','ZPZ');
    hdrLength = cellfun(@numel,header);
    if any(hdrLength>63)
        header = makeheadernames(numel(header));
        warning('ccbr:BadInput','Column headers modified to more than 63 characters, please see fourth output of DFread');
        return
    else
        header = genvarname(header);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Err = checklength(filelength,Data,isColNames,numCommLines)
% CHECKLENGTH
% Check if Data is okay and matches wc's line count
    [isOkay numRows] = DFverify(Data,true);
    deltaLines = numCommLines;
    Err = (isOkay < 1) + 2*not(isequal(filelength,numRows + deltaLines)); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function filelength = getfilelength(fid,filepath,maxLines)
% GETFILELENGTH
    try 
        frewind(fid);
        linesFound = textscan(fid, '%s', maxLines, 'delimiter', '\n');
        filelength = numel(linesFound{1});
    catch
        frewind(fid);
        linesFound = textscan(fid, '%s', maxLines, 'delimiter', '\n','BufSize',2^16-1);
        filelength = numel(linesFound{1});
    end
    frewind(fid);
    %else
    %    [wcOkay unixNumRowsStr] = unix(['wc -l ' filepath]);
    %    filelength              = strsplithy(' ',unixNumRowsStr);
    %    if numel(filelength) > 1 && (wcOkay == 0)
    %        filelength = str2double(filelength(1));
    %    else
    %        error('ccbr:SignalFromOS','Line counting broke');
    %    end
    %end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% alternative method to read long files
%filelength = 0;
%newLn = sprintf('\n');
%chunksize = 1e6;
%while not(feof(fid))
%    ch = fread(fid, chunksize, '*uchar');
%    if isempty(ch)
%        break;
%    end
%    filelength = filelength + sum(ch == newLn);
%end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function formats = csvformatreplace(formats)
% perform replacements in format string to handle CSV files
    formats = strrep(formats,'%s','%q');
    formats = strrep(formats,'%*s','%*q');
