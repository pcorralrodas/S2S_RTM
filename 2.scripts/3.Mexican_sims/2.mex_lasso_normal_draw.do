set more off
clear all

set seed 3739

*========================================================================
//Bring in the full data and get plines
*========================================================================
	
	foreach x in nonnormal_8{
		use lny_`x' hhsize using "$dpath\mex_census.dta", clear
		global themodel : char _dta[model]
		pctile pct_`x' = lny_`x' [aw=hhsize], nq(100)
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

tempfile modeldta
save `modeldta'
*=======================================================================
//Models
************************************************************************

local etype nonnormal_8
	use `modeldta', clear
	
	lasso linear lny_`etype' $themodel [iw=Whh], selection(cv)
		
	predict xb, xb
	gen double res = lny_`etype' - xb
	gen touse = !missing(res)
	putmata e      = res if touse==1
	sum res if touse==1 [aw=Whh] 
	local rmse = r(sd)
	global ols_rmse = `rmse'
	
//Now, predict
use "$mex\my_samples_pps_psu@.dta" if inrange(sim_sample,501,1000), clear

merge m:1 hhid using "$dpath\mex_census.dta"
	drop if _m!=3
	drop _m

//Predict model with RE, note that area effects are ignored!
predict double xb, xb
drop if missing(xb)


//Get poverty rates
forval z=5(5)95{
	gen lasso_pov_`z' = normal((`pline_`z'' - xb)/${ols_rmse})
}

gen popw = Whh*hhsize
keep lasso_pov* Whh sim_sample popw
sp_groupfunction [aw=popw], mean(lasso_pov*) by(sim_sample)
	
save "$dpath\mex_results_lasso_nn8_normal_draw.dta", replace