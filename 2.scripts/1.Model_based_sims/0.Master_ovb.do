*********************************************************************
* 			                                        				*
*   		The when, the why, and the how to impute: 			  	*
* A practitioners' guide to survey-to-survey imputation of poverty	*
* 			                                        				*
*********************************************************************  
*** Authors: Paul Corral, Leonardo Lucchetti, Andres Ham ***
*** THIS DO-FILE: Runs OVB results ****
*** VERSION: 08/15/2024 ***
 
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
if (lower("`c(username)'")=="wb378870"|lower("`c(username)'")=="paul corral"){
	global main    "C:/Users//`c(username)'//Github/S2S_RTM/"
}

global dpath   "$main/1.data"
global thedo   "$main/2.scripts/1.Model_based_sims"
global theado  "$main/2.scripts/0.ados"
global figs    "$main/5.figures"

run "$thedo\1.Model_based_sims\1.create_ovb_data.do"
run "$thedo\1.Model_based_sims\2.ovb_sim_new.do"