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
use "$mex\my_samples_pps_psu@.dta" if sim_sample==`sample_num', clear

merge 1:1 hhid using "$dpath\mex_census.dta"
	drop if _m!=3
	drop _m
	
gen popw = hhsize*Whh
	
*=======================================================================
//Normal errors
************************************************************************
reg lny_normal $themodel [aw=Whh], r
global ols_rmse = e(rmse)

foreach x of global themodel{
	local `x' = _b[`x']
}
	local lacons = _b[_cons]
	
preserve	
	predict laxb, xb
	gen lny_normal_imp =rnormal(laxb, $ols_rmse)
	
	cap gen popw = hhsize*Whh
	
	//Produce figure
	foreach x in lny_normal laxb lny_normal_imp{
		pctile pt_`x' = `x' [aw=popw], nq(100) 
	}
	
	gen ptile = _n if pt_lny_normal!=.

	twoway (line pt_lny_normal ptile, lcolor(black) ) ///
	(line pt_laxb ptile, lcolor(blue) lpattern(-.-)) ///
	(scatter pt_lny_normal_imp ptile, mcolor(red) msymbol(Oh)), ///
	legend(label(1 "True values") label(2 "XB values") label(3 "XB+e values")) ytitle("Welfare in nat. log") xtitle("Cumulative percent of population") legend(cols(3)) legend(position(6)) xsize(5) ysize(5)
	
	graph export "$figs\why_errors.eps", as(eps) name("Graph") replace


restore
	
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

gen popw = Whh*hhsize

keep ols_pov* re_pov* direct_* Whh sim_sample popw
sp_groupfunction [aw=popw], mean(ols_pov* re_pov* direct_*) by(sim_sample)

save "$dpath\normal_mex_results.dta", replace

