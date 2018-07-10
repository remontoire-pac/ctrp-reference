function A = sig2both(p, X)
% A = sig2both(p, X)
% basic 2-parameter sigmoid with fixed (=1) left and right (=0) asymptote
% last modified 2013/04/09 PAC

    alpha  = p(1); % IC50
    beta  = p(2); % slope
    
    A = 1./(1+exp(-(X-alpha)./beta));

end
