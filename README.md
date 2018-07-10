# ctrp-reference

MATLAB reference implementation of foundational data-analysis procedures underlying results in the Cancer Therapeutics Response Portal (CTRP; https://portals.broadinstitute.org/ctrp/), which presents analysis results stemming from small-molecule sensitivity profiling of cancer cell lines. 

Data and metadata required to run the reference implementation (implement.zip) are available for free public download from the National Cancer Institute (NCI) Office of Cancer Genomics (OCG), and were originally produced as part of work supported by the Cancer Target Discovery and Development (CTD^2) Network of research centers.

To use the code, download and unpack the reference implementation (implement.zip) somewhere visible to the MATLAB search path. Next, DOWNLOAD DATA from ftp://caftpd.nci.nih.gov/pub/OCG-DCC/CTD2/Broad/.

Put the following files in a 'data' subfolder: v20.data.per_cpd_pre_qc.txt, v21.data.auc_sensitivities.txt, v21.data.gex_avg_log2.txt, v22.anno.ccl_anno_features.txt, v22.anno.ccl_mut_features.txt, v22.data.auc_sensitivities.txt.

Put the following files in a 'meta' subfolder: v20.meta.per_cell_line.txt, v20.meta.per_compound.txt, v20.meta.per_experiment.txt, v21.meta.gex_features.txt, v21.meta.per_compound.txt, v22.meta.per_compound.txt.

The reference implementation (implement.zip) covers three procedures in detail:

•	Procedure 1: preparation of concentration-response areas-under-curve (AUCs) as a measure of small-molecule sensitivity

•	Procedure 2: enrichment analysis of mutation features among cell lines of a particular lineage sensitive to individual compounds

•	Procedure 3: correlation analysis of basal gene-expression levels to compound sensitivity across panels of cell lines from a particular lineage

The reference implementation was initially developed on a Dell OptiPlex 9020 (Intel i7-4790 CPU @ 2x3.60GHz, 32.0 GB RAM) running 64-bit Windows 7 Enterprise, Service Pack 1, and MATLAB 2014b. Development was completed, and main testing performed, on a virtual machine (Intel Xeon CPU E5-2695 v4 @ 2x2.10GHz, 32.0 GB RAM) running Windows Server 2016 Datacenter and MATLAB 2018a. Development was initiated in MATLAB 2014b, and this is the earliest version of MATLAB that can execute the complete procedure as written, due to the addition of fishertest.m in that revision. The procedure requires the MATLAB Statistics and Machine Learning Toolbox (just called the Statistics Toolbox in MATLAB 2014b), along with the included custom functions. The reference code package should run in 5-10 minutes and creates 3 figures, with some variation per instantiation depending on a random component of data subset selection for analysis.
