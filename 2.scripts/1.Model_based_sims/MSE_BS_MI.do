*********************************************************************
* 			                                        				*
*   		The when, the why, and the how to impute: 			  	*
* A practitioners' guide to survey-to-survey imputation of poverty	*
* 			                                        				*
*********************************************************************  

clear all 
set more off

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
	
drop e Y_B ptiles


sort hhid
//Sample target data
	preserve
		sample 30
		sort hhid
		count
		local numT = r(N)
		tempfile target
		save `target'
	restore
//Sample source
	preserve
		sample 20
		sort hhid
		tempfile source
		save `source'
	restore
//Full Data
tempfile pop
save `pop'

	
tempfile true Mi pbs blup

forval SIM = 1/10000{
	use `pop', clear
	//Simulate error
	qui:gen e = rnormal(0, `sigmaeps')
	//Simulate Welfare
	qui:gen Y_B = linear_fit + e
	//Produce poverty
	forval z = 5(5)95{
		qui:gen poverty`z' = Y_B<povline`z' if !missing(Y_B)
	}
	groupfunction, mean(poverty*)
	gen source = "True"
	gen sim    = "`SIM'" 
	cap: append using `true'
	qui:save `true', replace
*===============================================================================
// MI
*===============================================================================	
	//Bring in the source survey...
	use `source', clear
	//Simulate error
	qui:gen e = rnormal(0, `sigmaeps')
	//Simulate Welfare
	qui:gen Y_B = linear_fit + e	
	//Append the target survey
	append using `target', gen(new)
	//Register MI data
	qui:mi set mlong
	qui:mi register imputed Y_B 
	//Model
	qui:mi impute reg Y_B  x1 x2 x3 x4 x5, add(`num_imp')
		
	//Caclulate poverty for the imputed vector
	forval z = 5(5)95{
		qui:gen poverty`z' = Y_B<povline`z' if !missing(Y_B)	
	}
	
	//Get the poverty rates by vector
	groupfunction, mean(poverty*) by(_mi_m) 
	qui:drop if _mi_m==0 //drop the original data
	local M = `num_imp'
	
	//Calculate the within variation
	forval z = 5(5)95{
		qui:gen var`z' = poverty`z'
		qui:gen w_`z'  = poverty`z'*(1-poverty`z')/`numT'
	}
	groupfunction, mean(poverty* w_*) var(var*)
	//Calculate the SE followign Rubin's rules
	forval z = 5(5)95{
		qui:gen se_`z' = sqrt(w_`z' +(1+1/`M')*var`z')
	}
	keep poverty* se_* 
	gen source = "MI `num_imp'"
	gen sim    = "`SIM'" 
	cap: append using `Mi'
	qui:save `Mi', replace
	
*===============================================================================
// PBS
*===============================================================================
	// Bring in the source
	use `source', clear
	forval bspop = 0/`totBS'{
		//Simulate error
		qui:gen e = rnormal(0, `sigmaeps')
		//Simulate Welfare
		qui:gen Y_B = linear_fit + e
		//Fit the model
		qui:reg Y_B x1 x2 x3 x4 x5, r
		forval beta = 1/5{
			local beta_`beta'_`bspop' = _b[x`beta']
		}
		local lacons_`bspop' = _b[_cons]
		local rmse_`bspop'   = e(rmse)
		drop e Y_B
	}
	
	//Bring in the target
	use `target', clear
	//Gen the BLUP
	gen xb = `lacons_0'
	forval beta = 1/5{
		qui:replace xb = xb + x`beta'*`beta_`beta'_0'
	}
	//Get blup poverty rates
	forval pov = 5(5)95{
		qui:gen poverty`pov'_0 = normal((povline`pov'-xb)/(`rmse_0'))
	}
	
	//Generate 100 vectors for PB-MSE
	forval bspop=1/`totBS'{
		qui:gen _`bspop'_Y_B = rnormal(xb, `rmse_0')
		//Blup BS
		//Gen the BLUP
		qui:gen xb_ = `lacons_`bspop''
		forval beta = 1/5{
			qui:replace xb_ = xb_ + x`beta'*`beta_`beta'_`bspop''
		}
		
		forval pov = 5(5)95{
			qui:gen tpoverty`pov'_`bspop' = _`bspop'_Y_B<povline`pov' if !missing(_`bspop'_Y_B)
			qui:gen poverty`pov'_`bspop' = normal((povline`pov'-xb_)/(`rmse_`bspop''))
		}
		drop xb_		
	}
	drop xb
	groupfunction, mean(poverty* tpoverty*) norestore
	forval pov = 5(5)95{
		qui:gen mse_`pov'=0
		forval bspop = 1/`totBS'{
			qui:replace mse_`pov' = mse_`pov' + (poverty`pov'_`bspop' - tpoverty`pov'_`bspop')^2	
		}
		qui: replace mse_`pov' = sqrt(mse_`pov'/`totBS') //we rename it later
	}
	
	keep mse_* poverty*_0
	rename poverty*_0 poverty*
	rename mse_* se_*
	
	gen source = "BLUP"
	gen sim    = "`SIM'" 
	cap: append using `blup'
	qui:save `blup', replace
	
	di as error "Simulation: `SIM'"
}

use `true', clear
append using `Mi'
append using `blup'

reshape long poverty se_, i(source sim) j(ptile)
gen  mse_ = se_^2
egen true = max(poverty*(source=="True")), by(sim ptile)

gen bias     = (poverty - true)
gen true_mse = bias^2



groupfunction, mean(bias true_mse mse) by(ptile source)
save "$dpath\MSE_BS.dta", replace

twoway (line true_mse ptile if source=="MI 20", lpattern(-) lcolor(blue)) ///
(line true_mse ptile if source=="BLUP", lpattern(-) lcolor(red)) ///
(scatter mse_ ptile if source=="MI 20", msymbol(Oh) mcolor(blue)) ///
(scatter mse_ ptile if source=="BLUP", msymbol(Oh) mcolor(red)), ///
legend(label(1 "True MI 20") label(2 "True BLUP") label(3 "MI 20") label(4 "BLUP")) ///
xtitle(Poverty rate) ytitle(MSE)

graph export "$figs\method_comp_MSE.jpg", as(jpg) name("Graph") quality(100) replace