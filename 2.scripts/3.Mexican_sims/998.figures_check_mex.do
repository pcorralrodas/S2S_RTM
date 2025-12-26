set more off
clear 

*===============================================================================
//Under heteroskedastic normal errors
*===============================================================================
use  "$dpath\het_mex_results.dta", clear
split variable, parse(_)
	gen double ptile = real(variable3)	
	rename value imputed
	keep ptile imputed variable
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
(scatter bias ptile if regexm(variable,"het"), msymbol(X)), ///
legend(label(1 "Empirical Bias - OLS ignoring heteroskedastic") label(2 "Empirical Bias - MLE with heteroskedastic")  ///
pos(6) cols(1)) xtitle(Poverty rate) ytitle("Bias x 100")

twoway (scatter mse ptile if regexm(variable,"ols")) ///
(scatter mse ptile if regexm(variable,"het"), msymbol(X)), ///
legend(label(1 "Empirical MSE - OLS ignoring heteroskedastic") label(2 "Empirical MSE - MLE with heteroskedastic")  ///
pos(6) cols(1)) xtitle(Poverty rate) ytitle("MSE x 10000")

//Add hetmiregress results


*===============================================================================
//Under non-normal errors
*===============================================================================
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
(scatter bias ptile if regexm(variable,"OLS BS 100"), msymbol(X)) ///
(scatter bias ptile if regexm(variable,"OLS BS 20"), msymbol(T)) ///
(scatter bias ptile if regexm(variable,"Mi 20 BS"), msymbol(square) mcolor(black)), ///
legend(label(1 "Empirical Bias - OLS ignoring non-normal") ///
label(2 "Empirical Bias - OLS BS 100") ///
label(3 "Empirical Bias - OLS BS 20") ///
label(4 "Empirical Bias - Mi BS 20") pos(6) cols(2)) xtitle(Poverty rate) ytitle("Bias x 100")

twoway (scatter mse ptile if regexm(variable,"ols")) ///
(scatter mse ptile if regexm(variable,"OLS BS 100"), msymbol(X)) ///
(scatter mse ptile if regexm(variable,"OLS BS 20"), msymbol(T)) ///
(scatter mse ptile if regexm(variable,"Mi 20 BS"), msymbol(square) mcolor(black)), ///
legend(label(1 "Empirical MSE - OLS ignoring non-normal") label(2 "Empirical MSE - OLS BS 100")  ///
label(3 "Empirical MSE - OLS BS 20") label(4 "Empirical MSE - Mi BS 20")  pos(6) cols(2)) xtitle(Poverty rate) ytitle("MSE x 10000")

*===============================================================================
//Under normally distributed errors, following a nested error model
*===============================================================================
//Normal errors, MI
/*
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
*/
//Normal errors
use "$dpath\normal_mex_results.dta", clear
	split variable, parse(_)
	gen double ptile = real(variable3)	
	rename value imputed
	keep ptile imputed variable
	
	//append using `mi'
	//append using `mi100'
	
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
(scatter bias ptile if regexm(variable,"Mi 20"), mcolor(black) msymbol(square)) ///
(scatter bias ptile if regexm(variable,"Mi 100"), mcolor(red) msymbol(.) msize(vsmall)), ///
legend(label(1 "Empirical Bias - OLS") label(2 "Empirical Bias - nested")  ///
label(3 "Empirical Bias - MI 20") label(4 "Empirical Bias - Mi 100") pos(6) cols(2)) xtitle(Poverty rate) ytitle("Bias x 100")


twoway (scatter mse ptile if regexm(variable,"ols")) ///
(scatter mse ptile if regexm(variable,"re_"), msymbol(X)) ///
(scatter mse ptile if regexm(variable,"Mi 20"), mcolor(black) msymbol(square)) ///
(scatter mse ptile if regexm(variable,"Mi 100"), mcolor(red) msymbol(.) msize(vsmall)), ///
legend(label(1 "Empirical MSE - OLS") label(2 "Empirical MSE - nested")  ///
label(3 "Empirical MSE - MI 20") label(4 "Empirical MSE - Mi 100") pos(6) cols(2)) xtitle(Poverty rate) ytitle("MSE x 10000")


