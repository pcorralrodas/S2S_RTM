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

global dpath   "$main/1.data/3.Mexican/"
global thedo   "$main/2.scripts/3.Mexican_sims/"
global theado  "$main/2.scripts/0.ados"
global figs    "$main/5.figures/3.Mexican/"
global mex     "C:\Users\WB378870\GitHub\Poverty-Mapping\Data\"

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
//run "$thedo\1.mex_create_data.do"
//run "$thedo\1_5.mex_pov_rates.do"
run "$thedo\2.mex_lasso.do"
run "$thedo\2.mex_sims_ols_e.do"
run "$thedo\2.mex_rf.do"

global ladep lny_nonnormal_8
run "$thedo\2.mex_sims_nonnormal.do"
run "$thedo\2.mex_sims_nonnormal_hetmi100bs.do"
run "$thedo\2.mex_sims_nonnormal_hetmi20bs.do"
run "$thedo\2.mex_sims_nonnormal_mi20bs.do"


global ladep lny_nonnormal
run "$thedo\2.mex_sims_nonnormal.do"
run "$thedo\2.mex_sims_nonnormal_hetmi100bs.do"
run "$thedo\2.mex_sims_nonnormal_hetmi20bs.do"
run "$thedo\2.mex_sims_nonnormal_mi20bs.do"


run "$thedo\2.mex_sims_het.do" 
//run "$thedo\2.mex_sims_normal.do" //already run, results make sense
//run "$thedo\2.mex_sims_normal_mi.do" //already run, results make sense
//run "$thedo\2.mex_sims_normal_mi100.do" //already run, results make sense


*===============================================================================
// FIGURES
*===============================================================================
run "$thedo\998.figures_check_mex.do"


