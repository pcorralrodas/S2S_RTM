set more off
clear all

set seed 3739

*========================================================================
//Bring in the full data and get plines
*========================================================================
	
	foreach x in lny_normal{
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

qui{

forval z=501/1000{
	use "$mex\my_samples_pps_psu@.dta" if inlist(sim_sample,`sample_num',`z'), clear

	merge m:1 hhid using "$dpath\mex_census.dta"
		drop if _m!=3
		drop _m
	
	replace lny_normal = . if sim_sample==`z'
	
	mi set mlong
	mi register imputed lny_normal
	mi impute reg lny_normal $themodel [aw=Whh], add(100)
	
	keep if _mi_m>0
	//Get poverty rates
	forval i=5(5)95{
		gen mi_pov_`i'  = lny_normal<`pline_`i'' if !missing(lny_normal)
	}
	
	gen popw = Whh*hhsize
	groupfunction [aw=popw], mean(mi_pov*) 
	gen sim_sample = `z'
	cap: append using `allsim'
	if _rc{
		tempfile allsim
	}
	save `allsim', replace
	dis as error "Sim num: `z'"
}
}

save "$dpath\normal_mex_results_mi100.dta", replace
