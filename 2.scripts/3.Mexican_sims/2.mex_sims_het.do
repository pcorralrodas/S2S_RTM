set more off
clear all

set seed 3739

*========================================================================
//Bring in the full data and get plines
*========================================================================
	
	foreach x in lny_het{
		use `x' hhsize using "$dpath\mex_census.dta", clear
		global themodel : char _dta[model]
		pctile pct_`x' = `x' [aw=hhsize], nq(100)
		forval z=5(5)95{
			local pline_`z' = pct_`x'[`z']
		}
	}	
	
*=======================================================================
//Pick a random sample from 1 to 500 to act as source survey
************************************************************************
local sample_num = int(runiform()*500)
use "$mex\my_samples_pps_psu@.dta" if sim_sample==`sample_num', clear

merge 1:1 hhid using "$dpath\mex_census.dta"
	drop if _m!=3
	drop _m
	
*=======================================================================
//Models
************************************************************************
//Normal
reg lny_het $themodel [aw=Whh], r
global ols_rmse = e(rmse)

foreach x of global themodel{
	local `x' = _b[`x']
}
	local lacons = _b[_cons]
	
//Het
hetregress lny_het $themodel [aw=Whh], mle het(xhet)

//Now, predict
use "$mex\my_samples_pps_psu@.dta" if inrange(sim_sample,501,1000), clear

merge m:1 hhid using "$dpath\mex_census.dta"
	drop if _m!=3
	drop _m

//Predict model with RE, note that area effects are ignored!
predict double xb_het, xb
drop if missing(xb_het)
predict er, sigma


//Predict ols
gen double xb_ols = `lacons'
foreach x of global themodel{
	replace xb_ols = xb_ols + `x'*``x''
}

//Get poverty rates
forval z=5(5)95{
	gen ols_pov_`z' = normal((`pline_`z'' - xb_ols)/${ols_rmse})
	gen het_pov_`z' = normal((`pline_`z'' - xb_het)/er)
	gen direct_pov_`z'  = lny_het<`pline_`z'' if !missing(lny_het)
}

gen popw = Whh*hhsize
keep ols_pov* het_pov* direct_* Whh sim_sample popw
sp_groupfunction [aw=popw], mean(ols_pov* het_pov* direct_*) by(sim_sample)

save "$dpath\het_mex_results.dta", replace

