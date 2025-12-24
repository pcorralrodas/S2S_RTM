*********************************************************************
* 			                                        				*
*   		The when, the why, and the how to impute: 			  	*
* A practitioners' guide to survey-to-survey imputation of poverty	*
* 			                                        				*
*********************************************************************  
*** Authors: Paul Corral, Leonardo Lucchetti, Andres Ham ***
*** THIS DO-FILE: * Checks results from simulations ****
*** VERSION: 08/13/2024 ***

set more off
clear 


use "$dpath/results_micomps.dta", clear
	replace reference = "gini" if measure=="gini"
	egen double true = max(value*(method=="FULL")), by(sim reference measure)
	gen double bias  = (value - true)
	
	groupfunction, mean(bias) by(reference measure method)
	
gen conca = reference+measure+method
order conca, first
	
export excel using "$dpath/reweight.xlsx", sheet(data_micomps) sheetreplace first(variable)
