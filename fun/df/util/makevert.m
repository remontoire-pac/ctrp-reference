function vector = makevert(vector, varargin)
% MAKEVERT
%        columnizes a comma separated list of n-dim arrays
%
%     vector = makevert(M)
%     vector = makevert(M1,M2,M3,...,Mk)
%
%     multiple inputs are expected to have compatible dimensions
%
%     Created June 28, 2007
%     Hy Carrinski
%     Broad Institute
%     note: CSL of strings --> Nx1 char array

if nargin > 1
   if numel(vector) > 1           % first input has dimension
       s = size(vector);
       if s(2) > s(1)
           vector = horzcat(vector,varargin{:});
       else
           vector = vertcat(vector,varargin{:});
       end
   else
       try
           vector = vertcat(vector,varargin{:});
       catch
           vector = horzcat(vector,varargin{:});
       end
   end
end
vector = reshape(vector,numel(vector),1);
