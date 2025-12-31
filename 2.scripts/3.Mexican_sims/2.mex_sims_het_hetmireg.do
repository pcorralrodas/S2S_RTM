set more off
clear all

set seed 3739

*========================================================================
//Bring in the full data and get plines
*========================================================================
local depvar lny_het
	
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

qui{

forval z=501/1000{
	use "$mex\my_samples_pps_psu@.dta" if inlist(sim_sample,`sample_num',`z'), clear

	merge m:1 hhid using "$dpath\mex_census.dta"
		drop if _m!=3
		drop _m
	
	replace `depvar' = . if sim_sample==`z'
	
	mi set mlong
	mi register imputed `depvar'
	hetmireg `depvar' $themodel [aw=Whh], sims(100) uniqid(hhid)  errdraw(normal) mlong by(_mi_miss)	het(xhet)
	keep if _mi_m>0
	//Get poverty rates
	forval i=5(5)95{
		gen mi_pov_`i'  = `depvar'<`pline_`i'' if !missing(`depvar')
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

save "$dpath\het_mex_results_hetmireg.dta", replace
