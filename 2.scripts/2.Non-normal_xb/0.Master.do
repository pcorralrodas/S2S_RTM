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

/*
* Required packages and files
cap: net install github, from(https://haghish.github.io/github/)
cap: ssc install groupfunction, replace
cap: github install pcorralrodas/sp_groupfunction
cap: github install pcorralrodas/wentropy
*/
*===============================================================================
		*Run necessary ado files
*===============================================================================

* Runs processes
forval z=1/1000{
	
	* Displays current simulation
	global zed = `z'
	display in yellow "Simulation: `z'"	
	 
	// A. Creates the data
	run "$thedo/1.creates_data.do" 

	// B. Runs the simulations
	run "$thedo/2.runs_simulations.do"

} 

// Illustrates the problem of changing constant
run "$thedo/3.Changing constant.do"
 
// Illustrates the problem of changing betas and sigma
run "$thedo/4.Changing_betas_sigmas_mu.do" 

//Changes in sigma e
run "$thedo/5.changing_sigma_e.do"

