*********************************************************************
* 			                                        				*
*   		The when, the why, and the how to impute: 			  	*
* A practitioners' guide to survey-to-survey imputation of poverty	*
* 			                                        				*
*********************************************************************  
*** Authors: Paul Corral, Leonardo Lucchetti, Andres Ham ***
*** THIS DO-FILE: * Checks the imputation procedure...does the MI approach bring in additional noise? ****
*** VERSION: 08/13/2024 ***
clear

*===============================================================================
// STep 2: Follow rforest
*===============================================================================
use "$dpath/srs_sample_cluster.dta", clear
append using "$dpath\srs_sample_cluster_target.dta", gen(lamuestra)
	sort lamuestra hhid
	rforest Y_B x1-x5 in 1/1600, type(reg) numvars(3) iter(200) lsize(5)
	predict xb
	reg Y_B x1-x5 if lamuestra==0, r
	predict xb_ols, xb	
	drop if lamuestra==0
	
	xtile true = laverdad, nq(5)
	xtile qrf = xb, nq(5)
	xtile qols = xb_ols, nq(5)
	
	tab true,gen(true_)
	tab qrf, gen(qrf_)
	tab qols, gen(qols_)
	
	
	groupfunction, mean(qrf_* qols_*) by(true)
	
	gen sim = $zed
	
if ($zed==1) save "$dpath/results_micomps_pmt.dta", replace
else{
	append using "$dpath/results_micomps_pmt.dta"
	save "$dpath/results_micomps_pmt.dta", replace
}
