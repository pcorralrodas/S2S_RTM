*********************************************************************
* 			                                        				*
*   		The when, the why, and the how to impute: 			  	*
* A practitioners' guide to survey-to-survey imputation of poverty	*
* 			                                        				*
*********************************************************************  
*** Authors: Paul Corral, Leonardo Lucchetti, Andres Ham ***
*** THIS DO-FILE: * Checks the imputation procedure...does the MI approach bring in additional noise? ****
*** VERSION: 08/13/2024 ***

clear all
set maxvar 10000
local sigmaeps = 0.5      //Sigma eps


local mypovlines 
forval z=5(5)95{
	local mypovlines `mypovlines' povline`z'
}

clear mata
mata
	function _f_sampleepsi(real scalar n, real scalar dim, real matrix eps){				  
		sige2 = J(dim,n,0)
		N = rows(eps)
		if (cols(eps)==1) for(i=1; i<=n; i++) sige2[.,i]=eps[ceil(N*runiform(dim,1)),1]
		else              for(i=1; i<=n; i++) sige2[.,i]=eps[ceil(N*runiform(dim,1)),i]
		//for(i=1; i<=n; i++) sige2[.,i]=eps[ceil(rows(eps)*runiform(dim,1)),i]
		return(sige2)	
	}
end

*===============================================================================
// Step 1: Use the full population to get the true values 
*===============================================================================
use "$dpath/full_sample_t.dta", clear
gen all = 1
sp_groupfunction, poverty(e_y) povertyline(`mypovlines') gini(e_y) by(all)
sort measure

gen source = "Full"
gen method = "FULL"

tempfile full
save `full'

*===============================================================================
// Het MI Reg
*===============================================================================
	use "$dpath/srs_sample_t.dta", clear
	expand 2, generate(new)
	replace Y_B = . if new==1
	sort new hhid
	mi set wide
	mi register imputed Y_B
	hetmireg Y_B  x1 x2 x3 x4 x5, sims(100) uniqid(hhid) errdraw(empirical) by(new) lny
	drop if new!=1
	cap drop y_*
	rename yhat* y_*

	
	unab lasvar: y_*
	gen all = 1
	sp_groupfunction, poverty(`lasvar')  povertyline(`mypovlines') gini(`lasvar') by(all)
	groupfunction, by(measure reference) mean(value)
	
	gen method = "Het. Mi Reg"
tempfile hetmireg
save `hetmireg'

*===============================================================================
// STep 2: Follow rforest
*===============================================================================
use "$dpath/srs_sample_t.dta", clear
	sort hhid
	rforest e_y x1-x5, type(reg) numvars(5) iter(200) lsize(5)
	predict xb
	gen double res = Y_B - xb
	gen touse = !missing(res)
	putmata e      = res if touse==1
	putmata xb     = xb  if touse==1
	//Simulate vector a la EBP
	local the_y
	forval z=1/100{
		qui:gen double y_`z' = .
		local the_y `the_y'  y_`z'
		local nv = `z'
	}
	
	mata: st_view(la_y=.,.,tokens("`the_y'"),"touse")
	mata: la_y[.,.] = exp(xb:+_f_sampleepsi(`nv', rows(e),e))
	
	gen all=1
	
	sp_groupfunction, poverty(y_1 - y_100)  povertyline(`mypovlines') gini(y_1 - y_100) by(all)
	groupfunction, by(measure reference) mean(value)
	
	gen method = "rforest"
tempfile rforest
save `rforest'
mata: mata drop xb e

*===============================================================================
// STep 2: Follow LASSO approach
*===============================================================================
use "$dpath/srs_sample_t.dta", clear
	sort hhid
	lasso linear Y_B x1-x5, selection(cv)
	
	predict xb, xb
	gen double res = Y_B - xb
	gen touse = !missing(res)
	putmata e      = res if touse==1
	putmata xb     = xb  if touse==1
	//Simulate vector a la EBP
	local the_y
	forval z=1/100{
		qui:gen double y_`z' = .
		local the_y `the_y'  y_`z'
		local nv = `z'
	}
	
	mata: st_view(la_y=.,.,tokens("`the_y'"),"touse")
	mata: la_y[.,.] = exp(xb:+_f_sampleepsi(`nv', rows(e),e))
	
	gen all=1
	
	sp_groupfunction, poverty(y_1 - y_100)  povertyline(`mypovlines') gini(y_1 - y_100) by(all)
	groupfunction, by(measure reference) mean(value)
	
	gen method = "lasso empirical"
	
tempfile lasso
save `lasso'
mata: mata drop xb e
*===============================================================================
//Select by lowest BIC
*===============================================================================
use "$dpath/srs_sample_t.dta", clear
	sort hhid
	lasso linear Y_B x1-x5, selection(bic)
	
	predict xb, xb
	gen double res = Y_B - xb
	gen touse = !missing(res)
	putmata e      = res if touse==1
	putmata xb     = xb  if touse==1
	//Simulate vector a la EBP
	local the_y
	forval z=1/100{
		qui:gen double y_`z' = .
		local the_y `the_y'  y_`z'
		local nv = `z'
	}
	
	mata: st_view(la_y=.,.,tokens("`the_y'"),"touse")
	mata: la_y[.,.] = exp(xb:+_f_sampleepsi(`nv', rows(e),e))
	
	gen all=1
	
	sp_groupfunction, poverty(y_1 - y_100)  povertyline(`mypovlines') gini(y_1 - y_100) by(all)
	groupfunction, by(measure reference) mean(value)
	
	gen method = "lasso BIC"

append using `lasso'
tempfile lasso
save `lasso'
mata: mata drop xb e
*===============================================================================
//Select by lowest BIC
*===============================================================================

use "$dpath/srs_sample_t.dta", clear
	sort hhid
	lasso linear Y_B x1-x5, selection(adaptive)
	
	predict xb, xb
	gen double res = Y_B - xb
	gen touse = !missing(res)
	putmata e      = res if touse==1
	putmata xb     = xb  if touse==1
	//Simulate vector a la EBP
	local the_y
	forval z=1/100{
		qui:gen double y_`z' = .
		local the_y `the_y'  y_`z'
		local nv = `z'
	}
	
	mata: st_view(la_y=.,.,tokens("`the_y'"),"touse")
	mata: la_y[.,.] = exp(xb:+_f_sampleepsi(`nv', rows(e),e))
	
	gen all=1
	
	sp_groupfunction, poverty(y_1 - y_100)  povertyline(`mypovlines') gini(y_1 - y_100) by(all)
	groupfunction, by(measure reference) mean(value)
	
	gen method = "lasso adaptive"

append using `lasso'
tempfile lasso
save `lasso'
mata: mata drop xb e


*===============================================================================
// STep 2: Follow EBP approach - no fixe
*===============================================================================
use "$dpath/srs_sample_t.dta", clear
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
// STep 2: lnskew fix
*===============================================================================
use "$dpath/srs_sample_t.dta", clear
	sort hhid
	lnskew0 newY = e_y
	local G = r(gamma)
	reg newY x1 x2 x3 x4 x5, r
	predict xb, xb
	local SiGma = e(rmse)
	
	//Simulate vector a la EBP
	forval z=1/100{
		gen double y_`z' = exp(rnormal(xb, `SiGma')) +`G' 
	}
	gen all=1
	
	sp_groupfunction, poverty(y_1 - y_100)  povertyline(`mypovlines') gini(y_1 - y_100) by(all)
	groupfunction, by(measure reference) mean(value)
	
	gen method = "A la EBP skew"
append using `ebp'
tempfile ebp
save `ebp'

*===============================================================================
// bcox fix
*===============================================================================
use "$dpath/srs_sample_t.dta", clear
	sort hhid
	bcskew0 newY = e_y
	local G = r(lambda)
	reg newY x1 x2 x3 x4 x5, r
	predict xb, xb
	local SiGma = e(rmse)
	
	//Simulate vector a la EBP
	forval z=1/100{
		gen double y_`z' = (`G'*rnormal(xb, `SiGma') +1)^(1/`G') 
	}
	gen all=1
	
	sp_groupfunction, poverty(y_1 - y_100)  povertyline(`mypovlines') gini(y_1 - y_100) by(all)
	groupfunction, by(measure reference) mean(value)
	
	gen method = "A la EBP bcox"
append using `ebp'	
tempfile ebp
save `ebp'

	
*===============================================================================
// STep 3: Follow MI approach
*===============================================================================

	use "$dpath/srs_sample_t.dta", clear
	expand 2, generate(new)
	replace Y_B = . if new==1
	sort new hhid
	mi set wide
	mi register imputed Y_B
	mi impute reg Y_B  x1 x2 x3 x4 x5, add(100)
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
	
	gen method = "MI 100"
	
	cap append using `uno'
	tempfile uno
	save `uno'

append using `hetmireg'
append using `rforest'
append using `lasso'
append using `ebp'
append using `full'
tempfile uno
save `uno'

*===============================================================================
// STep 4: Follow MI approach - bootstrap
*===============================================================================

	use "$dpath/srs_sample_t.dta", clear
	expand 2, generate(new)
	replace Y_B = . if new==1
	sort new hhid
	mi set wide
	mi register imputed Y_B
	mi impute reg Y_B  x1 x2 x3 x4 x5, add(100) bootstrap
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
	
	gen method = "MI 100 BS"
	
	cap append using `uno'
	tempfile uno
	save `uno'

gen sim = $zed

if ($zed==1) save "$dpath/results_micomps_t.dta", replace
else{
	append using "$dpath/results_micomps_t.dta"
	save "$dpath/results_micomps_t.dta", replace
}
