function [outCharMat] = DFview(S,idx,colWidth,isPrintIndex,maxDig)
% DFVIEW
%        Display a few rows from a structure
%
%     outCharMat = DFview(S)
%     outCharMat = DFview(S,idx)
%     outCharMat = DFview(S,idx,colWidth,isPrintIndex,maxDig)
%
% parameters
% ----------------------------------------------------------------
%    "S"            - a 1x1 structure of arrays of any type
%                     e.g., double, int, char or cell array of strings 
%                     e.g., S.fieldname(index)
%    "idx"          - a logical or positive integer index into S
%    "colWidth"     - a positive integer equal to the maximum width per column
%    "isPrintIndex" - a logical determining whether an index column is printed
%    "maxDig"       - a positive integer giving a number beyond which decimals
%                     should be truncated
% output
% ----------------------------------------------------------------
%    "outCharMat"   - a matrix of type character containing data from S
% ----------------------------------------------------------------
%
%     Created 14 December 2008
%     Hy Carrinski
%     Broad Institute
%
%    Note: currently grows output matrix as loops over fields, since
%    widths of numerical fields are difficult to estimate. Could adopt
%    a preallocation approach similar to DFwrite if desired

% Prepare inputs 
fields = fieldnames(S);
if nargin < 2 || isempty(idx)
    idx= 1:numel(S.(fields{1}));
end
if nargin < 3 || isempty(colWidth)
    colWidth = inf;
end
if nargin < 4 || isempty(isPrintIndex)
    isPrintIndex = false;
end
if nargin < 5 || isempty(maxDig)
    maxDig = 6; % number of digits before and after decimal
end
if islogical(idx)
    idx = find(idx);
end
numRows = numel(idx);

% Add index
if isPrintIndex
    unpaddedStrings = num2str(idx(:));
    currWidth       = max(size(unpaddedStrings,2),numel('Index'));
    currWidth       = min(currWidth,colWidth) + 1;
    outCharMat      = [addpad('Index',currWidth); ...
                       addpad(unpaddedStrings,currWidth,false)];
else
    outCharMat      = [];
end
% Generate output character matrix
S = DFkeeprow(S,idx);
for i = 1:numel(fields)
    currFld = fields{i};
    if iscellstr(S.(currFld))
        initWidth     = max(cellfun(@numel,S.(currFld)));
        currWidth     = getwidth(initWidth,colWidth,numel(currFld));
        paddedStrings = cellfun(@(x) addpad(x,currWidth,true), ...
                         S.(currFld),'UniformOutput',false);
        charMat       = [ addpad(currFld,currWidth); ...
                          cell2mat(paddedStrings) ];
   elseif isnumeric(S.(currFld)) || islogical(S.(currFld))
        numFormat       = getformat(abs(S.(currFld)),maxDig);
        unpaddedStrings = num2str(S.(currFld),numFormat);
        initWidth       = size(unpaddedStrings,2);
        currWidth       = getwidth(initWidth,colWidth,numel(currFld));
        charMat         = [ addpad(currFld,currWidth); ...
                            addpad(unpaddedStrings,currWidth,false) ];
   else
       error('ccbr:BadInput',...
             [ class(S.(currFld)) ' is not yet supported' ]);
   end
   outCharMat = [ outCharMat, charMat];
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function x = addpad(x, num, isPadRight)
% ADDPAD
%     addpad - add whitespace padding to end of string
%
%     x = addpad(x, num, isPadRight)
%
%     isPadRight is logical, default = true

    if nargin < 3 || isempty(isPadRight)
        isPadRight = true;
    end
    space = ' ';
    if isempty(x)
        x = repmat(space,1,num);
    elseif size(x,2) >= num
        x = [ x(:,1:(num-1)) repmat(space,size(x,1),1) ];
    elseif isPadRight
        x = [ x repmat(space,size(x,1),num-size(x,2)) ];
    else
        x = [ repmat(space,size(x,1),num-size(x,2)-1), ...
              x, repmat(space,size(x,1),1) ];
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function numFormat = getformat(vals, maxDig)
% GETFORMAT
%     getformat - generate sprintf-style format string for numbers
%
%     numFormat = getformat(vals, maxDig)

    if islogical(vals)
        numFormat = '%0.0f';
    end
    logVals   = log10(vals);
    maxDigits = min(max(ceil(abs(max(logVals))),1),maxDig);
    minDigits = min(max(ceil(abs(min(logVals))),0),maxDig-1)+1;
    if all(vals == round(vals)) 
        minDigits = 0;
    end
    numFormat = [ '%' sprintf('%0.0f.%0.0f',maxDigits,minDigits) 'f'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function width = getwidth(initWidth, colWidth, headWidth)
% GETWIDTH
%     getwidth - calculate output column width
%
%     width = getwidth(initWidth, colWidth, headWidth)

    width = min( max(initWidth,headWidth), colWidth ) + 1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%
%UNIT TEST DESCRIPTION
% Required
% 1. Show a DF
% 2. Show fields of types: double, int, cellstr, char (?)
% 3. Have at least one space between field names and between field values
% Optional
% 1. Add index
% 2. Show specific rows based on logical or integer index
% 3. Trim field's length
% 4. Define number of decimal places
