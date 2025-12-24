set more off 
clear all

set seed 31282
set maxvar 20000	
use "$dpath/data_ovb.dta", clear
	//Pull original parameters
	local b_eggs         : char _dta[b_eggs]
	local b_conflict     : char _dta[b_conflict]
	local p_egg_conflict : char _dta[p_egg_conflict]
	local egg_increase   : char _dta[egg_increase]
	//Model parameters
	foreach x in x1 x2 x3 x4 x5 thecons eggs RMSE{
		local `x' : char _dta[`x']
	}	
	
*===============================================================================
//Predict new welfare using nex X, but Betas and RMSE from original model
//with OVB
*===============================================================================
gen double yb_1_pred = `thecons'
forval z = 1/5{
	replace yb_1_pred = yb_1_pred + `x`z''*x`z'
}
	

forval bd = 5/15{
	forval ed = 5/15{
		
		//conflict dropped by 50% - only change in the model!
		gen conflict_1 = runiform()<0.4*`=`bd'/10'
		//Eggs changes due to conflict change
		gen     eggs_1 = runiform()<=(.5*`=`ed'/10' + `p_egg_conflict'*conflict_1) 		
		//generate new errors following assumed DGP
		gen e_1 = rnormal(0,0.5)
		//generate new welfare
		gen linear_fit_1 = 3 + 0.1* x1 + 0.5* x2 - 0.25*x3 - 0.2*x4 - 0.15*x5 + `b_eggs'*eggs_1 + `b_conflict'*conflict_1
		gen Y_B_`bd'_`ed' = linear_fit_1 + e_1
		
		//Now produce the predicted
		gen y_b_`bd'_`ed' = yb_1_pred + `eggs'*eggs_1 + rnormal(0,`RMSE')
		
		drop conflict_1
		drop eggs_1
		drop e_1
		drop linear_fit_1
	}
}

keep y_b_* Y_B_* Y_B povline* yb_pred
cap gen all = 1
sp_groupfunction, poverty(y_b_* Y_B_* Y_B yb_pred) povertyline(povline*) by(all)

save "$dpath\ovb_results.dta", replace
