/*===============================================================================
// Let's take the Mexican intercensus to create the simulations
// This do file, will create the model, and then create the following errors:
1) Normal errors
2) Non-normal errors
3) heteroskedastic errors
*=============================================================================*/
set more off
clear all

global mex "C:\Users\WB378870\GitHub\Poverty-Mapping\Data"

local misvar rural  hhsize age_hh male_hh  piped_water no_piped_water ///
	no_sewage sewage_pub sewage_priv electricity telephone cellphone internet ///
	computer washmachine fridge television share_under15 share_elderly share_adult ///
	max_secondary
	
use "$mex/census_trim.dta", clear
		
	sum e_y [aw=hhsize],d
	global pline = r(p25)		
	
	sample 10, by(HID)
	gen Whh = 1
	
	cap drop *automobile*

	clonevar bcy = lny
	
	rename HID_mun theMUN
	
	lassoregress bcy  `chosen'  [aw=Whh], lambda1se epsilon(1e-10) numfolds(20)
	local hhvars0p = e(varlist_nonzero)
	local hhvars `hhvars0p'
	//sae model h3 bcy `hhvars0p', area(HID_mun)
	
	rename theMUN HID_mun
	
	forval z= 0.5(-0.05)0.05{
		qui:sae model h3 bcy `hhvars' [aw=Whh], area(HID_mun) 
		mata: bb=st_matrix("e(b_gls)")
		mata: se=sqrt(diagonal(st_matrix("e(V_gls)")))
		mata: zvals = bb':/se
		mata: st_matrix("min",min(abs(zvals)))
		local zv = (-min[1,1])
		if (2*normal(`zv')<`z') exit
	
		foreach x of varlist `hhvars'{
			local hhvars1
			qui: sae model h3 bcy `hhvars' [aw=Whh], area(HID_mun)
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
	
	forval z= 0.05(-0.0005)0.0005{
		qui:sae model h3 bcy `hhvars' [aw=Whh], area(HID_mun) 
		mata: bb=st_matrix("e(b_gls)")
		mata: se=sqrt(diagonal(st_matrix("e(V_gls)")))
		mata: zvals = bb':/se
		mata: st_matrix("min",min(abs(zvals)))
		local zv = (-min[1,1])
		if (2*normal(`zv')<`z') exit
	
		foreach x of varlist `hhvars'{
			local hhvars1
			qui: sae model h3 bcy `hhvars' [aw=Whh], area(HID_mun)
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
		
	sae model h3 bcy `hhvars' [aw=Whh], area(HID_mun)
	outreg2 using "$figs/h3_lnskew_hh_simfake@1.xls", adds(Adj. R2, e(r2a_beta), N, e(N_beta), Eta ratio, e(eta_ratio), Eta square, e(eta_var)) sideway replace
	
	global hhCmodel `hhvars'			
	
	local unico $hhCmodel hhsize	
	local unico: list uniq unico
	global toimport `unico'
	
	noi:xtmixed bcy $hhCmodel  || HID_mun: || HID:, reml
	outreg2 using "$figs/twofold_lnskew_hh_simfake@1.xls", adds(N, e(N), Sigma Mun, exp([lns1_1_1]_cons), Sigma PSU, exp([lns2_1_1]_cons)) sideway replace

	local sig1_2 =  (exp([lns1_1_1]_cons))^2
	local sig2_2 =   exp([lns2_1_1]_cons)^2
	local evar   =  (exp([lnsig_e]_cons))^2

