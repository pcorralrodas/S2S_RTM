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

//Would you impute?
//Gini under log normal dist
local obsnum    = 20000 	//Number of observations in our survey
local outsample = 20	 	//sample size to take
local sigmaeps  = 0.5      	//Sigma eps

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

//Household specific residual - heteroskedastic
// Generate independent variable x
generate x = rnormal(0.5, 0.5)

// Generate error term with multiplicative heteroskedasticity
// where variance increases with x
generate e = rnormal(0, exp((1/6)*x)/2)
	
gen Y_B = linear_fit + e
gen e_y = exp(Y_B)

pctile ptiles= e_y, nq(100)

forval z=5(5)95{
    gen povline`z' = ptiles[`z']
}

drop ptiles
//Get centiles of the population
xtile NQ = e_y, nq(100)

save "$dpath/full_sample_het.dta", replace


sample 20
sort hhid //sort to ensure replicability
save "$dpath/srs_sample_het.dta", replace


