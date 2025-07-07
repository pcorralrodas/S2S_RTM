*********************************************************************
* 			                                        				*
*   		The when, the why, and the how to impute: 			  	*
* A practitioners' guide to survey-to-survey imputation of poverty	*
* 			                                        				*
*********************************************************************  

 
* Initial options
version 15
set more off
clear all

* Do not change to obtain exact results
set seed 94131
set maxvar 15000

*===============================================================================
		*Run necessary ado files
*===============================================================================

* Runs processes
forval z=1/1000	{
	
	* Displays current simulation
	global zed = `z'
	display in yellow "Simulation: `z'"	
	 
	// A. Creates the data
	run "$thedo/1.creates_data_nonnormal.do" 
	
	// B. Runs the simulations
	do "$thedo/2.runs_simulations_nonnormal.do"
	
	// B. Runs the simulations
	run "$thedo/2.runs_simulations_nonnormal_oos.do"
	
	

} 

