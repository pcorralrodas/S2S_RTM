set more off
clear all

*===============================================================================
//Under heteroskedastic normal errors
*===============================================================================
use "$dpath\het_mex_results_hetmireg.dta", clear
	reshape long mi_pov_, i(sim_sample) j(ptile)
	rename mi_pov_ imputed
	gen variable = "alpha"
	
	keep ptile imputed variable
tempfile alfa
save `alfa'

use "$dpath\mex_results_lasso.dta", clear
	keep if etype=="het"
	reshape long lasso_pov_, i(sim_sample) j(ptile)
	rename lasso_pov_ imputed
	gen variable = "Lasso empirical"
	
	keep ptile imputed variable
tempfile lasso_emp
save `lasso_emp'

use "$dpath\mex_results_ols_e.dta", clear
	keep if etype=="het"
	reshape long ols_e_pov_, i(sim_sample) j(ptile)
	rename ols_e_pov_ imputed
	gen variable = "OLS empirical"
	
	keep ptile imputed variable
tempfile ols_emp
save `ols_emp'

use  "$dpath\het_mex_results.dta", clear
split variable, parse(_)
	gen double ptile = real(variable3)	
	rename value imputed
	keep ptile imputed variable
	
	append using `lasso_emp'
	append using `ols_emp'
	append using `alfa'
tempfile imps
save `imps'

use  "$dpath\mex_pov_nums.dta", clear
	keep if variable=="lny_het" 
	keep if measure=="fgt0"
	drop variable
	gen double ptile = real(subinstr(reference,"ptile_","",.))
	
	merge 1:m ptile using `imps'
		drop if _m==2
		drop _m
		
	gen bias = (imputed - value)*100
	gen mse  = (bias)^2
	
	groupfunction, mean(bias mse) by(ptile variable)
	
twoway (scatter bias ptile if regexm(variable,"ols")) ///
(scatter bias ptile if regexm(variable,"het"), msymbol(X)) ///
(scatter bias ptile if regexm(variable,"OLS emp"), msymbol(Th)) ///
(scatter bias ptile if regexm(variable,"alpha"), msymbol(Oh) mcolor(black)) ///
(line bias ptile if regexm(variable,"Lasso"), lpattern(-.-)), ///
legend(label(1 "OLS ignoring het.") label(2 "MLE with het.")  ///
label(3 "OLS Empirical") label(4 "Alpha model") label(5 "Lasso Empirical") ///
pos(6) cols(2)) xtitle(Poverty rate) ytitle("Bias x 100") xsize(5) ysize(5)


graph export "$figs\bias_het_mex.eps", as(eps) name("Graph") replace

twoway (scatter mse ptile if regexm(variable,"ols")) ///
(scatter mse ptile if regexm(variable,"het"), msymbol(X)) ///
(scatter mse ptile if regexm(variable,"OLS emp"), msymbol(Th)) ///
(scatter mse ptile if regexm(variable,"alpha"), msymbol(Oh) mcolor(black)) ///
(line mse ptile if regexm(variable,"Lasso"), lpattern(-.-)), ///
legend(label(1 "OLS ignoring het.") label(2 "MLE with het.")  ///
label(3 "OLS Empirical") label(4 "Alpha model") label(5 "Lasso Empirical") ///
pos(6) cols(2)) xtitle(Poverty rate) ytitle("MSE x 10000") xsize(5) ysize(5)

graph export "$figs\mse_het_mex.eps", as(eps) name("Graph") replace


*===============================================================================
//Under non-normal errors - fat tails
*===============================================================================
use "$dpath\mex_results_lasso_nn8_normal_draw.dta", clear
	split variable, parse(_)
	gen double ptile = real(variable3)	
	rename value imputed
	keep ptile imputed variable
	replace variable = "lnnd"
tempfile lasso_nn_nd
save `lasso_nn_nd'

use "$dpath\mex_results_lasso.dta", clear
	keep if etype=="nonnormal_8"
	reshape long lasso_pov_, i(sim_sample) j(ptile)
	rename lasso_pov_ imputed
	gen variable = "Lasso empirical"
	
	keep ptile imputed variable
tempfile lasso_emp
save `lasso_emp'

use "$dpath\mex_results_rf.dta", clear
	keep if etype=="nonnormal_8"
	reshape long rf_pov_, i(sim_sample) j(ptile)
	rename rf_pov_ imputed
	gen variable = "RF empirical"
	
	keep ptile imputed variable
tempfile rf_emp
save `rf_emp'

use "$dpath\mex_results_ols_e.dta", clear
	keep if etype=="nonnormal_8"
	reshape long ols_e_pov_, i(sim_sample) j(ptile)
	rename ols_e_pov_ imputed
	gen variable = "OLS empirical"
	
	keep ptile imputed variable
tempfile ols_emp
save `ols_emp'

use "$dpath\nonnormal8_mex_results_mi.dta", clear
	reshape long mi_pov_, i(sim_sample) j(ptile)
	rename mi_pov_ imputed
	gen variable = "Mi 20 BS"
	
	keep ptile imputed variable
tempfile ols_mi
save `ols_mi'

use "$dpath\nonnormal8_mex_results_hetmi.dta", clear
	reshape long mi_pov_, i(sim_sample) j(ptile)
	rename mi_pov_ imputed
	gen variable = "OLS BS 100"
	
	keep ptile imputed variable
tempfile olsbs
save `olsbs'

use "$dpath\nonnormal8_mex_results_hetmi20.dta", clear
	reshape long mi_pov_, i(sim_sample) j(ptile)
	rename mi_pov_ imputed
	gen variable = "OLS BS 20"
	
	keep ptile imputed variable
tempfile olsbs20
save `olsbs20'

use "$dpath\nonnormal8_mex_results.dta", clear
	split variable, parse(_)
	gen double ptile = real(variable3)	
	rename value imputed
	keep ptile imputed variable
	
	append using `olsbs'
	append using `olsbs20'
	append using `ols_mi'
	append using `ols_emp'
	append using `rf_emp'
	append using `lasso_emp'
	append using `lasso_nn_nd'
tempfile imps
save `imps'

use  "$dpath\mex_pov_nums.dta", clear
	keep if variable=="lny_nonnormal_8" 
	keep if measure=="fgt0"
	drop variable
	gen double ptile = real(subinstr(reference,"ptile_","",.))
	
	merge 1:m ptile using `imps'
		drop if _m==2
		drop _m
		
	gen bias = (imputed - value)*100
	gen mse  = (bias)^2
	
	groupfunction, mean(bias mse) by(ptile variable)
	
twoway (scatter bias ptile if regexm(variable,"ols")) ///
(scatter bias ptile if regexm(variable,"OLS BS 20"), msymbol(X)) ///
(scatter bias ptile if regexm(variable,"OLS emp"), msymbol(Th) msize(medium)) ///
(scatter bias ptile if regexm(variable,"Mi 20 BS"), msymbol(square) mcolor(black)) ///
(line bias ptile if regexm(variable,"Lasso"), lpattern(-.-)), ///
legend(label(1 "OLS ignoring non-normal") ///
label(2 "OLS BS 20") ///
label(3 "OLS Empirical") ///
label(4 "MI BS 20") label(5 "Lasso Empirical") ///
pos(6) cols(2)) xtitle(Poverty rate) ytitle("Bias x 100") xsize(5) ysize(5)

graph export "$figs\bias_nonnormal8_mex.eps", as(eps) name("Graph") replace


twoway (scatter mse ptile if regexm(variable,"ols")) ///
(scatter mse ptile if regexm(variable,"OLS BS 20"), msymbol(X)) ///
(scatter mse ptile if regexm(variable,"OLS emp"), msymbol(Th) msize(medium)) ///
(scatter mse ptile if regexm(variable,"Mi 20 BS"), msymbol(square) mcolor(black)) ///
(line    mse ptile if regexm(variable,"Lasso"), lpattern(-.-)), ///
legend(label(1 "OLS ignoring non-normal") ///
label(2 "OLS BS 20") ///
label(3 "OLS Empirical") ///
label(4 "MI BS 20") label(5 "Lasso Empirical") ///
pos(6) cols(2)) xtitle(Poverty rate) ytitle("MSE x 10000") xsize(5) ysize(5)

graph export "$figs\mse_nonnormal8_mex.eps", as(eps) name("Graph") replace

//WITH RF results
twoway (scatter bias ptile if regexm(variable,"ols")) ///
(scatter bias ptile if regexm(variable,"OLS BS 20"), msymbol(X)) ///
(scatter bias ptile if regexm(variable,"OLS emp"), msymbol(Th) msize(medium)) ///
(scatter bias ptile if regexm(variable,"Mi 20 BS"), msymbol(square) mcolor(black)) ///
(line bias ptile if regexm(variable,"Lasso"), lpattern(-.-)) ///
(line bias ptile if regexm(variable,"RF"), lpattern(.)), ///
legend(label(1 "OLS ignoring non-normal") ///
label(2 "OLS BS 20") ///
label(3 "OLS Empirical") ///
label(4 "MI BS 20") label(5 "Lasso Empirical") label(6 "RF Empirical") ///
pos(6) cols(2)) xtitle(Poverty rate) ytitle("Bias x 100") xsize(5) ysize(5)

graph export "$figs\bias_nonnormal8_mex_RF.eps", as(eps) name("Graph") replace


twoway (scatter mse ptile if regexm(variable,"ols")) ///
(scatter mse ptile if regexm(variable,"OLS BS 20"), msymbol(X)) ///
(scatter mse ptile if regexm(variable,"OLS emp"), msymbol(Th) msize(medium)) ///
(scatter mse ptile if regexm(variable,"Mi 20 BS"), msymbol(square) mcolor(black)) ///
(line    mse ptile if regexm(variable,"Lasso"), lpattern(-.-)) ///
(line mse ptile if regexm(variable,"RF"), lpattern(.)), ///
legend(label(1 "OLS ignoring non-normal") ///
label(2 "OLS BS 20") ///
label(3 "OLS Empirical") ///
label(4 "MI BS 20") label(5 "Lasso Empirical") label(6 "RF Empirical") ///
pos(6) cols(2)) xtitle(Poverty rate) ytitle("MSE x 10000") xsize(5) ysize(5)

graph export "$figs\mse_nonnormal8_mex_RF.eps", as(eps) name("Graph") replace

//Results with errors drawn from residual but assuming normal
//WITH RF results
twoway (line bias ptile if regexm(variable,"Lasso"), lpattern(-.-)) ///
(line bias ptile if regexm(variable,"lnnd"), lpattern(.)), ///
legend(label(1 "Lasso Empirical") ///
label(2 "Lasso - errors from residual SD") ///
pos(6) cols(1)) xtitle(Poverty rate) ytitle("Bias x 100") xsize(5) ysize(5)

graph export "$figs\bias_nonnormal8_mex_lnnd.eps", as(eps) name("Graph") replace

//Results with errors drawn from residual but assuming normal
//WITH RF results
twoway (line mse ptile if regexm(variable,"Lasso"), lpattern(-.-)) ///
(line mse ptile if regexm(variable,"lnnd"), lpattern(.)), ///
legend(label(1 "Lasso Empirical") ///
label(2 "Lasso - errors from residual SD") ///
pos(6) cols(1)) xtitle(Poverty rate) ytitle("MSE x 10000") xsize(5) ysize(5)

graph export "$figs\mse_nonnormal8_mex_lnnd.eps", as(eps) name("Graph") replace

//Add hetmiregress results


*===============================================================================
//Under non-normal errors
*===============================================================================

use "$dpath\mex_results_ols_e.dta", clear
	keep if etype=="nonnormal"
	reshape long ols_e_pov_, i(sim_sample) j(ptile)
	rename ols_e_pov_ imputed
	gen variable = "OLS empirical"
	
	keep ptile imputed variable
tempfile ols_emp
save `ols_emp'

use "$dpath\nonnormal_mex_results_mi.dta", clear
	reshape long mi_pov_, i(sim_sample) j(ptile)
	rename mi_pov_ imputed
	gen variable = "Mi 20 BS"
	
	keep ptile imputed variable
tempfile ols_mi
save `ols_mi'

use "$dpath\nonnormal_mex_results_hetmi.dta", clear
	reshape long mi_pov_, i(sim_sample) j(ptile)
	rename mi_pov_ imputed
	gen variable = "OLS BS 100"
	
	keep ptile imputed variable
tempfile olsbs
save `olsbs'

use "$dpath\nonnormal_mex_results_hetmi20.dta", clear
	reshape long mi_pov_, i(sim_sample) j(ptile)
	rename mi_pov_ imputed
	gen variable = "OLS BS 20"
	
	keep ptile imputed variable
tempfile olsbs20
save `olsbs20'

use "$dpath\nonnormal_mex_results.dta", clear
	split variable, parse(_)
	gen double ptile = real(variable3)	
	rename value imputed
	keep ptile imputed variable
	
	append using `olsbs'
	append using `olsbs20'
	append using `ols_mi'
	append using `ols_emp'
tempfile imps
save `imps'

use  "$dpath\mex_pov_nums.dta", clear
	keep if variable=="lny_nonnormal" 
	keep if measure=="fgt0"
	drop variable
	gen double ptile = real(subinstr(reference,"ptile_","",.))
	
	merge 1:m ptile using `imps'
		drop if _m==2
		drop _m
		
	gen bias = (imputed - value)*100
	gen mse  = (bias)^2
	
	groupfunction, mean(bias mse) by(ptile variable)
	
twoway (scatter bias ptile if regexm(variable,"ols")) ///
(scatter bias ptile if regexm(variable,"OLS BS 20"), msymbol(X)) ///
(scatter bias ptile if regexm(variable,"OLS emp"), msymbol(Th)) ///
(scatter bias ptile if regexm(variable,"Mi 20 BS"), msymbol(square) mcolor(black)), ///
legend(label(1 "OLS ignoring non-normal") ///
label(2 "OLS BS 20") ///
label(3 "OLS Empirical") ///
label(4 "MI BS 20") ///
pos(6) cols(2)) xtitle(Poverty rate) ytitle("Bias x 100") xsize(5) ysize(5)

graph export "$figs\bias_nonnormal_mex.eps", as(eps) name("Graph") replace


twoway (scatter mse ptile if regexm(variable,"ols")) ///
(scatter mse ptile if regexm(variable,"OLS BS 20"), msymbol(X)) ///
(scatter mse ptile if regexm(variable,"OLS emp"), msymbol(Th)) ///
(scatter mse ptile if regexm(variable,"Mi 20 BS"), msymbol(square) mcolor(black)), ///
legend(label(1 "OLS ignoring non-normal") label(2 "OLS BS 20")  ///
label(3 "OLS Empirical") label(4 "MI BS 20")  pos(6) cols(2)) xtitle(Poverty rate) ytitle("MSE x 10000") xsize(5) ysize(5)

graph export "$figs\mse_nonnormal_mex.eps", as(eps) name("Graph") replace

*===============================================================================
//Under normally distributed errors, following a nested error model
*===============================================================================
//Ols drawing errors from the empirical distribution
use "$dpath\mex_results_ols_e.dta", clear
	keep if etype=="normal"
	reshape long ols_e_pov_, i(sim_sample) j(ptile)
	rename ols_e_pov_ imputed
	gen variable = "OLS empirical"
	
	keep ptile imputed variable
tempfile ols_emp
save `ols_emp'


//Normal errors, MI
use "$dpath\normal_mex_results_mi100.dta", clear
	reshape long mi_pov_, i(sim_sample) j(ptile)
	rename mi_pov_ imputed
	gen variable = "Mi 100"
	
	keep ptile imputed variable
tempfile mi100
save `mi100'

use "$dpath\normal_mex_results_mi.dta", clear
	reshape long mi_pov_, i(sim_sample) j(ptile)
	rename mi_pov_ imputed
	gen variable = "Mi 20"
	
	keep ptile imputed variable
tempfile mi
save `mi'

//Normal errors
use "$dpath\normal_mex_results.dta", clear
	split variable, parse(_)
	gen double ptile = real(variable3)	
	rename value imputed
	keep ptile imputed variable
	
	append using `mi'
	append using `mi100'
	append using `ols_emp'
	
tempfile imps
save `imps'

use  "$dpath\mex_pov_nums.dta", clear
	keep if variable=="lny_normal" 
	keep if measure=="fgt0"
	drop variable
	gen double ptile = real(subinstr(reference,"ptile_","",.))
	
	merge 1:m ptile using `imps'
		drop if _m==2
		drop _m
		
	gen bias = (imputed - value)*100
	gen mse  = (bias)^2
	
	groupfunction, mean(bias mse) by(ptile variable)
	
/*
Interesting figures comparing the noise and bias of estimates across types of 
imputation methods.

1) Despite the nested structure of the data - and sampling - ignoring the structure
has no impact on the bias and noise. It actually leads to smaller noise and bias 
at the national level.

2) Mi style estimates are noisier and more biased. Misniscule difference between
mi 20 and mi 100. MI is not designed to minimise MSE, thus the results make sense.
*/
		
twoway (scatter bias ptile if regexm(variable,"ols")) ///
(scatter bias ptile if regexm(variable,"re_"), msymbol(X)) ///
(scatter bias ptile if regexm(variable,"Mi 20"), mcolor(black) msymbol(Sh)) ///
(scatter bias ptile if regexm(variable,"Mi 100"), mcolor(gs8) msymbol(.) msize(vsmall)), ///
legend(label(1 "OLS") label(2 "Nested")  ///
label(3 "MI 20") label(4 "MI 100") pos(6) cols(2)) ///
xtitle(Poverty rate) ytitle("Bias x 100") xsize(5) ysize(5)

graph export "$figs\bias_normal_mex.eps", as(eps) name("Graph") replace

twoway (scatter mse ptile if regexm(variable,"ols")) ///
(scatter mse ptile if regexm(variable,"re_"), msymbol(X)) ///
(scatter mse ptile if regexm(variable,"Mi 20"), mcolor(black) msymbol(Sh)) ///
(scatter mse ptile if regexm(variable,"Mi 100"), mcolor(gs8) msymbol(.) msize(vsmall)), ///
legend(label(1 "OLS") label(2 "Nested")  ///
label(3 "MI 20") label(4 "MI 100") pos(6) ///
cols(2)) xtitle(Poverty rate) ytitle("MSE x 10000") xsize(5) ysize(5)

graph export "$figs\mse_normal_mex.eps", as(eps) name("Graph") replace
