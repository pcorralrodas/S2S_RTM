*********************************************************************
* 			                                        				*
*   		The when, the why, and the how to impute: 			  	*
* A practitioners' guide to survey-to-survey imputation of poverty	*
* 			                                        				*
*********************************************************************  
*** Authors: Paul Corral, Leonardo Lucchetti, Andres Ham ***
*** THIS DO-FILE: * Checks the imputation procedure...does the MI approach bring in additional noise? ****
*** VERSION: 08/13/2024 ***

clear 
local sigmaeps = 0.5      //Sigma eps


local mypovlines 
forval z=5(5)95{
	local mypovlines `mypovlines' povline`z'
}


*===============================================================================
// Step 1: Use the full population to get the true values 
*===============================================================================
use "$dpath/full_sample.dta", clear
gen all = 1
sp_groupfunction, poverty(e_y) povertyline(`mypovlines') gini(e_y) by(all)
sort measure

gen source = "Full"
gen method = "FULL"

tempfile full
save `full'
*===============================================================================
// STep 2: Follow EBP approach
*===============================================================================
use "$dpath/srs_sample.dta", clear
	sort hhid
	reg Y_B  x1 x2 x3 x4 x5, r
	predict xb, xb
	local SiGma = e(rmse)
	
	//Simulate vector a la EBP
	forval z=1/100{
		gen double y_`z' = exp(rnormal(xb, `SiGma'))
	}
	gen all=1
	
	sp_groupfunction, poverty(y_1 - y_100)  povertyline(`mypovlines') gini(y_1 - y_100) by(all)
	groupfunction, by(measure reference) mean(value)
	
	gen method = "A la EBP"
	
tempfile ebp
save `ebp'
	
*===============================================================================
// STep 3: Follow MI approach
*===============================================================================
forval z = 20(20)100{
	use "$dpath/srs_sample.dta", clear
	expand 2, generate(new)
	replace Y_B = . if new==1
	sort new hhid
	mi set wide
	mi register imputed Y_B
	mi impute reg Y_B  x1 x2 x3 x4 x5, add(`z')
	drop if new!=1
	cap drop y_*
	foreach x of varlist _*_Y_B{
		replace `x' = exp(`x')
		local nm = "y"+subinstr("`x'","_Y_B","",.)
		rename `x' `nm'
	}
	unab lasvar: y_*
	gen all = 1
	sp_groupfunction, poverty(`lasvar')  povertyline(`mypovlines') gini(`lasvar') by(all)
	groupfunction, by(measure reference) mean(value)
	
	gen method = "MI `z'"
	
	cap append using `uno'
	tempfile uno
	save `uno'
}
append using `ebp'
append using `full'

gen sim = $zed


if ($zed==1) save "$dpath/results_micomps.dta", replace
else{
	append using "$dpath/results_micomps.dta"
	save "$dpath/results_micomps.dta", replace
}
