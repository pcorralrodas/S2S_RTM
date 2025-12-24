set more off
clear all

set seed 3739

*========================================================================
//Bring in the full data and get plines
*========================================================================
	
	foreach x in lny_nonnormal{
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

di "Sample: `sample_num'"

qui{

forval z=501/1000{
	use "$mex\my_samples_pps_psu@.dta" if inlist(sim_sample,`sample_num',`z'), clear

	merge m:1 hhid using "$dpath\mex_census.dta"
		drop if _m!=3
		drop _m
	
	replace lny_nonnormal = . if sim_sample==`z'
	
	mi set mlong
	mi register imputed lny_nonnormal
	hetmireg lny_nonnormal $themodel [aw=Whh], sims(20) uniqid(hhid) errdraw(empirical) mlong by(_mi_miss)	
	keep if _mi_m>0
	//Get poverty rates
	forval i=5(5)95{
		gen mi_pov_`i'  = lny_nonnormal<`pline_`i'' if !missing(lny_nonnormal)
	}
	
	groupfunction [aw=Whh], mean(mi_pov*) 
	gen sim_sample = `z'
	cap: append using `allsim'
	if _rc{
		tempfile allsim
	}
	save `allsim', replace
	dis as error "Sim num: `z'"
}
}

save "$dpath\nonnormal_mex_results_hetmi20.dta", replace
