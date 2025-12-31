set more off
clear all

set seed 3739

*========================================================================
// Mata function for empirical distribution sampling of errors
*========================================================================
clear mata
mata
	function _f_sampleepsi(real scalar n, real scalar dim, real matrix eps){				  
		sige2 = J(dim,n,0)
		N = rows(eps)
		if (cols(eps)==1) for(i=1; i<=n; i++) sige2[.,i]=eps[ceil(N*runiform(dim,1)),1]
		else              for(i=1; i<=n; i++) sige2[.,i]=eps[ceil(N*runiform(dim,1)),i]
		return(sige2)	
	}
end

*========================================================================
//Bring in the full data and get plines
*========================================================================
local depvar $ladep
	
	foreach x in `depvar'{
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
di "Sample: `sample_num'"
use "$mex\my_samples_pps_psu@.dta" if sim_sample==`sample_num', clear

merge 1:1 hhid using "$dpath\mex_census.dta"
	drop if _m!=3
	drop _m
	
*=======================================================================
//Models
************************************************************************
//Normal
reg `depvar' $themodel [aw=Whh], r
global ols_rmse = e(rmse)


//Now, predict
use "$mex\my_samples_pps_psu@.dta" if inrange(sim_sample,501,1000), clear

merge m:1 hhid using "$dpath\mex_census.dta"
	drop if _m!=3
	drop _m

//Predict model with RE, note that area effects are ignored!
predict double xb_ols, xb
drop if missing(xb)

//Get poverty rates
forval z=5(5)95{
	gen ols_pov_`z' = normal((`pline_`z'' - xb_ols)/${ols_rmse})
	gen direct_pov_`z'  = `depvar'<`pline_`z'' if !missing(`depvar')
}

gen popw = hhsize*Whh

keep ols_pov* direct_* Whh sim_sample popw
sp_groupfunction [aw=popw], mean(ols_pov* direct_*) by(sim_sample)

if (regexm("`depvar'","8")) save "$dpath\nonnormal8_mex_results.dta", replace
else if (regexm("`depvar'","8")) save "$dpath\nonnormal_mex_results.dta", replace

