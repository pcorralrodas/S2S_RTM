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

*===============================================================================
// Prep data
*===============================================================================

forval z=1/1000	{
	
	* Displays current simulation
	global zed = `z'
	display in yellow "Simulation: `z'"	
	 
	// A. Creates the data
	run "$thedo/1.create_data_RE.do" 

	// B. Runs the simulations
	run "$thedo/2.run_cluster_sims.do"

} 
