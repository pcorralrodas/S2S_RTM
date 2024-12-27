*********************************************************************
* 			                                        				*
*   		The when, the why, and the how to impute: 			  	*
* A practitioners' guide to survey-to-survey imputation of poverty	*
* 			                                        				*
*********************************************************************  
*** Authors: Paul Corral, Leonardo Lucchetti, Andres Ham ***
*** THIS DO-FILE: Runs simulations (described below) ****
*** VERSION: 08/14/2024 ***

/*
As survey-to-survey imputation models make use of predictors from two different surveys, 
the relationship between consumption and the predictors needs to be the same in both 
(Christiaensen et al. 2012; Harttgen et al. 2012). 

In this experiment, we will modify three things:
1) the mean of X4
2) the SD of X4
3) The beta on x4
*/
clear 
set more off

//Would you impute?
//Gini under log normal dist
local obsnum    = 20000 //Number of observations in our survey
local outsample = 20	 	//sample size to take
local sigmaeps = 0.5      //Sigma eps
local beta4 = 0.2
local mu_x4 = 2.5
local sd_x4 = 2
**# Bookmark #1


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
	gen linear_fit = 3 + 0.1* x1 + 0.5* x2 - 0.25*x3 - `beta4'*x4 - 0.15*x5 
	//Household specific residual	
	gen e = rnormal(0,`sigmaeps')
	
	gen Y_B = linear_fit + e
	gen e_y = exp(Y_B)
	
	pctile ptiles= e_y, nq(100)
	
	forval z=5(5)95{
		gen povline`z' = ptiles[`z']
	}

*===============================================================================
// Ok, now do the sims
// Adjust the beta...
*===============================================================================
forval z = -0.25(0.01)0.25{
	local nm = round(abs(`z')*100)
	local my_beta = (1+`z')*`beta4'
	if (`z'<0){		
		gen b_n`nm' = linear_fit - `beta4'*x4 + `my_beta'*x4
		replace b_n`nm' = exp(b_n`nm' + e)
	}
	else{
		gen b_`nm' = linear_fit - `beta4'*x4 + `my_beta'*x4
		replace b_`nm' = exp(b_`nm' + e)
	}   	
}

*===============================================================================
// Ok, now do the sims
// Adjust the sd of x4
*===============================================================================
forval z = -0.25(0.01)0.25{
	local nm = round(abs(`z')*100)
	local my_sd = (1+`z')*`sd_x4'
	gen new_x4 = rnormal(`mu_x4',`my_sd')
	if (`z'<0){		
		gen sd_n`nm' = linear_fit - `beta4'*x4 + `beta4'*new_x4
		replace sd_n`nm' = exp(sd_n`nm' + e)
	}
	else{
		gen sd_`nm' = linear_fit - `beta4'*x4 + `beta4'*new_x4
		replace sd_`nm' = exp(sd_`nm' + e)
	}  
 	drop new_x4
}
*===============================================================================
// Ok, now do the sims
// Adjust the mean of x4
*===============================================================================
forval z = -0.25(0.01)0.25{
	local nm = round(abs(`z')*100)
	local my_mu = (1+`z')*`mu_x4'
	gen new_x4 = rnormal(`my_mu',`sd_x4')
	if (`z'<0){		
		gen mu_n`nm' = linear_fit - `beta4'*x4 + `beta4'*new_x4
		replace mu_n`nm' = exp(mu_n`nm' + e)
	}
	else{
		gen mu_`nm' = linear_fit - `beta4'*x4 + `beta4'*new_x4
		replace mu_`nm' = exp(mu_`nm' + e)
	} 
  	drop new_x4
}

gen all = 1
drop e_y
sp_groupfunction, poverty(b_* sd_* mu_*) povertyline(povline*) gini(b_* sd_* mu_*) by(all)
split variable, parse(_)
replace variable2 = subinstr(variable2,"n","-",.)
gen pchange_sigma = real(variable2)
drop variable1 variable2

export excel using "$main/1.data/Changing sigma.xlsx", sheet(changing_beta_sd_mu) sheetreplace first(variable)


