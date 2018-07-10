function [ B I J ] = uniquenotmiss(A,isEqualNaNs)
% UNIQUENOTMISS
%       find the unique values of array A which present.
%
%    [ B I J ] = uniqnotmiss(A,isEqualNaNs)
%
% parameters
%----------------------------------------------------------------
%    "A"           - a vector of doubles or a cell array of strings 
%    "isEqualNaNs" - a logical whether NaN's are treated as equal (true)
%                    or ignored (default=false)
%
% outputs
%----------------------------------------------------------------
%    "B" - a vector or linear cell array containing the unique values of A
%    "I" - an index vector such that B = A(I); 
%    "J" - an index vector such that regardless whether
%          A = nan(size(J));
%                  or
%          A = repmat({''},size(J));
%                  then
%          A( J > 0 ) = B( J(J > 0) );
%----------------------------------------------------------------
%      
%    Missing values are NaN for numerical arrays or
%    empty strings for a cell array of strings.
%    If the data type is neither cell nor double,
%    uniqnotmiss behaves the same as unique
%
%    Hy Carrinski
%    Broad Institute
%    Created  10Nov2008
%    Modified 16Jun2009
%    Required by DFindex, DFjoin and DFsort

% This version of unique supports only column or row vectors
if nnz(size(A) > 1) > 1
    error('uniqnotmiss requires an 1-D array as input.');
end

if nargin < 2 || isempty(isEqualNaNs)
    isEqualNaNs = false;
end

% Single output case is simple
if nargout <= 1
    B = unique(A);
    if isa(B,'double')
        rmIdx = find(isnan(B));
        if isEqualNaNs && not(isempty(rmIdx))
            rmIdx(1) = []; % preserve first instance
        end
        B(rmIdx) = []; % delete NaNs
    elseif isa(A,'cell')
        rmIdx = find(cellfun('isempty',B));
        if isEqualNaNs && not(isempty(rmIdx))
            rmIdx(1) = []; % preserve last instance
        end
        B(rmIdx) = []; % delete empty values
    end
else
   % Multiple output case is useful
    [B I J] =unique(A);
    rmIdx = [];
    if isa(A,'double')
        % NaNs are sorted to the end of B and I
        % so position in B of first NaN is at min(rmIdx)
        % Set value in J to 0 at positions which are NaN in A.
        rmIdx = find(isnan(B));
        if not(isempty(rmIdx))
            J(J>=min(rmIdx)) = 0; 
            if isEqualNaNs
                J(J==0)  = min(rmIdx); % NaNs at the end
                rmIdx(1) = []; % preserve first instance
            end
        end
    elseif isa(A,'cell')
        % Empty strings are sorted to the beginning of B and I
        % so position in B of last empty string is at max(rmIdx) 
        % Set value in J to 0 at positions which are empty strings in A.
        rmIdx = find(cellfun('isempty',B));
        if not(isempty(rmIdx))
            J = J - max(rmIdx);
            J(J < 0) = 0;
            if isEqualNaNs
                J          = J + 1; % empty string at beginning
                rmIdx(1) = []; % preserve first instance
            end
        end
    end
    B(rmIdx) = [];
    I(rmIdx) = [];
end
