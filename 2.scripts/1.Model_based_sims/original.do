//Purpose of do file is to create a Y vector that is aligned to the model in the census
// @1 version adds suggestion from David Newhouse to keep the vectors the same

clear 
*===============================================================================
// Simulation pre-amble -->
*===============================================================================
//remove non sig vars after vif


local iter     		= $zed
local simnum        = $sim
local sample        = $sample
if ($bcox==1){
	local transform bcox
	local transformell eta(nonnormal) epsilon(nonnormal)
}
else if ($bcox==2){
	local transform lnskew
	local transformell eta(nonnormal) epsilon(nonnormal)
}
else{
	local transform
	local transformell eta(normal) epsilon(normal)
}

local simhere direct h3eb h3area

*===============================================================================
//Select variables
*===============================================================================
if (`iter'==1){	
	local misvar rural  hhsize age_hh male_hh  piped_water no_piped_water ///
	no_sewage sewage_pub sewage_priv electricity telephone cellphone internet ///
	computer washmachine fridge television share_under15 share_elderly share_adult ///
	max_secondary
	
	
	use "$dpath/census_trim.dta", clear
	
	groupfunction, mean(`misvar') by(HID_mun state)
	
	tempfile cen
	save `cen'
	
	use "$thesamples" if sim_sample==1, clear
	merge 1:1 hhid using "$dpath/census_trim.dta"
		keep if _m==3
		drop _m
	
	groupfunction [aw=Whh], mean(`misvar') by(HID_mun state)
	
	
	ren * svy_*
	ren (svy_HID_mun svy_state) (HID_mun state)
	
	merge 1:1 HID_mun using `cen'
		drop if _m==2
		drop _m
		
	foreach x of local misvar{
		gen mse_`x' = ((`x' - svy_`x')/`x')^2
	}
	gen all=1
	sp_groupfunction, mean(mse_*) by(all)
	replace variable = subinstr(variable, "mse_", "",.)
	levelsof variable if value<=0.1, local(chosen) clean
	global eli `chosen'

*===============================================================================
//Use Census to create baseline values
*===============================================================================

	
		use "$dpath/census_trim.dta", clear
		
		sum e_y [aw=hhsize],d
		global pline = r(p25)		
		
		sample 5, by(HID)
		gen Whh = 1
		
		cap drop *automobile*
				
		if ($bcox==1) bcskew0 bcy = lny
		else if ($bcox==2){
			lnskew0 bcy = exp(lny)
			local   gma = r(gamma) 
		}
		else clonevar bcy = lny
		
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
		outreg2 using "$main/4.models/h3_lnskew_hh_simfake@1.xls", adds(Adj. R2, e(r2a_beta), N, e(N_beta), Eta ratio, e(eta_ratio), Eta square, e(eta_var)) sideway replace

		global hhCmodel `hhvars'			
		
		local unico $hhCmodel hhsize	
		local unico: list uniq unico
		global toimport `unico'
		
		noi:xtmixed bcy $hhCmodel  || HID_mun: || HID:, reml
		outreg2 using "$main/4.models/twofold_lnskew_hh_simfake@1.xls", adds(N, e(N), Sigma Mun, exp([lns1_1_1]_cons), Sigma PSU, exp([lns2_1_1]_cons)) sideway replace

		local sig1_2 =  (exp([lns1_1_1]_cons))^2
		local sig2_2 =   exp([lns2_1_1]_cons)^2
		local evar   =  (exp([lnsig_e]_cons))^2
		
		preserve
			sae data import, datain("$dpath/census_trim.dta") varlist($toimport) ///
			area(HID) uniqid(hhid) dataout("$dpath\micenso")	
			
		restore
			
			sae_ebp_two bcy $hhCmodel, area(3) subarea(HID) mcrep(1) bsrep(0) matin("$dpath\micenso") ind(FGT0) ///
			aggids(0) pwcensus(hhsize) uniqid(hhid) pline(12)
		
		
		
		erase "$dpath\micenso"
		
		preserve
			rename Unit HID
			keep HID
			duplicates drop HID, force
			sort HID
			
			getmata (_Eta _sigma obs1 obs2) = eb_eta //This ETA vector comes directly from the two fold nested error model
			drop obs1 obs2
			
			tempfile HID_E
			save `HID_E'
		restore
		
		
		use "$dpath/census_trim.dta", clear
		keep hhid HID_mun HID hhsize $toimport 
		local pline = $pline
		
			predict double e_y, xb
			merge m:1 HID using `HID_E'
			drop if _m==2
			drop _m
						
			sort hhid
			
			replace e_y = rnormal((e_y + _Eta), _sigma)
			
			replace e_y = exp(e_y) + `gma'
			
			gen double lny = ln(e_y)
			
			//note that e_y is converted!
			
		
			gen poor = e_y<`pline' if !missing(e_y)
			gen gap  = (e_y<`pline')*(1-e_y/`pline')^1
			gen gap2 = (e_y<`pline')*(1-e_y/`pline')^2
			
		keep hhid e_y lny poor gap gap2	
		save "$dpath/yvectors.dta", replace
		
	}


if (`iter'==1){	

	global truemodel $hhCmodel
	local areamodel
	foreach x of global truemodel{
		local areamodel `areamodel' HID_`x'
	}
	global truearea `areamodel'

*===============================================================================
//Use Census to create baseline values
*===============================================================================

			
		
		local unico $hhCmodel $amodel hhsize	
		local unico: list uniq unico
		global toimport `unico'
		
		
		
		use "$dpath/census_trim.dta", clear
		egen HID_rural = mean(rural), by(HID)
		keep hhid HID_mun HID hhsize $toimport 

				
		
		//Add new y vectors generated above
		merge 1:1 hhid using "$dpath/yvectors.dta"
			drop if _m==2
			drop _m
		save "$dpath/census_`simnum'.dta", replace
		
	}
	
	
	local pline = $pline
	cap drop touse
	

*===============================================================================
// CREATE THE SURVEY!
*===============================================================================
	
use "$thesamples" if sim_sample==`sample', clear
	merge 1:1 hhid using "$dpath/census_`simnum'.dta"
		keep if _m==3
		drop _m
gen popw = Whh*hhsize

save "$simdata\svy`simnum'.dta", replace

	//Get models!
	if `iter'==1{
		lnskew0 bcy = exp(lny)
		sae model h3 bcy $amodel [aw=Whh], area(HID_mun)
		outreg2 using "$main/4.models/h3_lnskew_A_fakecensus@1.xls", adds(Adj. R2, e(r2a_beta), N, e(N_beta), Eta ratio, e(eta_ratio), Eta square, e(eta_var)) sideway replace
		
		sae model h3 bcy $hhCmodel [aw=Whh], area(HID_mun)
		outreg2 using "$main/4.models/h3_lnskew_hh_fakecensus@1.xls", adds(Adj. R2, e(r2a_beta), N, e(N_beta), Eta ratio, e(eta_ratio), Eta square, e(eta_var)) sideway replace

	
	}

*===============================================================================
// Direct estimates
*===============================================================================
	gen observations=1
	groupfunction [aw=popw],mean(poor gap gap2 e_y) rawsum(observations) by(HID_mun)
	gen nsim = `iter'
	gen nsample = `sample'
	
	if (`iter'==1) save "$simdata\direct`simnum'.dta", replace
	else{
		append using "$simdata\direct`simnum'.dta"
		save "$simdata\direct`simnum'.dta", replace
	}
		
	//Import Census to stata
	if (`iter'==1){
		
			sae data import, datain("$dpath/census_`simnum'.dta") varlist($toimport) ///
			area(HID_mun) uniqid(hhid) dataout("$dpath\censo_`simnum'")

			sae data import, datain("$dpath/census_`simnum'.dta") varlist($toimport) ///
			area(HID) uniqid(hhid) dataout("$dpath\censo_t_`simnum'")

	}


	//Seed stage for simulations, changes after every iteration!
	local seedstage `c(rngstate)'
	
*===============================================================================
//H3 Area
*===============================================================================
	//We only use the vectors that have area correlations
	use "$simdata\svy`simnum'.dta", clear
	capture noisily sae sim h3 lny $amodel [aw=Whh],  area(HID_mun)  ///
	mcrep(50) bsrep(0) matin("$dpath\censo_`simnum'") lny `transform' seed(`seedstage') ///
	pwcensus(hhsize) indicators(FGT0 FGT1 FGT2) aggids(0) uniq(hhid) plines(`pline')
	if _rc==0{
		gen nsim = `iter'
		gen nsample = `sample'
	
		if (`iter'==1) save "$simdata\h3area`simnum'.dta", replace
		else{
			append using "$simdata\h3area`simnum'.dta"
			save "$simdata\h3area`simnum'.dta", replace
		}
		global redo = 0
	}
	else{
		global redo = 1
		dis as error "Area failed"
		foreach x of local simhere{
			cap use "$simdata\\`x'`simnum'.dta", clear
			if _rc==0{
				drop if nsim==`iter'
				save "$simdata\\`x'`simnum'.dta", replace
			}		
		}
	}
	
*===============================================================================
// H3-EB
*===============================================================================

	//H3-EB	
	if ($redo==0){
		use "$simdata\svy`simnum'.dta", clear
		cap sae sim h3 lny $hhCmodel [aw=Whh],  area(HID_mun)  ///
		mcrep(50) bsrep(0) matin("$dpath\censo_`simnum'") lny `transform' seed(`seedstage') ///
		pwcensus(hhsize) indicators(FGT0 FGT1 FGT2) aggids(0) uniq(hhid) plines(`pline')
		if _rc==0{
			gen nsim = `iter'
			gen nsample = `sample'
			
			if (`iter'==1) save "$simdata\h3eb`simnum'.dta", replace
			else{
				append using "$simdata\h3eb`simnum'.dta"
				save "$simdata\h3eb`simnum'.dta", replace
			}
			global redo = 0
		}
		else{
			global redo = 1
			dis as error "H3-EB failed"
			foreach x of local simhere{
				cap use "$simdata\\`x'`simnum'.dta", clear
				if _rc==0{
					drop if nsim==`iter'
					save "$simdata\\`x'`simnum'.dta", replace
				}				
			}
		}
	}

