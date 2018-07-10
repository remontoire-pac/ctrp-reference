function s = conv2str(item,level,formatNumbers,isWithNaN)
% CONV2STR
%     converts any input to a single string
%
%     s = conv2str(item,level,formatNumbers,isWithNaN)
%
%parameters
%----------------------------------------------------------------
%     "item"          - the item or 1D array of items which is being converted to a string
%     "level"         - 0 = no delimiter (default)
%                       1 = ";"
%                       2 = ":"
%                       3 = ","
%     "formatNumbers" - printf format string for number, default is "%0.5g"
%     "isWithNaN"     - boolean to determine whether NaNs are output as
%                     "" (default=0) or "NaN" (=1)
%output
%----------------------------------------------------------------
%     "s"             - a string (an 1xn char array)
%----------------------------------------------------------------
%
%    Hy Carrinski
%    Broad Institute

% Accept inputs
if nargin < 4 || isempty(isWithNaN)
    isWithNaN = false;
end
if nargin < 3 || isempty(formatNumbers)
    formatNumbers = '%0.5g';
end
if nargin < 2 || isempty(level)
    level = 0;
end
allDelim = {'',';',':',','};
delim    = allDelim{level+1};

% ensure input is 1x1, nx1 or 1xn only
sizItem  = size(item);
numItems = max(sizItem);

% return empty items immediately
if isempty(item)
    s = '';
    return
end

% matrices are currently unsupported
if prod(sizItem) ~= numItems
    error('ccbr:BadInput', ...
        'conv2str supports only single dimensional arrays');
end

% return strings right away, as row vectors
if ischar(item)
    s = item(:)';
    return
end

% perform work on single items
if numItems == 1
   if isnumeric(item)
       s = sprintnum(item,formatNumbers,isWithNaN);
    elseif iscellstr(item)
       s = item{1};
   elseif iscell(item)
       s = conv2str(item{1},level,formatNumbers,isWithNaN);
   elseif islogical(item)
       s = sprintnum(item);
   else
       error('ccbr:BadInput', ...
         ['Cannot convert with conv2str, type unknown: ' class(item) ]);
   end 
else
    % Recursively concatenate over arrays
    s = '';
    for i = 1:numItems
        s = [s delim conv2str(item(i),level+1,formatNumbers,isWithNaN) ];
    end

    % supports multi character delimiters and no delimiter
    s=s((1+numel(delim)):end); 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function s = sprintnum(item,formatNumbers,isWithNaN);
% SPRINTNUM
%    s = sprintnum(item,formatNumbers,isWithNaN);
%    default is to print NaN's as blank ( isWithNaN=false )

    if nargin < 3 || isempty(isWithNaN)
        isWithNaN = false;
    end
    if nargin < 2 || isempty(formatNumbers)
        formatNumbers = '%0.5g';
    end

    % could choose to differentiate between numeric type here
    if isnan(item) && not(isWithNaN)
        s = '';
    else
        % sprintf can handle NaN, Inf and -Inf
        s = sprintf(formatNumbers,item);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
