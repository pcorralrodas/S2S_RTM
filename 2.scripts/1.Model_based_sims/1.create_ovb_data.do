*********************************************************************
* 			                                        				*
*   		The when, the why, and the how to impute: 			  	*
* A practitioners' guide to survey-to-survey imputation of poverty	*
* 			                                        				*
*********************************************************************  
*** Authors: Paul Corral, Leonardo Lucchetti, Andres Ham ***
*** THIS DO-FILE: Creates data for simulations ****
*** VERSION: 08/14/2024 ***

clear
set more off

//Would you impute?
//Gini under log normal dist
local obsnum    = 20000 	//Number of observations in our survey
local outsample = 20	 	//sample size to take
local sigmaeps  = 0.5      	//Sigma eps

	
	//coefficients for eggs and conflict
	local b_eggs         = 0.4   
	local b_conflict     = -0.3
	local p_egg_conflict = -0.5
	local egg_increase   = 0.5
	

// Create area random effects
set obs `=`obsnum''

	//Household identifier
	gen hhid = _n
	//Household expansion factors - assume all 1
	gen hhsize = 1
	//Household specific residual	
	gen e = rnormal(0,`sigmaeps')
	//Covariates, some are corrlated to the area's label
	gen x1 = round(max(1,rpoisson(4)),1)
	gen x2 = runiform()<=(0.2) //*0.05*x1 //artificial correlation
	gen x3 = runiform()<(0.5) if x2==1
	replace x3 = 0 if x2==0
	gen x4 = rnormal(2.5, 2)
	gen x5  = rt(5)*.25
	//Create conflict variable, to indicate some form of conflict intensity
	gen conflict = runiform()<0.4
	//Create a dummy for whether or not the house bought eggs, notice it's
	//negatively related to conflict
	gen eggs = runiform()<=(.5 + `p_egg_conflict'*conflict) 

	//Welfare vector
	gen linear_fit = 3 + 0.1* x1 + 0.5* x2 - 0.25*x3 - 0.2*x4 - 0.15*x5 + `b_eggs'*eggs + `b_conflict'*conflict
	gen Y_B = linear_fit + e
	gen e_y = exp(Y_B)
	
	pctile ptiles= Y_B, nq(100)
	
	//Define poverty lines
	forval z=5(5)95{
		gen povline`z' = ptiles[`z']
	}

drop ptiles
*===============================================================================
// Now do the prediction model base on the baseline data
*===============================================================================
	
	reg Y_B x1 x2 x3 x4 x5 eggs, r //we omit conflict
	predict res, res
	//predicted original
	predict yb_pred, xb
	local RMSE = e(rmse)
	replace yb_pred = yb_pred + rnormal(0,`RMSE')
	//Plot residuals to illustrate that model residuals will still be normal
	qnorm res
	graph export "$figs\obv_sim_qnorm.eps", as(eps) replace
	
preserve
	gen all=1
	sp_groupfunction, poverty(Y_B yb_pred) povertyline(povline*) by(all)
	gen ptile = int(real(subinstr(reference,"povline","",.)))
	keep if measure=="fgt0"
	reshape wide value, i(ptile) j(variable) string

	//So first we want to show that the OVB model if applied to the same data
	// will produce an unbiased prediction
	twoway (line valueY_B ptile) (scatter valueyb_pred ptile, msize(medium) msymbol(X)), ///
	ytitle("Cumulative share of population" "(living on less than percentile value)") xtitle("2019 percentiles") legend(label(1 "True") label(2 "Predicted") pos(7))
	graph export "$figs\obv_pred_orig.eps", as(eps) replace
	
restore

//Add model parameters to data
char _dta[x1] `=_b[x1]'
char _dta[x2] `=_b[x2]'
char _dta[x3] `=_b[x3]'
char _dta[x4] `=_b[x4]'
char _dta[x5] `=_b[x5]'
char _dta[eggs] `=_b[eggs]'
char _dta[thecons] `=_b[_cons]'
char _dta[RMSE] `RMSE'
//Add original simulation parameters to the data
char _dta[b_eggs]         `b_eggs' 
char _dta[b_conflict]     `b_conflict'
char _dta[p_egg_conflict] `p_egg_conflict'
char _dta[egg_increase]   `egg_increase'

save "$dpath/data_ovb.dta", replace
