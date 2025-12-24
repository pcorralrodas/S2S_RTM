set more off
clear all

set seed 3739

*===============================================================================
// Get original poverty rates for Mexico
*===============================================================================	
	
	foreach x in lny_nonnormal lny_normal lny_het lny{
		use `x' hhsize using "$dpath\mex_census.dta", clear
		di as error "`x'"
		global themodel : char _dta[model]
		pctile pct_`x' = `x' [aw=hhsize], nq(100)
		forval z=5(5)95{
			local `x'_p`z' = pct_`x'[`z']
			gen ptile_`z'  = pct_`x'[`z']
		}
		
		gen all=1
		
		sp_groupfunction [aw=hhsize], poverty(`x') povertyline(ptile_*) by(all)
		cap: append using `fgts'
		if _rc{
			tempfile fgts
		}
		save `fgts', replace
	}
	
save "$dpath\mex_pov_nums.dta", replace