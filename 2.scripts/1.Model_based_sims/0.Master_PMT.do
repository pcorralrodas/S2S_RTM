*********************************************************************
* 			                                        				*
*   		The when, the why, and the how to impute: 			  	*
* A practitioners' guide to survey-to-survey imputation of poverty	*
* 			                                        				*
*********************************************************************  
*** Authors: Paul Corral, Leonardo Lucchetti, Andres Ham ***
*** THIS DO-FILE: Runs all the model-based simulations for S2S results ****
*** VERSION: 08/15/2024 ***
 
* Initial options
version 15
set more off
clear all

* Do not change to obtain exact results
set seed 94131
set maxvar 15000
* Paths
*** CHANGE THE FIRST GLOBAL TO THE DIRECTORY WHERE YOU DOWNLOADED THE REPLICATION FILES ***

*===============================================================================
		*Run necessary ado files
*===============================================================================

//run "$main\2.scripts\0.ado_files\rforest.ado"
* Runs processes
forval z=1/1000	{
	
	* Displays current simulation
	global zed = `z'
	display in yellow "Simulation: `z'"	
	 
	// A. Creates the data
	run "$thedo/1.creates_data_nonnormal.do" 

	// B. Runs the simulations
	run "$thedo/2.runs_simulations_pmt.do"
} 

use "$dpath/results_micomps_pmt.dta", clear

//MSE by sample type and method
tabstat mse*, by(lam)

sp_groupfunction, mean( qrf_1 qrf_2 qrf_3 qrf_4 qrf_5 qrf_in_1 qrf_in_2 qrf_in_3 qrf_in_4 qrf_in_5 qols_1 qols_2 qols_3 qols_4 qols_5 qols_in_1 qols_in_2 qols_in_3 qols_in_4 qols_in_5) by(e_y)

gen method = "RF"*regexm(variable,"rf")+ "OLS"*regexm(variable,"ols")
gen sample = "OOS"*(regexm(variable,"in")==0) + "In-sample"*regexm(variable,"in")

gen Qtile = substr(variable,-1,1)

export excel using "$dpath\trans_matrix.xlsx", sheet(tmat) sheetreplace first(variable)
