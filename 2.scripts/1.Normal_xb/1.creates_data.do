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
//Household specific residual	
gen e = rnormal(0,`sigmaeps')
//Covariates, some are corrlated to the area's label
gen x1 = round(max(1,rpoisson(4)),1)
gen x2 = runiform()<=(0.2) //*0.05*x1 //artificial correlation
gen x3 = runiform()<(0.5) if x2==1
replace x3 = 0 if x2==0
gen x4 = rnormal(2.5, 2)
gen x5  = rt(5)*.25


//Welfare vector
gen linear_fit = 3 + 0.1* x1 + 0.5* x2 - 0.25*x3 - 0.2*x4 - 0.15*x5 
gen Y_B = linear_fit + e
gen e_y = exp(Y_B)

pctile ptiles= e_y, nq(100)

forval z=5(5)95{
    gen povline`z' = ptiles[`z']
}

drop ptiles
//Get centiles of the population
xtile NQ = e_y, nq(100)

save "$dpath/full_sample.dta", replace

preserve
sample 20
sort hhid //sort to ensure replicability
save "$dpath/srs_sample.dta", replace
restore

//Lower sample at the bottom
preserve
	keep if NQ>=20
	sample 20, by(NQ)
	tempfile top80
	save `top80'
restore

forval z=1/19{
	preserve
		keep if NQ==`z'
		sample `z'
		append using `top80'	
		tempfile top80
		save `top80'
		count
	restore
}

use `top80', clear
sort hhid //sort to ensure replicability

save "$dpath/biased_sample.dta", replace

//Create biased sample at the top and the bottom

use "$dpath/full_sample.dta", clear

preserve
	keep if NQ>=20 & NQ<=80
	sample 20, by(NQ)
	tempfile top80P
	save `top80P'
restore

forval z=1/19{
	preserve
		keep if NQ==`z'
		sample `z'
		append using `top80P'	
		tempfile top80P
		save `top80P'
		count
	restore
	preserve
		keep if NQ==100-`z'
		sample `z'
		append using `top80P'
		tempfile top80P
		save `top80P'	
	restore
}
use `top80P', clear
sort hhid //sort to ensure replicability
save "$dpath/biased_sample_topbottom.dta", replace

