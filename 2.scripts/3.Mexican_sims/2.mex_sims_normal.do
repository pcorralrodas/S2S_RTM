set more off
clear all

set seed 3739

*========================================================================
//Bring in the full data and get plines
*========================================================================
	
	foreach x in lny_normal{
		use `x' using "$dpath\mex_census.dta", clear
		global themodel : char _dta[model]
		pctile pct_`x' = `x', nq(100)
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
//Normal errors
************************************************************************
reg lny_normal $themodel [aw=Whh], r
global ols_rmse = e(rmse)

foreach x of global themodel{
	local `x' = _b[`x']
}
	local lacons = _b[_cons]
	
//Cluster
sae model h3 lny_normal $themodel [aw=Whh], area(HID_mun) method(luinv_la)
	global eta_var =  e(eta_var)
    global eps_var =  e(eps_var)

use "$mex\my_samples_pps_psu@.dta" if inrange(sim_sample,501,1000), clear

merge m:1 hhid using "$dpath\mex_census.dta"
	drop if _m!=3
	drop _m

//Predict model with RE, note that area effects are ignored!
predict double xb_re, xb
drop if missing(xb_re)

//Predict ols
gen double xb_ols = `lacons'
foreach x of global themodel{
	replace xb_ols = xb_ols + `x'*``x''
}

//Get poverty rates
forval z=5(5)95{
	gen ols_pov_`z' = normal((`pline_`z'' - xb_ols)/${ols_rmse})
	gen  re_pov_`z' = normal((`pline_`z'' - xb_re)/sqrt(${etavar}+${eps_var}))
	gen direct_pov_`z'  = lny_normal<`pline_`z'' if !missing(lny_normal)
}

keep ols_pov* re_pov* direct_* Whh sim_sample
sp_groupfunction [aw=Whh], mean(ols_pov* re_pov* direct_*) by(sim_sample)

save "$dpath\normal_mex_results.dta", replace

