*********************************************************************
* 			                                        				*
*   		The when, the why, and the how to impute: 			  	*
* A practitioners' guide to survey-to-survey imputation of poverty	*
* 			                                        				*
*********************************************************************  
*** Authors: Paul Corral, Leonardo Lucchetti, Andres Ham ***
*** THIS DO-FILE: Runs simulations that assume that just the constant has shifted ****
*** VERSION: 08/14/2024 ***

clear 
set more off

//Would you impute?
//Gini under log normal dist
local obsnum    = 20000 //Number of observations in our survey
local outsample = 20	 	//sample size to take
local sigmaeps = 0.5      //Sigma eps
local lacons   = 3


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

//Welfare vector linear part, no constant...
gen linear_fit = `lacons' + 0.1* x1 + 0.5* x2 - 0.25*x3 - 0.2*x4 - 0.15*x5 
//Household specific residual	
gen e = rnormal(0,`sigmaeps')

gen Y_B = linear_fit + e
gen e_y = exp(Y_B)

pctile ptiles= e_y, nq(100)

forval z=5(5)95{
    gen povline`z' = ptiles[`z']
}


//Assume that just the constant has shifted
forval z = -0.25(0.01)0.25{
	local nm = round(abs(`z')*100)
	local my_cons = (1+`z')*`lacons'
	if (`z'<0){		
		gen e_n`nm' = linear_fit - `lacons' + `my_cons' + e
		replace e_n`nm' = exp(e_n`nm')
	}
	else{
		gen e_`nm'  = linear_fit - `lacons' + `my_cons' + e
		replace e_`nm' = exp(e_`nm')
	}   	
}

gen all = 1

compare e_0 e_y
drop e_0
rename e_y e_0


sp_groupfunction, poverty(e_n* e_*) povertyline(povline*) gini(e_n* e_*) by(all)
split variable, parse(_)
replace variable2 = subinstr(variable2,"n","-",.)
gen pchange_constant = real(variable2)
drop variable1 variable2

export excel using "$main/1.data/Changing constant.xlsx", sheet(changing_constant) sheetreplace first(variable)

