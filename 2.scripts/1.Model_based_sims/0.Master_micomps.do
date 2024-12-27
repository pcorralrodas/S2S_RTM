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

/* Required packages and files
cap: net install github, from(https://haghish.github.io/github/)
cap: ssc install groupfunction, replace
cap: github install pcorralrodas/sp_groupfunction
cap: github install pcorralrodas/wentropy
*/
* Do not change to obtain exact results
set seed 94131

* Paths
*** CHANGE THE FIRST GLOBAL TO THE DIRECTORY WHERE YOU DOWNLOADED THE REPLICATION FILES ***
if (lower("`c(username)'")=="ham_andres"){
	global main    "/Users/ham_andres/Library/CloudStorage/Dropbox/research/wb/S2S/"
}
if (lower("`c(username)'")=="wb378870"|lower("`c(username)'")=="paul corral"){
	global main    "C:/Users//`c(username)'//Github/S2S_RTM/"
}

global dpath   "$main/1.data"
global thedo   "$main/2.scripts/1.Model_based_sims"
global theado  "$main/2.scripts/0.ados"
global figs    "$main/5.figures"

/*
*===============================================================================
		*Run necessary ado files
*===============================================================================
	local files : dir "$theado" files "*.ado"
	foreach f of local files{
		dis in yellow "`f'"
		qui: run "$theado//`f'"
	}
*/
*===============================================================================
		*Run necessary ado files
*===============================================================================

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

