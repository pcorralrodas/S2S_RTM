*********************************************************************
* 			                                        				*
*   		The when, the why, and the how to impute: 			  	*
* A practitioners' guide to survey-to-survey imputation of poverty	*
* 			                                        				*
*********************************************************************  
*** Authors: Paul Corral, Leonardo Lucchetti, Andres Ham ***
*** THIS DO-FILE: Creates data for simulations ****
*** VERSION: 12/27/2024***

forval sim = 1/1000{
	clear all
	
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
		
		pctile ptiles= Y_B, nq(100)
		
		//Define poverty lines
		forval z=5(5)95{
			gen povline`z' = ptiles[`z']
		}
		
		forval z= 5(5)95{
			gen true_`z' =  Y_B<povline`z' if !missing(Y_B)
			forval zz = -0.25(0.05)0.25{
				local nm = ceil(abs(`=`zz'*100'))
				if (`zz'<0) local nm n`nm'
				local lasigma = `sigmaeps'*(1+`zz')
				gen pred_`nm'_`z' = normal((povline`z' - linear_fit)/(`lasigma'))
			}
		}
		
	groupfunction, mean(pred_* true_*)
	gen sim = "`sim'"
	cap append using `lassim'
	tempfile lassim
	save `lassim'	
}

sp_groupfunction, mean(pred* true*) by(sim)


save "$dpath/sigma_e_results.dta", replace

	

