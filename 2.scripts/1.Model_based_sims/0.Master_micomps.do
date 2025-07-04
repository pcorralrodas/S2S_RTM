*********************************************************************
* 			                                        				*
*   		The when, the why, and the how to impute: 			  	*
* A practitioners' guide to survey-to-survey imputation of poverty	*
* 			                                        				*
*********************************************************************  
*** Authors: Paul Corral, Leonardo Lucchetti, Andres Ham ***
*** THIS DO-FILE: Runs the simulations that check the imputation procedure ****
*** VERSION: 08/13/2024 ***

* Initial options
version 15
set more off
clear all
* Do not change to obtain exact results
set seed 94131



* Runs processes
forval z=1/1000{
	global zed = `z'
	display in yellow "Simulation: `z'"	

	//Creates the data
	run "$thedo/1.creates_data.do" 

	//Runs the simulations
	run "$thedo/2.Mi_ebp_comps.do"
	
}

//Checks consistency
run "$thedo/3.check_results_Mi_ebp_comps.do"

