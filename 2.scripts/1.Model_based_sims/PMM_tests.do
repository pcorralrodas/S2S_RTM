*********************************************************************
* 			                                        				*
*   		The when, the why, and the how to impute: 			  	*
* A practitioners' guide to survey-to-survey imputation of poverty	*
* 			                                        				*
*********************************************************************  
*** Authors: Paul Corral, Leonardo Lucchetti, Andres Ham ***
*** THIS DO-FILE: Creates data for simulations ****
*** VERSION: 08/14/2024 ***

clear all 
set more off

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


//Would you impute?
//Gini under log normal dist
local obsnum    = 20000 	//Number of observations in our survey
local outsample = 20	 	//sample size to take
local sigmaeps  = 0.5      	//Sigma eps
local num_imp   = 20
local totBS     = 100

set seed 966875
// Create area random effects
set obs `=`obsnum''

//Household identifier
gen hhid = _n
//Household expansion factors - assume all 1
gen hhsize = 1
//Covariates, some are corrlated to the area's label
gen x1 = round(max(1,rpoisson(4)),1)
gen x2 = runiform()<=(0.2) //*0.05*x1 //artificial correlation
gen x3 = runiform()<(0.5) if x2==1
replace x3 = 0 if x2==0
gen x4 = rnormal(2.5, 2)
gen x5  = rt(5)*.25
//Welfare vector
gen linear_fit = 3 + 0.1* x1 + 0.5* x2 - 0.25*x3 - 0.2*x4 - 0.15*x5 

*The below is just to calculate the original pov lines
	//Simulate error
	gen e = rnormal(0, `sigmaeps')
	//Simulate Welfare
	gen Y_B = linear_fit + e
	
	
	pctile ptiles= Y_B, nq(100)
	
	forval z=5(5)95{
		gen povline`z' = ptiles[`z']
	}
	
gen year = 1

sample 30 //30% sample for speediness
tempfile source
save `source'
*===============================================================================
// Now produce new welfare, only change x2
*===============================================================================
use `source', clear
replace hhid = hhid+100000
	// Assume only X2 changed...
	replace x2 = runiform()<=(0.8)
	gen Y_Bn = 3 + 0.1* x1 + 0.5* x2 - 0.25*x3 - 0.2*x4 - 0.15*x5  + rnormal(0,`sigmaeps') 
	replace year = 2
	drop Y_B
append using `source'
mi set mlong
mi register imputed Y_B

mi impute pmm Y_B x1 x2 x3 x4 x5, bootstrap add(20) rseed(6349) knn(4)

reg Y_B x1 x2 x3 x4 x5 if year==1, r 
predict thenewY if year==2,xb
sum _mi_m
forval z = 1/`r(max)'{
	replace thenewY = rnormal(thenewY,e(rmse)) if _mi_m==`z'
}




	//Caclulate poverty for the imputed vector
	forval z = 5(5)95{
		qui:gen poverty`z'    = Y_B<povline`z' if !missing(Y_B)	
		qui:gen tpoverty`z'   = Y_Bn<povline`z' if !missing(Y_Bn)
		qui:gen olspoverty`z' = thenewY<povline`z' if !missing(thenewY)
	}
	
	drop if year==2 & _mi_m==0
	replace _mi_m = 999 if _mi_m!=0
	//Get the poverty rates by vector
	
	sum Y_B if _mi_m!=0, d
	sum Y_Bn,d
	
	pctile uno = Y_B if _mi_m!=0, nq(100)
	pctile dos = Y_Bn if _mi_m!=0, nq(100)
	gen rank = _n
	
	twoway (scatter uno rank if !missing(uno)) ///
	(scatter dos rank if !missing(uno), msymbol(Oh)), ///
	legend(label(1 "Predicted") label(2 "True") pos(7) cols(2))
	
	groupfunction, mean(*poverty*) by(_mi_m) 
	reshape long poverty tpoverty olspoverty,i(_mi_m) j(ptile)
	
//We want to see true change vs predicted change...	
	egen true = max(tpoverty*(_mi_m!=0)), by(ptile)
	egen predicted = max(poverty*(_mi_m!=0)), by(ptile)
	egen pred_ols  = max(olspoverty*(_mi_m!=0)), by(ptile)
	drop if _mi_m==999
	gen true_change     = 100*(true - poverty)/poverty
	gen pred_change     = 100*(predicted - poverty)/poverty
	gen pred_change_ols = 100*(pred_ols - poverty)/poverty
	
twoway (line true_change ptile ) /// 
(scatter pred_change ptile) ///
(scatter pred_change_ols ptile), ///
legend(label(1 "True change") label(2 "Predicted change PMM") ///
label(3 "Predicted change assuming normal errors") ///
pos(7) cols(2)) xtitle (Poverty rate period 1) ytitle(Change (%))

graph export "$figs\method_comp_PMM1.eps", as(eps) name("Graph") replace

	replace true_change = true_change*poverty
	replace pred_change = pred_change*poverty
	replace pred_change_ols = pred_change_ols*poverty 
	
twoway (line true_change ptile ) ///
(scatter pred_change ptile) ///
(scatter pred_change_ols ptile, msymbol(Oh)), ///
legend(label(1 "True change") label(2 "Predicted change") ///
label(3 "Predicted change Normal") ///
pos(7) cols(2)) xtitle (Poverty rate period 1) ytitle(Difference (pp))

graph export "$figs\method_comp_PMMpp1.eps", as(eps) name("Graph") replace

*===============================================================================
// Now produce new welfare, only gor incomes by 20% - a 4 year growth of 4.66%
*===============================================================================
use `source', clear
replace hhid = hhid+100000
// True period 2 welfare...
gen Y_Bn = ln(exp(Y_B)*(1.2)) 
replace year = 2
drop Y_B
append using `source'
mi set mlong
mi register imputed Y_B

mi impute pmm Y_B x1 x2 x3 x4 x5, bootstrap add(20) rseed(6349) knn(4)


//Caclulate poverty for the imputed vector
	forval z = 5(5)95{
		qui:gen poverty`z' = Y_B<povline`z' if !missing(Y_B)
		qui:gen tpoverty`z' = Y_Bn<povline`z' if !missing(Y_Bn)
	}
	
	replace _mi_m = 999 if _mi_m!=0
	//Get the poverty rates by vector
	
	sum Y_B if _mi_m!=0, d
	sum Y_Bn,d
	
	pctile uno = Y_B if _mi_m!=0, nq(100)
	pctile dos = Y_Bn if _mi_m!=0, nq(100)
	gen rank = _n
	
	twoway (scatter uno rank if !missing(uno)) ///
	(scatter dos rank if !missing(uno), msymbol(Oh)), ///
	legend(label(1 "Predicted") label(2 "True") pos(7) cols(2))
	
	groupfunction, mean(poverty* tpoverty*) by(_mi_m) 
	reshape long poverty tpoverty,i(_mi_m) j(ptile)
	
//We want to see true change vs predicted change...	
	egen true = max(tpoverty*(_mi_m!=0)), by(ptile)
	egen predicted = max(poverty*(_mi_m!=0)), by(ptile)
	drop if _mi_m==999
	gen true_change = 100*(true - poverty)/poverty
	gen pred_change = 100*(predicted - poverty)/poverty
	
twoway (line true_change ptile ) (scatter pred_change ptile), ///
legend(label(1 "True change") label(2 "Predicted change") ///
pos(7) cols(2)) xtitle (Poverty rate period 1) ytitle(Change (%))

graph export "$figs\method_comp_PMM.eps", as(eps) name("Graph") replace

	replace true_change = true_change*poverty
	replace pred_change = pred_change*poverty
	
twoway (line true_change ptile ) (scatter pred_change ptile), ///
legend(label(1 "True change") label(2 "Predicted change") ///
pos(7) cols(2)) xtitle (Poverty rate period 1) ytitle(Difference (pp))

graph export "$figs\method_comp_PMMpp.eps", as(eps) name("Graph") replace

//The predictions are worse at the bottom since the the
	
	