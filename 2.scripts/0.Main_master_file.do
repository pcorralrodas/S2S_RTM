*********************************************************************
* 			                                        				*
*   		The when, the why, and the how to impute: 			  	*
* A practitioners' guide to survey-to-survey imputation of poverty	*
* 			                                        				*
*********************************************************************  
*** Authors: Paul Corral, Andres Ham, Leo Lucchetti, Pete Lanjouw, Henry Stemmler ***
* Initial options
version 15
set more off
clear all

* Do not change to obtain exact results
set seed 94131

* Paths
*** CHANGE THE FIRST GLOBAL TO THE DIRECTORY WHERE YOU DOWNLOADED THE REPLICATION FILES ***
if (lower("`c(username)'")=="ham_andres"){
	global main    "/Users/ham_andres/Library/CloudStorage/Dropbox/research/wb/S2S/"
}
if (lower("`c(username)'")=="wb378870"){
	global main    "C:/Users//`c(username)'//Github/S2S_RTM/"
}
if (lower("`c(username)'")=="paul corral"){
	global main "C:\Users\Paul Corral\Documents\GitHub\S2S_RTM\"
}

global dpath   "$main/1.data"
global thedo   "$main/2.scripts/1.Model_based_sims"
global theado  "$main/2.scripts/0.ados"
global figs    "$main/5.figures"
/*
* Required packages and files
cap: net install github, from(https://haghish.github.io/github/)
cap: ssc install groupfunction, replace
cap: github install pcorralrodas/sp_groupfunction
cap: github install pcorralrodas/wentropy
*/


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

*===============================================================================
// Results 
*===============================================================================
run "$thedo\Why_errors.do"
run "$thedo\0.Master_micomps.do"
run "$thedo\0.Master_nonnormal.do"
run "$thedo\0.Master_het.do"
run "$thedo\0.Master_RE.do"
run "$thedo\PMM_tests.do"
run "$thedo\MSE_BS_MI.do"
run "$thedo\0.Master.do"
run "$thedo\0.Master_ovb.do"
run "$thedo\0.Master_PMT.do"

*===============================================================================
// FIGURES
*===============================================================================
run "$thedo\998.figures_check.do"


