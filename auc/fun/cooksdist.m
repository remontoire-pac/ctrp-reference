function [keepPt,Dcook] = cooksdist(x,y0,beta0,alpha,opts)
% [keepPt,Dcook] = cooksdist(x,y0,beta0,alpha,opts)
%
% INPUT PARAMETERS
%      x : size (n) x 1 column vector (numeric)
%     y0 : size (n) x 1 column vector (numeric)(X x 1) column vector of directions (0 = sensitive; 1 = non-responsive)
%  beta0 : size 1 x 4 column vector (numeric parameters for sigmoid fit)
%   opts : curve fits options
%   
% OUTPUT
%  keepPt:   binary column vector of points to keep
%
% Created on 2013/04/05 Nicole E Bodycombe
% Modified by PAC 2013/06/26 to work with F-test cutoff
% Modified by PAC 2014/08/21 to default to 3-parameter fit

    if (nargin<5||isequal(opts,[]))
        opts = statset('TolX',1e-3,'TolFun',1e-3,'MaxFunEvals',1024, 'MaxIter',1024,...
            'Display','off','FunValCheck','off','Robust','off','WgtFun','logistic');
    end
    if (nargin<4||isequal(alpha,[]))
        alpha = 0.05;
    end
    
    assert(size(x,2)==1,'Input x must be a column vector.');
    assert(size(y0,2)==1,'Input y0 must be a column vector.');
    assert(size(x,1)==size(y0,1), 'Input x and y0 must have same number of elements.');
    assert(numel(beta0)==4&&size(beta0,2)==4,'Input beta0 must have 4 entries for sigmoid parameters.');
    assert(isscalar(alpha)&&alpha>0&&alpha<0.5,'Input alpha must be a significance threshold on (0,0.5).');

    [beta,~,~,~,mse] = nlinfit(x,y0,@sig3upper,beta0([1 2 4]),opts);
    
    n = numel(x);
    p = numel(beta);
    yy = sig3upper(beta,x);
    Dcook = nan(n,1);
    for i=1:n
        k = true(1,numel(x));
        k(i) = false;
        xc = x(k);
        y0c = y0(k);
        betac = nlinfit(xc,y0c,@sig3upper,beta0([1 2 4]),opts);
        ypred = sig3upper(betac,x);
        Dcook(i,1) = sum(power(yy-ypred,2))./(p*mse);
    end
    keepPt = (fcdf(Dcook,numel(beta0),numel(x)-numel(beta0))<(1-alpha));

end
