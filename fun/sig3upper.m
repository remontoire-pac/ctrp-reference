function A = sig3upper(p, X)
% A = sig3upper(p, X)
% basic 3-parameter sigmoid with fixed (=1) left asymptote
% last modified 2014/08/07 PAC

    alpha  = p(1);      % EC50
    beta  = p(2);       % slope
    b = p(3);           % lower limit
    
    A = b+(1-b)./(1+exp(-(X-alpha)./beta));

end
