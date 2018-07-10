# ctrp-reference/auc

Updated implementation of CTRPv2 area-under-curve (AUC) calculations

Paul A. Clemons, Ph.D.
Broad Institute
last modified 2018-07-09 (PAC)

Workflow:

   - start with public data from NCI CTD^2 Data Portal
   - reconcile any re-mapping between experiment identifiers and cell lines
   - capture numeric code for cell growth mode (0=adherent; 1=mixed/other; 2=suspension)
   - established fixed limits of area-under-curve (AUC) integration shared by all compounds
   - fit curves according to reference implementation (implement.zip)
   - apply post-fit quality-control measures according to reference implementation
   - report AUC, log(EC50), and percent viability at maximum concentration
   - omit problematic log(EC50) values due to extrapolation outside concentration range
   - omit meaningless log(EC50) values when effect size is within DMSO-treatment noise
 