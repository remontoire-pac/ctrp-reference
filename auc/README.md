# ctrp-reference/auc

Updated implementation of CTRPv2 area-under-curve (AUC) calculations

Paul A. Clemons, Ph.D. (Broad Institute); last modified 2018-07-10

Data and metadata required to run are available for free public download from the National Cancer Institute (NCI) Office of Cancer Genomics (OCG), and were originally produced as part of work supported by the Cancer Target Discovery and Development (CTD^2) Network of research centers. DOWNLOAD DATA from ftp://caftpd.nci.nih.gov/pub/OCG-DCC/CTD2/Broad/.

Put the following file in a 'data' subfolder: v20.data.per_cpd_pre_qc.txt.

Put the following file in a 'meta' subfolder: v20.meta.per_experiment.txt.

Workflow:

   - start with public data from NCI CTD^2 Data Portal
   - reconcile any re-mapping between experiment identifiers and cell lines
   - capture numeric code for cell growth mode (0=adherent; 1=mixed/other; 2=suspension)
   - establish fixed limits of area-under-curve (AUC) integration shared by all compounds
   - fit curves according to reference implementation (implement.zip)
   - normalize AUC values on the interval [0,1] (1 = DMSO treatment; 0 = complete killing)
   - apply post-fit quality-control measures according to reference implementation
   - report AUC, log(EC50), and percent viability at maximum concentration
   - omit problematic log(EC50) values due to extrapolation outside concentration range
   - omit meaningless log(EC50) values when effect size is within DMSO-treatment noise
 