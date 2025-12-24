/*===============================================================================
// Let's take the Mexican intercensus to create the simulations
// This do file, will create the model, and then create the following errors:
1) Normal errors
2) Non-normal errors
3) heteroskedastic errors
*=============================================================================*/
set more off
clear all

set seed 26439
local doall = 1


local misvar rural  hhsize age_hh male_hh  piped_water no_piped_water ///
	no_sewage sewage_pub sewage_priv electricity telephone cellphone internet ///
	computer washmachine fridge television share_under15 share_elderly share_adult ///
	max_secondary
	
use "$mex/census_trim.dta", clear
	sort hhid
	sum e_y [aw=hhsize],d
	global pline = r(p25)		
	
	sample 10, by(HID)
	gen Whh = 1
	
	cap drop *automobile*

	clonevar bcy = lny
	
	rename HID_mun theMUN
	
if (`doall'==1){
	
	lassoregress bcy  `misvar' mun_* state_* [aw=Whh], lambda1se epsilon(1e-10) numfolds(20)
	local hhvars0p = e(varlist_nonzero)
	local hhvars `hhvars0p'
	//sae model h3 bcy `hhvars0p', area(HID_mun)
}	
	rename theMUN HID_mun
if (`doall'==1){
	
	forval z= 0.5(-0.05)0.05{
		qui:sae model h3 bcy `hhvars' [aw=Whh], area(HID_mun) method(luinv_la)
		mata: bb=st_matrix("e(b_gls)")
		mata: se=sqrt(diagonal(st_matrix("e(V_gls)")))
		mata: zvals = bb':/se
		mata: st_matrix("min",min(abs(zvals)))
		local zv = (-min[1,1])
		if (2*normal(`zv')<`z') exit
	
		foreach x of varlist `hhvars'{
			local hhvars1
			qui: sae model h3 bcy `hhvars' [aw=Whh], area(HID_mun) method(luinv_la)
			qui: test `x' 
			if (r(p)>`z'){
				local hhvars1
				foreach yy of local hhvars{
					if ("`yy'"=="`x'") dis ""
					else local hhvars1 `hhvars1' `yy'
				}
			}
			else local hhvars1 `hhvars'
			local hhvars `hhvars1'
		
		}
	}	


	
	reg bcy `hhvars' [aw=Whh]
	gen touse = e(sample)
	
	
	mata: ds = _f_stepvif("`hhvars'","Whh",3,"touse")

	local hhvars `vifvar'
	
	forval z= 0.05(-0.01)0.01{
		qui:sae model h3 bcy `hhvars' [aw=Whh], area(HID_mun) method(luinv_la)
		mata: bb=st_matrix("e(b_gls)")
		mata: se=sqrt(diagonal(st_matrix("e(V_gls)")))
		mata: zvals = bb':/se
		mata: st_matrix("min",min(abs(zvals)))
		local zv = (-min[1,1])
		if (2*normal(`zv')<`z') exit
	
		foreach x of varlist `hhvars'{
			local hhvars1
			qui: sae model h3 bcy `hhvars' [aw=Whh], area(HID_mun) method(luinv_la)
			qui: test `x' 
			if (r(p)>`z'){
				local hhvars1
				foreach yy of local hhvars{
					if ("`yy'"=="`x'") dis ""
					else local hhvars1 `hhvars1' `yy'
				}
			}
			else local hhvars1 `hhvars'
			local hhvars `hhvars1'
		
		}
	}
		
	global modvar `hhvars'
}	

	mixed lny $modvar || HID_mun:||HID:, reml difficult
	local sig1_2 =  0.75*(exp([lns1_1_1]_cons))^2
	local sig2_2 =  0.75*(exp([lns2_1_1]_cons))^2
	local evar   =  0.75*(exp([lnsig_e]_cons))^2
	
	keep HID HID_mun
	duplicates drop HID, force
	gen eta_HID = rnormal(0,sqrt(`sig2_2'))
	
	preserve
		keep HID eta_HID
		tempfile HID
		save `HID'
	restore
	
	duplicates drop HID_mun, force
	gen eta_HID_mun = rnormal(0,sqrt(`sig1_2'))
	preserve
		keep HID_mun eta_HID_mun
		tempfile HID_mun
		save `HID_mun'
	restore
	

	
*===============================================================================
//Now produce vectors with different type of errors
*===============================================================================
use "$mex/census_trim.dta", clear
	predict double linear_fit, xb 
	drop if missing(linear_fit)
	
	merge m:1 HID using `HID'
		drop if _m==2
		drop _m
		
	merge m:1 HID_mun using `HID_mun'
		drop if _m==2
		drop _m
	
	sort hhid
		
	//Normal errors
	egen double lny_normal = rsum(linear_fit eta_HID eta_HID_mun)
	replace lny_normal     = lny_normal + rnormal(0,sqrt(`evar'))
	
	//Non-normal errors
	gen double lny_nonnormal = linear_fit + rt(10)/2.25
	
	//Heteroskedastic errors
		// Generate independent variable x
		generate xhet = rnormal(0.5, 0.5)

		// Generate error term with multiplicative heteroskedasticity
		// where variance increases with x
		generate ehet = rnormal(0, exp((1/6)*xhet)/2)
		
	gen lny_het = linear_fit + ehet
	
keep hhid lny_nonnormal lny_normal lny_het lny $modvar HID_mun xhet
char _dta[model] $modvar

save "$dpath\mex_census.dta", replace