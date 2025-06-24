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
use "$dpath/srs_sample_t.dta", clear
append using "$dpath\full_sample_t.dta", gen(lamuestra)
	sort lamuestra hhid
	count if lamuestra==0
	rforest Y_B x1-x5 in 1/`r(N)', type(reg) numvars(3) iter(200) lsize(5)
	predict xb
		
	reg Y_B x1-x5 if lamuestra==0, r
	predict xb_ols, xb	
	
	gen mse_ols = (ln(e_y) - xb_ols)^2
	gen mse_rf  = (ln(e_y) - xb)^2

	
	xtile qrf    = xb     if lamuestra==1, nq(5)
	xtile qols   = xb_ols if lamuestra==1, nq(5)
	
	xtile qrf_in    = xb     if lamuestra==0, nq(5)
	xtile qols_in   = xb_ols if lamuestra==0, nq(5)
		
	tab qrf, gen(qrf_)
	tab qols, gen(qols_)
	tab qrf_in, gen(qrf_in_)
	tab qols_in, gen(qols_in_)
	
	
	groupfunction, mean(qrf_* qols_* mse_*) by(lamuestra) xtile(e_y) nq(5)
	
	gen sim = $zed
	
if ($zed==1) save "$dpath/results_micomps_pmt.dta", replace
else{
	append using "$dpath/results_micomps_pmt.dta"
	save "$dpath/results_micomps_pmt.dta", replace
}
