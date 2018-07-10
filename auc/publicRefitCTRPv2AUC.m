% Updated implementation of CTRPv2 area-under-curve (AUC) calculations
%
% Paul A. Clemons, Ph.D.
% Broad Institute
%
% Workflow:
%   - start with public data from NCI CTD^2 Data Portal
%   - reconcile any re-mapping between experiment identifiers and cell lines
%   - capture numeric code for cell growth mode (0=adherent; 1=mixed/other; 2=suspension)
%   - established fixed limits of area-under-curve (AUC) integration shared by all compounds
%   - fit curves according to reference implementation (implement.zip)
%   - apply post-fit quality-control measures according to reference implementation
%   - report AUC, log(EC50), and percent viability at maximum concentration
%   - omit problematic log(EC50) values due to extrapolation outside concentration range
%   - omit meaningless log(EC50) values when effect size is within DMSO-treatment noise
% 
% last modified 2018-07-09 (PAC)

% clean workspace and start counter
clear; close all; clc; tic;

% map a directory structure
wf = 'D:\auc'; % CHANGE to local path to publicRefitCTRPv2AUC.m
addpath(genpath([wf filesep 'fun'])); % need \fun, \fun\df, \fun\df\util
cd(wf); % work in main folder

% read data and and experiement metadata
dtScore = DFread('v20.data.per_cpd_pre_qc.txt',[wf filesep 'data'],16384);
mtExpt = DFread('v20.meta.per_experiment.txt',[wf filesep 'meta']);

% index dataframe with unique combinations of compound and experiment identifiers
[sptx,svals,sidx] = DFindex(dtScore,{'master_cpd_id','experiment_id'});

% reconcile relationships between experiment identifiers and cell lines
utExpt = unique([mtExpt.experiment_id mtExpt.master_ccl_id],'rows');
assert(isequal(utExpt(:,1),(1:max(utExpt(:,1)))'),'Experiment identifiers not unique or not in sequence.');
utGM = zeros(size(utExpt,1),1);
for u=1:size(utExpt,1)
    if (strcmp(unique(mtExpt.growth_mode(mtExpt.experiment_id==u)),'adherent'))
        utGM(u,1) = 0;
    elseif (strcmp(unique(mtExpt.growth_mode(mtExpt.experiment_id==u)),'suspension'))
        utGM(u,1) = 2;
    else
        utGM(u,1) = 1;
    end
end

% define curves to be fit (all of them!)
tCRC = 1:size(sidx,1);
nCRC = numel(tCRC);

% create MATLAB struct for curve-fitting results
CRC = struct();

% define concentration limits for area-under-curve (AUC) integration
t_mG = min(log2(dtScore.cpd_conc_umol)); 
t_xG = max(log2(dtScore.cpd_conc_umol));

% initialize curve-fit parameters and options
betaX = [NaN -1/log(19) 1 0]; 
opts = statset('TolX',1e-3,'TolFun',1e-3,'MaxFunEvals',1024, 'MaxIter',1024,...
    'Display','off','FunValCheck','off','Robust','off','WgtFun','logistic');

for tt=1:nCRC % for each curve to be fit
    
    t = tCRC(tt);

    % get data points for current curve fit and integration    
    tNP0 = numel(sptx{t});
    tQC = unique(dtScore.qc_type(sptx{t}));
    assert(isscalar(tQC),'Too many values of QCtype.');
    [tx,ti] = sort(log2(dtScore.cpd_conc_umol(cell2mat(sptx(t)))));
    ty = dtScore.cpd_avg_pv(cell2mat(sptx(t)));
    ty = ty(ti);
    
    % seed curve fit parameters and make initial guess for EC50 from the data
    beta0 = betaX;
    if (min(ty)<0.5)
        beta0(1) = tx(find(ty<0.5,1,'first'));
    else
        beta0(1) = median(tx);
    end
    
    % remove final two data points for QCtype=2
    if (tQC==2)
        tNP = tNP0-2;
        tx = tx(1:end-2);
        ty = ty(1:end-2);
    
    % remove final data point for QCtype=1
    elseif (tQC==1)
        tNP = tNP0-1;
        tx = tx(1:end-1);
        ty = ty(1:end-1);
    
    % apply Cook's distance censoring for QCtype=3
    elseif (tQC>2)
        tKP = cooksdist(tx,ty,beta0);
        if (ty(end-1)<0.5)  % disallow discard of penultimate point if ty<0.5
            tKP(end-1) = true;
        end
        if (ty(end)<0.5)    % disallow discard of final point if ty<0.5
            tKP(end) = true;
        end
        tx = tx(tKP);
        ty = ty(tKP);
        tNP = numel(tx);
    
    % otherwise keep all data points
    else
        tNP = tNP0;
    end
    
    % skip curves with fewer than 5 data points remaining
    if (tNP<5)
        CRC(tt).t = t;
        CRC(tt).master_cpd_id = svals.master_cpd_id(sidx(t,1));
        CRC(tt).experiment_id = svals.experiment_id(sidx(t,2));
        CRC(tt).tQC = tQC;
        CRC(tt).tNP0 = tNP0;
        CRC(tt).tNP = tNP;
        CRC(tt).tx = tx;
        CRC(tt).ty = ty;
        CRC(tt).tfx = NaN;
        CRC(tt).tci = NaN;
        CRC(tt).beta0 = beta0;
        CRC(tt).beta = NaN;
        CRC(tt).betaCI = NaN;
        CRC(tt).betaN = 0;
        CRC(tt).t_mG = t_mG;
        CRC(tt).t_xG = t_xG;
        CRC(tt).r_G = NaN;       
        continue;
    
    % fit curves with at least 5 data points remaining
    else
        
        % provisionally fit 3-parameter sigmoid curve to data points
        [beta,pRES,~,pCOV,pMSE] = nlinfit(tx,ty,@sig3upper,beta0([1 2 4]),opts);   
        [tfx,tci] = nlpredci(@sig3upper,tx,beta,pRES,'covar',pCOV,'mse',pMSE);
        betaCI = nlparci(beta,pRES,'covar',pCOV);
        r_G = integral(@(tx) sig3upper(beta,tx),t_mG,t_xG)./(t_xG-t_mG);
        
        % re-fit using 2-parameter sigmoid curve if initial EC50 is above the highest concentration
        if (beta(1)>tx(end))
            [beta,pRES,~,pCOV,pMSE] = nlinfit(tx,ty,@sig2both,beta0([1 2]),opts);   
            [tfx,tci] = nlpredci(@sig2both,tx,beta,pRES,'covar',pCOV,'mse',pMSE);
            betaCI = nlparci(beta,pRES,'covar',pCOV);
            r_G = integral(@(tx) sig2both(beta,tx),t_mG,t_xG)./(t_xG-t_mG);
        end
        
        betaN = numel(beta);
    end
    
    % add curve-fitting results to MATLAB struct
    CRC(tt).t = t;
    CRC(tt).master_cpd_id = svals.master_cpd_id(sidx(t,1));
    CRC(tt).experiment_id = svals.experiment_id(sidx(t,2));
    CRC(tt).tQC = tQC;
    CRC(tt).tNP0 = tNP0;
    CRC(tt).tNP = tNP;
    CRC(tt).tx = tx;
    CRC(tt).ty = ty;
    CRC(tt).tfx = tfx;
    CRC(tt).tci = tci;
    CRC(tt).beta0 = beta0;
    CRC(tt).beta = beta;
    CRC(tt).betaCI = betaCI;
    CRC(tt).betaN = betaN;
    CRC(tt).t_mG = t_mG;
    CRC(tt).t_xG = t_xG;
    CRC(tt).r_G = r_G;
    sprintf('Finished curve fit %i of %i.',tt,nCRC)
    
end

% create tabluar dataframe to hold one row per curve
A.area_under_curve = nan(numel(CRC),1);
A.ec50_log2_umol = A.area_under_curve;
A.pred_pv_high_conc = A.area_under_curve;
A.master_cpd_id = A.area_under_curve;
A.experiment_id = A.area_under_curve;
A.master_ccl_id = A.area_under_curve;
A.growth_mode_id = A.area_under_curve;

for z=1:nCRC % for each curve to be output 

    % no curve fit was attempted
    f0 = CRC(z).betaN==0;
    % fewer than 8 total points were used
    f1 = CRC(z).tNP<8;
    % Cook's distance censored more than 1/3 of the points
    f2 = CRC(z).tNP<(2/3)*CRC(z).tNP0;
    % no part of the fit curve is below PV = 1.25
    f3 = min(CRC(z).tfx)>1.25;
    % an increasing curve (within roundoff tolerance) starts below PV = 0.8
    f4 = (min(CRC(z).tfx)<0.8)&((CRC(z).tfx(end)-min(CRC(z).tfx))>(2*10^-5));
    % a predicted value falls below PV = -0.1
    f5 = min(CRC(z).tfx)<-0.1;
    % area-under-curve falls below -0.05
    f6 = CRC(z).r_G<-0.05;
    % area-under-curve exceeds 1.25, except sufficiently increasing curves
    f7 = (CRC(z).r_G>1.25)&(~(CRC(z).tfx(end)-min(CRC(z).tfx)>0.25));
    f = ~(f0|f1|f2|f3|f4|f5|f6|f7);
    
    % create output only if all quality-control conditions are met
    if(f)
        A.area_under_curve(z,1) = CRC(z).r_G;
        A.ec50_log2_umol(z,1) = CRC(z).beta(1);
        A.pred_pv_high_conc(z,1) = CRC(z).tfx(end);
        A.master_cpd_id(z,1) = CRC(z).master_cpd_id;
        A.experiment_id(z,1) = CRC(z).experiment_id;
        A.master_ccl_id(z,1) = utExpt(CRC(z).experiment_id,2);
        A.growth_mode_id(z,1) = utGM(CRC(z).experiment_id);
    end
    zz = toc;
    sprintf('Finished curve %i of %i after %d seconds.',z,nCRC,zz)
end

% remove problematic or meaningless log(EC50) values and missing AUCs
A.ec50_log2_umol(A.ec50_log2_umol<t_mG|A.ec50_log2_umol>t_xG|(A.pred_pv_high_conc<1.25&A.pred_pv_high_conc>0.8)) = NaN;
A = DFkeeprow(A,~isnan(A.area_under_curve));

% write output file with error-handling to main folder
q = DFwrite(A,'new-abs-auc-with-qc.txt');
assert(q==0,'Problem writing output file.');

toc;
