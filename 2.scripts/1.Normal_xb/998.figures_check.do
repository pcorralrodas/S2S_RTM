set more off
clear all

*===============================================================================
// Hetero sims
*===============================================================================
use "$dpath/results_micomps_het.dta", clear
	egen double true_pov = max(value*(method=="FULL")), by( reference measure sim)
	gen bias = 100*(value - true_pov)
	gen mse  = bias^2
	groupfunction, mean(bias mse) by(method reference measure)
	gen ptile = int(real(subinstr(reference,"povline","",.)))
	
	sort ptile
	
	local measure_type bias mse
	
	foreach type of local measure_type{
		if ("`type'"=="bias") local title Empirical Bias x 100 (pp)
		else local title Empirical MSE x 10,000
	
		twoway (line `type' ptile if measure=="fgt0"  & method=="A la EBP", color(blue) lpattern(-)) ///
		(line `type' ptile if measure=="fgt0"      & method=="A la EBP skew", color(grey)) ///
		(line `type' ptile if measure=="fgt0"      & method=="A la EBP bcox", color(red) lpattern(-.)) ///
		(scatter `type' ptile if measure=="fgt0"      & method=="MI 100", msymbol(Th)  mcolor(blue) msize(medium)) ///
		(scatter `type' ptile if measure=="fgt0"      & method=="MI 100 BS", msymbol(X) mcolor(blue)) ///
		(scatter `type' ptile if measure=="fgt0"      & method=="lasso BIC", msymbol(+) mcolor(blue)) ///
		(scatter `type' ptile if measure=="fgt0"      & method=="Hetregress MLE", msymbol(*) mcolor(red)) ///
		(scatter `type' ptile if measure=="fgt0"      & method=="Het. Mi Reg Het", msymbol(Oh) mcolor(blue)), ///
		legend(label(1 "Fixed B") label(2 "Fixed B, lnskew") ///
		label(3 "Fixed B, bcskew") label(4 "MI 100") label(5 "MI 100 BS") ///
		label(6 "lasso BIC") label(7 "Het. MLE") label(8 "Alpha model") ///
		position(6) cols(4)) ytitle("`title'") xtitle("True poverty rate")
		
		graph export "$figs\method_comp_fgt0_het_`type'.eps", as(eps) name("Graph") replace
	
		
		twoway (line bias ptile if measure=="fgt0"  & method=="lasso BIC", color(blue) lpattern(-)) ///
		(line bias ptile if measure=="fgt0"      & method=="lasso adaptive", color(grey)) ///
		(line bias ptile if measure=="fgt0"      & method=="lasso empirical", color(red) lpattern(-.)) ///
		(scatter bias ptile if measure=="fgt0"      & method=="Het. Mi Reg Het", msymbol(Oh) mcolor(blue)), ///
		legend(label(1 "lasso BIC") label(2 "lasso adaptive") ///
		label(3 "lasso") label(4 "Alpha model") ///
		position(6) cols(3)) ytitle("`title'") xtitle("True poverty rate")
	
		graph export "$figs\lasso_comp_fgt0_het_`type'.eps", as(eps) name("Graph") replace
	
	}
*===============================================================================
// Sigma E sims
*===============================================================================
use "$dpath/sigma_e_results.dta", clear
split variable, parse(_)
gen line = real(variable2) if variable1=="true"
replace line = real(variable3) if variable1=="pred"

groupfunction, mean(value) by(variable1 variable2 line)

egen true_fgt0 = max(value*(variable1=="true")), by(line)

gen bias = 100*(value - true_fgt0)

drop if variable1=="true"

rename line ptile

	twoway (line bias ptile if variable2=="n5", color(blue) lpattern(-)) ///
	(line bias ptile if variable2=="n10", color(grey)) ///
	(line bias ptile if variable2=="n20", color(red) lpattern("...")) ///
	(scatter bias ptile if variable2=="5", msymbol(Th)  mcolor(blue) msize(medium)) ///
	(scatter bias ptile if variable2=="10", msymbol(X) mcolor(blue)) ///
	(scatter bias ptile if variable2=="20", msymbol(+) mcolor(blue)), ///
	legend(label(1 "95% {&sigma}") label(2 "90% {&sigma}") label(3 "80% {&sigma}") ///
	label(4 "105% {&sigma}") label(5 "110% {&sigma}") ///
	label(6 "120% {&sigma}")  ///
	position(6) cols(2)) ytitle("Empirical Bias (pp)") xtitle("True poverty rate")

	graph export "$figs\sigma_change_fgt0.eps", as(eps) name("Graph") replace
*===============================================================================
// Non normal simulations - t distribution 10 df, SD=0.5
*===============================================================================
use "$dpath/results_micomps_t.dta", clear

	egen double true_pov = max(value*(method=="FULL")), by( reference measure sim)
	gen bias = 100*(value - true_pov)
	gen mse  = bias^2
	groupfunction, mean(bias mse) by(method reference measure)
	gen ptile = int(real(subinstr(reference,"povline","",.)))
	
	sort ptile
	
	local measure_type bias mse
	
	foreach type of local measure_type{
		if ("`type'"=="bias") local title Empirical Bias x 100 (pp)
		else local title Empirical MSE x 10,000
	
		twoway (line `type' ptile if measure=="fgt0"  & method=="A la EBP", color(blue) lpattern(-)) ///
		(line `type' ptile if measure=="fgt0"      & method=="A la EBP skew", color(grey)) ///
		(line `type' ptile if measure=="fgt0"      & method=="A la EBP bcox", color(red) lpattern(-.)) ///
		(scatter `type' ptile if measure=="fgt0"      & method=="MI 100", msymbol(Th)  mcolor(blue) msize(medium)) ///
		(scatter `type' ptile if measure=="fgt0"      & method=="MI 100 BS", msymbol(X) mcolor(blue)) ///
		(scatter `type' ptile if measure=="fgt0"      & method=="rforest", msymbol(*) mcolor(red)) ///
		(scatter `type' ptile if measure=="fgt0"      & method=="Het. Mi Reg", msymbol(Dh) mcolor(blue)) ///	
		(scatter `type' ptile if measure=="fgt0"      & method=="lasso BIC", msymbol(+) mcolor(blue)), ///
		legend(label(1 "Fixed B") label(2 "Fixed B, lnskew") ///
		label(3 "Fixed B, bcskew") label(4 "MI 100") label(5 "MI 100 BS") ///
		label(6 "Random Forest") label(7 "OLS BS") label(8 "lasso BIC")  ///
		position(6) cols(3)) ytitle("`title'") xtitle("True poverty rate") xsize(6.5) ysize(5)
		
		graph export "$figs\method_comp_fgt0_rf_t_`type'.eps", as(eps) name("Graph") replace
		
		twoway (line `type' ptile if measure=="fgt0"  & method=="A la EBP", color(blue) lpattern(-)) ///
		(line `type' ptile if measure=="fgt0"      & method=="A la EBP skew", color(grey)) ///
		(line `type' ptile if measure=="fgt0"      & method=="A la EBP bcox", color(red) lpattern(-.)) ///
		(scatter `type' ptile if measure=="fgt0"      & method=="MI 100", msymbol(Th)  mcolor(blue) msize(medium)) ///
		(scatter `type' ptile if measure=="fgt0"      & method=="MI 100 BS", msymbol(X) mcolor(blue)) ///
		(scatter `type' ptile if measure=="fgt0"      & method=="Het. Mi Reg", msymbol(Dh) mcolor(blue)) ///
		(scatter `type' ptile if measure=="fgt0"      & method=="lasso BIC", msymbol(+) mcolor(blue)), ///
		legend(label(1 "Fixed B") label(2 "Fixed B, lnskew") ///
		label(3 "Fixed B, bcskew") label(4 "MI 100") label(5 "MI 100 BS") ///
		label(6 "OLS BS") label(7 "lasso BIC")  ///
		position(6) cols(3)) ytitle("`title'") xtitle("True poverty rate") xsize(6.5) ysize(5)
		
		graph export "$figs\method_comp_fgt0_t_`type'.eps", as(eps) name("Graph") replace
	
		
		twoway (line `type' ptile if measure=="fgt0"  & method=="lasso BIC", color(blue) lpattern(-)) ///
		(line `type' ptile if measure=="fgt0"      & method=="lasso adaptive", color(grey)) ///
		(line `type' ptile if measure=="fgt0"      & method=="lasso empirical", color(red) lpattern(-.)), ///
		legend(label(1 "lasso BIC") label(2 "lasso adaptive") ///
		label(3 "lasso") ///
		position(6) cols(3)) ytitle("`title'") xtitle("True poverty rate")
	
		graph export "$figs\lasso_comp_fgt0_t_`type'.eps", as(eps) name("Graph") replace
	}

*===============================================================================
// Gini
*===============================================================================
use "$dpath\results_reweight_1.dta", clear
	keep if measure=="gini"
	groupfunction, mean(value) by(source method measure variable)
	egen double true_gini = max(value*(source=="Full")), by(measure)

	gen bias = 100*(value - true_gini)
	drop if method=="FULL"|method=="SRS"
	
	replace method = "Unadjusted" if method=="Non adjusted"
	replace method = "Match XB and var[XB]" if method=="Weight 4"
	replace method = "Match XB" if method=="Weight 3"
	replace method = "Match X and var[X]" if method=="Weight 2"
	replace method = "Match X" if method=="Weight 1"
	replace method = "Standardize each X" if method=="Standardize All"
	replace method = "Standardize XB" if method=="Standardize xb"
	
	graph hbar (mean) bias if source=="biased_sample", over(method) ytitle(Bias (Gini points))
	graph export "$figs\weights_std_bb_gini.eps", as(eps) name("Graph") replace
	
	graph hbar (mean) bias if source=="biased_sample_topbottom", over(method) ytitle(Bias (Gini points))
	graph export "$figs\weights_std_tbb_gini.eps", as(eps) name("Graph") replace
	
/*===============================================================================
// Figures for OVB
// 2.ovb_sim_new.do
*===============================================================================
use "$dpath\ovb_results.dta", clear
gen ptile = int(real(subinstr(reference,"povline","",.)))

//Dconflict_Deggs
drop if measure!="fgt0"
replace value = 100*value
qui: reshape wide value, i(ptile) j(variable) string
	rename value* *
	//So first we want to show that the OVB model if applied to the same data
	// will produce an unbiased prediction
	forval bd = 5/15{
		forval ed = 5/15{
			gen diff_true_`bd'_`ed' = Y_B_`bd'_`ed' - Y_B
			lab var diff_true_`bd'_`ed' "Conflict `bd'0%, Eggs `ed'0%"
			
			gen pred_diff_`bd'_`ed' = (y_b_`bd'_`ed' - Y_B)
			lab var pred_diff_`bd'_`ed' "Conflict `bd'0%, Eggs `ed'0%"
			
			gen pred2_diff_`bd'_`ed' = (y_b_`bd'_`ed' - Y_B)^2
			
			gen diff_dir_`bd'_`ed' = (diff_true_`bd'_`ed'>0 & pred_diff_`bd'_`ed'<0) | (diff_true_`bd'_`ed'<0 & pred_diff_`bd'_`ed'>0) 
			
			local suff `bd'_`ed'
			
			qui:twoway (line diff_true_`suff' ptile, color(blue) lpattern(-)) ///
			(scatter pred_diff_`suff' ptile, mcolor(red)), ///
			ytitle(Difference) xtitle("True poverty rate") ///
			legend(label(1 "True change in poverty") label(2 "Predicted change") pos(6) cols(2)) xsize(5) ysize(5)
			
			graph export "$figs\bd`bd'_ed`ed'.eps", as(eps) name("Graph") replace
			graph export "$figs\bd`bd'_ed`ed'.jpg", as(jpg) name("Graph") replace
			
		}
	}
		
*/	
*===============================================================================
// Figures for changing beta and sigma
// 4.Changing_betas_sigmas_mu.do
*===============================================================================
import excel using "$dpath/Changing sigma.xlsx", sheet(changing_beta_sd_mu) first clear
	gen ptile = int(real(subinstr(reference,"povline","",.)))
	gen bias = 100*value - ptile


twoway        (line bias ptile if measure=="fgt0"  & regexm(variable,"b_") & pchange==-1, color(red) lpattern(-)) ///
	          (line bias ptile if measure=="fgt0"  & regexm(variable,"b_") & pchange==1, color(blue) lpattern(-)) ///
	   (scatter bias ptile if measure=="fgt0"      & regexm(variable,"b_") & pchange==-2, msymbol(d)  mcolor(red)) ///
	   (scatter bias ptile if measure=="fgt0"      & regexm(variable,"b_") & pchange==2, msymbol(d)  mcolor(blue)) ///
	   (scatter bias ptile if measure=="fgt0"      & regexm(variable,"b_") & pchange==-3, msymbol(+) mcolor(red)) ///
	   (scatter bias ptile if measure=="fgt0"      & regexm(variable,"b_") & pchange==3, msymbol(+) mcolor(blue)) ///
	   (scatter bias ptile if measure=="fgt0"      & regexm(variable,"b_") & pchange==-4, msymbol(Th) mcolor(red)) ///
	   (scatter bias ptile if measure=="fgt0"      & regexm(variable,"b_") & pchange==4, msymbol(Th) mcolor(blue)), ///
	legend(label(1 "1% increase") label(2 "1% decrease") ///
	label(3 "2% increase") label(4 "2% decrease") ///
	label(5 "3% increase") label(6 "3% decrease") ///
	label(7 "4% increase") label(8 "4% decrease") ///
	position(6) cols(2)) ytitle("Empirical Bias (pp)") xtitle("True poverty rate")
	graph export "$figs\beta_change_fgt0.eps", as(eps) name("Graph") replace
	
twoway        (line bias ptile if measure=="fgt0"  & regexm(variable,"mu_") & pchange==-1, color(red) lpattern(-)) ///
	          (line bias ptile if measure=="fgt0"  & regexm(variable,"mu_") & pchange==1, color(blue) lpattern(-)) ///
	   (scatter bias ptile if measure=="fgt0"      & regexm(variable,"mu_") & pchange==-2, msymbol(d)  mcolor(red)) ///
	   (scatter bias ptile if measure=="fgt0"      & regexm(variable,"mu_") & pchange==2, msymbol(d)  mcolor(blue)) ///
	   (scatter bias ptile if measure=="fgt0"      & regexm(variable,"mu_") & pchange==-3, msymbol(+) mcolor(red)) ///
	   (scatter bias ptile if measure=="fgt0"      & regexm(variable,"mu_") & pchange==3, msymbol(+) mcolor(blue)) ///
	   (scatter bias ptile if measure=="fgt0"      & regexm(variable,"mu_") & pchange==-4, msymbol(Th) mcolor(red)) ///
	   (scatter bias ptile if measure=="fgt0"      & regexm(variable,"mu_") & pchange==4, msymbol(Th) mcolor(blue)), ///
	legend(label(1 "1% increase") label(2 "1% decrease") ///
	label(3 "2% increase") label(4 "2% decrease") ///
	label(5 "3% increase") label(6 "3% decrease") ///
	label(7 "4% increase") label(8 "4% decrease") ///
	position(6) cols(2)) ytitle("Empirical Bias (pp)") xtitle("True poverty rate")
	graph export "$figs\beta_mu_change_fgt0.eps", as(eps) name("Graph") replace
	
twoway        (line bias ptile if measure=="fgt0"  & regexm(variable,"sd_") & pchange==-1, color(red) lpattern(-)) ///
	          (line bias ptile if measure=="fgt0"  & regexm(variable,"sd_") & pchange==1, color(blue) lpattern(-)) ///
	   (scatter bias ptile if measure=="fgt0"      & regexm(variable,"sd_") & pchange==-2, msymbol(d)  mcolor(red)) ///
	   (scatter bias ptile if measure=="fgt0"      & regexm(variable,"sd_") & pchange==2, msymbol(d)  mcolor(blue)) ///
	   (scatter bias ptile if measure=="fgt0"      & regexm(variable,"sd_") & pchange==-3, msymbol(+) mcolor(red)) ///
	   (scatter bias ptile if measure=="fgt0"      & regexm(variable,"sd_") & pchange==3, msymbol(+) mcolor(blue)) ///
	   (scatter bias ptile if measure=="fgt0"      & regexm(variable,"sd_") & pchange==-4, msymbol(Th) mcolor(red)) ///
	   (scatter bias ptile if measure=="fgt0"      & regexm(variable,"sd_") & pchange==4, msymbol(Th) mcolor(blue)), ///
	legend(label(1 "1% increase") label(2 "1% decrease") ///
	label(3 "2% increase") label(4 "2% decrease") ///
	label(5 "3% increase") label(6 "3% decrease") ///
	label(7 "4% increase") label(8 "4% decrease") ///
	position(6) cols(2)) ytitle("Empirical Bias (pp)") xtitle("True poverty rate")
	graph export "$figs\beta_sd_change_fgt0.eps", as(eps) name("Graph") replace
*/
*===============================================================================
// FIgures for changing constants
// 3.Changing constant.do
*===============================================================================
import excel using "$dpath/Changing constant.xlsx", first clear

	gen ptile = int(real(subinstr(reference,"povline","",.)))
	gen bias = 100*value - ptile
	
	keep if ptile
	
	twoway (line bias ptile if measure=="fgt0"  & pchange==-1, color(red) lpattern(-)) ///
	(line bias ptile if measure=="fgt0"  & pchange==1, color(blue) lpattern(-)) ///
	(scatter bias ptile if measure=="fgt0"      & pchange==-2, msymbol(d)  mcolor(red)) ///
	(scatter bias ptile if measure=="fgt0"      & pchange==2, msymbol(d)  mcolor(blue)) ///
	(scatter bias ptile if measure=="fgt0"      & pchange==-3, msymbol(+) mcolor(red)) ///
	(scatter bias ptile if measure=="fgt0"      & pchange==3, msymbol(+) mcolor(blue)) ///
	(scatter bias ptile if measure=="fgt0"      & pchange==-4, msymbol(Th) mcolor(red)) ///
	(scatter bias ptile if measure=="fgt0"      & pchange==4, msymbol(Th) mcolor(blue)), ///
	legend(label(1 "1% increase") label(2 "1% decrease") ///
	label(3 "2% increase") label(4 "2% decrease") ///
	label(5 "3% increase") label(6 "3% decrease") ///
	label(7 "4% increase") label(8 "4% decrease") ///
	position(6) cols(2)) ytitle("Empirical Bias (pp)") xtitle("True poverty rate")
	
	graph export "$figs\constant_change_fgt0.eps", as(eps) name("Graph") replace
	
*===============================================================================
// 2.5 FIgures for Cluster sims 
// 2.run_cluster_sims.do
*==============================================================================

use "$dpath/results_micomps_cluster.dta", clear

	egen double true_pov = max(value*(method=="FULL")), by( reference measure sim)
	gen bias = 100*(value - true_pov)
	gen mse  = bias^2
	groupfunction, mean(bias mse) by(method reference measure)
	gen ptile = int(real(subinstr(reference,"povline","",.)))
	
	sort ptile
	
	local measure_type bias mse
	
	foreach type of local measure_type{
		if ("`type'"=="bias") local title Empirical Bias x 100 (pp)
		else local title Empirical MSE x 10,000
	
		twoway (line `type' ptile if measure=="fgt0"  & method=="A la EBP", color(blue) lpattern(-)) ///
		(scatter `type' ptile if measure=="fgt0"      & method=="MI 20", msymbol(oh) mcolor(blue) msize(small)) ///
		(scatter `type' ptile if measure=="fgt0"      & method=="MI 100", msymbol(d)  mcolor(blue)) ///
		(scatter `type' ptile if measure=="fgt0"      & method=="One-fold", msymbol(Th)  mcolor(blue) msize(medium)) ///
		(scatter `type' ptile if measure=="fgt0"      & method=="Two-fold", msymbol(X) mcolor(blue)), ///
		legend(label(1 "Fixed B") label(2 "MI 20") ///
		label(3 "MI 100") label(4 "One-fold") label(5 "Two-fold") ///
		position(7) cols(6)) ytitle("`title'") xtitle("True poverty rate")
		
		graph export "$figs\mi_ebp_fgt0_cluster_`type'.eps", as(eps) name("Graph") replace
		
		twoway (line `type' ptile if measure=="fgt1"  & method=="A la EBP", color(blue) lpattern(-)) ///
		(scatter `type' ptile if measure=="fgt1"      & method=="MI 20", msymbol(oh) mcolor(blue) msize(small)) ///
		(scatter `type' ptile if measure=="fgt1"      & method=="MI 100", msymbol(d)  mcolor(blue)) ///
		(scatter `type' ptile if measure=="fgt1"      & method=="One-fold", msymbol(Th)  mcolor(blue) msize(medium)) ///
		(scatter `type' ptile if measure=="fgt1"      & method=="Two-fold", msymbol(X) mcolor(blue)), ///
		legend(label(1 "Fixed B") label(2 "MI 20") ///
		label(3 "MI 100") label(4 "One-fold") label(5 "Two-fold") ///
		position(7) cols(6)) ytitle("`title'") xtitle("True poverty gap")
		
		graph export "$figs\mi_ebp_fgt1_cluster_`type'.eps", as(eps) name("Graph") replace
		
	}
	

*===============================================================================
// FIgures for MI comparison to EBP
// 3.check_results_Mi_ebp_comps.do
*==============================================================================

use "$dpath/results_micomps.dta", clear

	egen double true_pov = max(value*(method=="FULL")), by( reference measure sim)
	gen bias = 100*(value - true_pov)
	gen mse  = bias^2
	groupfunction, mean(bias mse) by(method reference measure)
	gen ptile = int(real(subinstr(reference,"povline","",.)))
	
	sort ptile
	
	local measure_type bias mse
	
	foreach type of local measure_type{
		if ("`type'"=="bias") local title Empirical Bias x 100 (pp)
		else local title Empirical MSE x 10,000
	
		twoway (line `type' ptile if measure=="fgt0"  & method=="A la EBP", color(blue) lpattern(-)) ///
		(scatter `type' ptile if measure=="fgt0"      & method=="MI 20", msymbol(oh) mcolor(blue) msize(small)) ///
		(scatter `type' ptile if measure=="fgt0"      & method=="MI 40", msymbol(d)  mcolor(blue)) ///
		(scatter `type' ptile if measure=="fgt0"      & method=="MI 60", msymbol(Th)  mcolor(blue) msize(medium)) ///
		(scatter `type' ptile if measure=="fgt0"      & method=="MI 80", msymbol(X) mcolor(blue)) ///
		(scatter `type' ptile if measure=="fgt0"      & method=="MI 100", msymbol(+) mcolor(blue)), ///
		legend(label(1 "Fixed B") label(2 "MI 20") ///
		label(3 "MI 40") label(4 "MI 60") label(5 "MI 80") ///
		label(6 "MI 100")  ///
		position(7) cols(6)) ytitle("`title'") xtitle("True poverty rate")
		
		graph export "$figs\mi_ebp_fgt0_`type'.eps", as(eps) name("Graph") replace
		
		twoway (line `type' ptile if measure=="fgt1"  & method=="A la EBP", color(blue) lpattern(-)) ///
		(scatter `type' ptile if measure=="fgt1"      & method=="MI 20", msymbol(oh) mcolor(blue) msize(small)) ///
		(scatter `type' ptile if measure=="fgt1"      & method=="MI 40", msymbol(d)  mcolor(blue)) ///
		(scatter `type' ptile if measure=="fgt1"      & method=="MI 60", msymbol(Th)  mcolor(blue) msize(medium)) ///
		(scatter `type' ptile if measure=="fgt1"      & method=="MI 80", msymbol(X) mcolor(blue)) ///
		(scatter `type' ptile if measure=="fgt1"      & method=="MI 100", msymbol(+) mcolor(blue)), ///
		legend(label(1 "Fixed B") label(2 "MI 20") ///
		label(3 "MI 40") label(4 "MI 60") label(5 "MI 80") ///
		label(6 "MI 100")  ///
		position(7) cols(6)) ytitle("`title'") xtitle("True poverty rate")
		
		graph export "$figs\mi_ebp_fgt1_`type'.eps", as(eps) name("Graph") replace
	}

*===============================================================================
// FIgures for reweighting and standarization simulations
// 2.runs_simulations.do
*===============================================================================
use "$dpath\results_reweight_1.dta", clear

	egen double true_pov = max(value*(lower(source)=="full")), by(reference measure sim)
	gen bias = 100*(value - true_pov)
	gen mse  = bias^2
	groupfunction, mean(bias mse) by(source method reference measure)
	gen ptile = int(real(subinstr(reference,"povline","",.)))
	
	sort ptile
	
	local measure_type bias mse
	
	foreach type of local measure_type{
		if ("`type'"=="bias") local title Empirical Bias x 100 (pp)
		else local title Empirical MSE x 10,000	
		
		twoway (line `type' ptile if measure=="fgt0" & source=="biased_sample_topbottom" & method=="Non adjusted", color(blue) lpattern(-)) ///
		(scatter `type' ptile if measure=="fgt0" & source=="biased_sample_topbottom" & method=="Weight 4", msymbol(oh) mcolor(blue) msize(small)) ///
		(scatter `type' ptile if measure=="fgt0" & source=="biased_sample_topbottom" & method=="Weight 3", msymbol(d)  mcolor(blue)) ///
		(scatter `type' ptile if measure=="fgt0" & source=="biased_sample_topbottom" & method=="Weight 2", msymbol(Th)  mcolor(blue) msize(medium)) ///
		(scatter `type' ptile if measure=="fgt0" & source=="biased_sample_topbottom" & method=="Weight 1", msymbol(X) mcolor(blue)) ///
		(line `type' ptile if measure=="fgt0" & source=="biased_sample_topbottom" & method=="Standardize All", lpattern("..-")) ///
		(line `type' ptile if measure=="fgt0" & source=="biased_sample_topbottom" & method=="Standardize xb"), ///
		legend(label(1 "Unadjusted") label(2 "Match XB and var[XB]") ///
		label(3 "Match XB") label(4 "Match X and var[X]") label(5 "Match X") ///
		label(6 "Standardize each X") label(7 "Standardize XB") ///
		position(7) cols(3)) ytitle("`title'") xtitle("True poverty rate")
		
		graph export "$figs\weights_std_tbb_fgt0_`type'.eps", as(eps) name("Graph") replace
		
		twoway (line `type' ptile if measure=="fgt0" & source=="biased_sample" & method=="Non adjusted", color(blue) lpattern(-)) ///
		(scatter `type' ptile if measure=="fgt0" & source=="biased_sample" & method=="Weight 4", msymbol(oh) mcolor(blue) msize(small)) ///
		(scatter `type' ptile if measure=="fgt0" & source=="biased_sample" & method=="Weight 3", msymbol(d)  mcolor(blue)) ///
		(scatter `type' ptile if measure=="fgt0" & source=="biased_sample" & method=="Weight 2", msymbol(Th)  mcolor(blue) msize(medium)) ///
		(scatter `type' ptile if measure=="fgt0" & source=="biased_sample" & method=="Weight 1", msymbol(X) mcolor(blue)) ///
		(line `type' ptile if measure=="fgt0" & source=="biased_sample" & method=="Standardize All", lpattern("..-")) ///
		(line `type' ptile if measure=="fgt0" & source=="biased_sample" & method=="Standardize xb"), ///
		legend(label(1 "Unadjusted") label(2 "Match XB and var[XB]") ///
		label(3 "Match XB") label(4 "Match X and var[X]") label(5 "Match X") ///
		label(6 "Standardize each X") label(7 "Standardize XB") ///
		position(7) cols(3)) ytitle("`title'") xtitle("True poverty rate")
		
		graph export "$figs\weights_std_bb_fgt0_`type'.eps", as(eps) name("Graph") replace
		
		twoway (line `type' ptile if measure=="fgt1" & source=="biased_sample_topbottom" & method=="Non adjusted", color(blue) lpattern(-)) ///
		(scatter `type' ptile if measure=="fgt1" & source=="biased_sample_topbottom" & method=="Weight 4", msymbol(oh) mcolor(blue) msize(small)) ///
		(scatter `type' ptile if measure=="fgt1" & source=="biased_sample_topbottom" & method=="Weight 3", msymbol(d)  mcolor(blue)) ///
		(scatter `type' ptile if measure=="fgt1" & source=="biased_sample_topbottom" & method=="Weight 2", msymbol(Th)  mcolor(blue) msize(medium)) ///
		(scatter `type' ptile if measure=="fgt1" & source=="biased_sample_topbottom" & method=="Weight 1", msymbol(X) mcolor(blue)) ///
		(line `type' ptile if measure=="fgt1" & source=="biased_sample_topbottom" & method=="Standardize All", lpattern("..-")) ///
		(line `type' ptile if measure=="fgt1" & source=="biased_sample_topbottom" & method=="Standardize xb"), ///
		legend(label(1 "Unadjusted") label(2 "Match XB and var[XB]") ///
		label(3 "Match XB") label(4 "Match X and var[X]") label(5 "Match X") ///
		label(6 "Standardize each X") label(7 "Standardize XB") ///
		position(7) cols(3)) ytitle("`title'") xtitle("True poverty rate")
		
		graph export "$figs\weights_std_tbb_fgt1_`type'.eps", as(eps) name("Graph") replace
		
		twoway (line `type' ptile if measure=="fgt1" & source=="biased_sample" & method=="Non adjusted", color(blue) lpattern(-)) ///
		(scatter `type' ptile if measure=="fgt1"     & source=="biased_sample" & method=="Weight 4", msymbol(oh) mcolor(blue) msize(small)) ///
		(scatter `type' ptile if measure=="fgt1"     & source=="biased_sample" & method=="Weight 3", msymbol(d)  mcolor(blue)) ///
		(scatter `type' ptile if measure=="fgt1"     & source=="biased_sample" & method=="Weight 2", msymbol(Th)  mcolor(blue) msize(medium)) ///
		(scatter `type' ptile if measure=="fgt1"     & source=="biased_sample" & method=="Weight 1", msymbol(X) mcolor(blue)) ///
		(line `type' ptile if measure=="fgt1"        & source=="biased_sample" & method=="Standardize All", lpattern("..-")) ///
		(line `type' ptile if measure=="fgt1"        & source=="biased_sample" & method=="Standardize xb"), ///
		legend(label(1 "Unadjusted") label(2 "Match XB and var[XB]") ///
		label(3 "Match XB") label(4 "Match X and var[X]") label(5 "Match X") ///
		label(6 "Standardize each X") label(7 "Standardize XB") ///
		position(7) cols(3)) ytitle("`title'") xtitle("True poverty rate")
		
		graph export "$figs\weights_std_bb_fgt1_`type'.eps", as(eps) name("Graph") replace
	}
