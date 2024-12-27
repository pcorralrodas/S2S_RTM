*********************************************************************
* 			                                        				*
*   		The when, the why, and the how to impute: 			  	*
* A practitioners' guide to survey-to-survey imputation of poverty	*
* 			                                        				*
*********************************************************************  
*** Authors: Paul Corral, Leonardo Lucchetti, Andres Ham ***
*** THIS DO-FILE: * Runs the simulation on imputation for poverty ****
*** VERSION: 08/14/2024 ***

clear all
clear mata
set maxvar 10000
* Defines relevant parameters
local sigmaeps = 0.5      //Sigma eps

local mypovlines 
forval z=5(5)95{
	local mypovlines `mypovlines' povline`z'
}

*set trace on
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
// Step 2: Use the sample to extract mean and variance from sample
*===============================================================================
use "$dpath/srs_sample.dta", clear
forval z=1/5{
	sum x`z'
	mat a = nullmat(a)\r(mean)
	mat v = nullmat(v)\r(Var)
}

sum linear_fit 
mat xb = r(mean)
mat varxb = r(Var)

gen all = 1
sp_groupfunction, poverty(e_y) povertyline(`mypovlines') gini(e_y) by(all)
sort measure

gen source = "SRS"
gen method = "SRS"

append using `full'

tempfile full
save `full'

*===============================================================================
// Step 3...use the biased samples to get "imputed" values
*===============================================================================
local samples biased_sample_topbottom biased_sample

foreach dta of local samples {
	use "$dpath/`dta'.dta", clear
	cap: gen prior = 1
	cap: gen all   = 1
	
	//Non-adjusted
	gen linear_nonadj = 3 + 0.1* x1 + 0.5* x2 - 0.25*x3 - 0.2*x4 - 0.15*x5
	
	//Standardize
	forval x = 1/5{
		sum x`x'
		replace x`x' = (x`x'-r(mean))*(`=sqrt(v[`x',1])'/(r(sd)))+`=a[`x',1]'
	}	
	gen linear_fitmod = 3 + 0.1* x1 + 0.5* x2 - 0.25*x3 - 0.2*x4 - 0.15*x5 
	// I simulate the errors to ensure the same errors are assigned across methods
	forval x=1/100{
		gen e_`x' = rnormal(0, `sigmaeps')
	}
	sum linear_fit
	gen linear_fit_adj = (linear_fit-r(mean))*(`=sqrt(varxb[1,1])'/(r(sd)))+`=xb[1,1]'
	
	preserve
		forval s = 1/100{
			gen w_`s' = exp(linear_nonadj+e_`s')
		}
		sp_groupfunction, poverty(w_1 - w_100)  povertyline(`mypovlines') gini(w_1 - w_100) by(all)
		groupfunction, by(measure reference) mean(value)
		
		gen method = "Non adjusted"
		gen source = "`dta'"
		append using `full'
		tempfile full
		save `full' 
	restore
	
	preserve
		forval s = 1/100{
			gen w_`s' = exp(linear_fitmod+e_`s')
		}
		sp_groupfunction, poverty(w_1 - w_100)  povertyline(`mypovlines') gini(w_1 - w_100) by(all)
		groupfunction, by(measure reference) mean(value)
		
		gen method = "Standardize All"
		gen source = "`dta'"
		append using `full'
		tempfile full
		save `full' 
	restore
	preserve
		forval s = 1/100{
			gen w_`s' = exp(linear_fit_adj+e_`s') 
		}
		sp_groupfunction, poverty(w_1 - w_100)  povertyline(`mypovlines') gini(w_1 - w_100) by(all)
		groupfunction, by(measure reference) mean(value)
		
		gen method = "Standardize xb"	
		gen source = "`dta'"
		append using `full'
		tempfile full
		save `full' 
	restore
	
	
	/*
	/Create new weights...4 sets of weights:
	1) Match means of every single x
	2) Match mean and variance of every single x
	3) Match mean linear fit
	4) Match mean and variance of linear fit
	*/
	timer on 1
	wentropy x1 x2 x3 x4 x5, constraints(a) old(prior) new(W1) pop(20000) iter(1000)
	timer off 1
	count 
	local thetotsN = r(N)
	forval z=1/5{
		gen x`z'_var = ((x`z' - a[`z',1])^2)*(`thetotsN'/(`thetotsN'-1))
	}
	mat mean_var = a\v
	timer on 2	
	wentropy x1 x2 x3 x4 x5 x1_var x2_var x3_var x4_var x5_var, constraints(mean_var) old(prior) new(W2) pop(20000) iter(1000)
	timer off 2
	timer on 3
	wentropy linear_fit, constraints(xb) old(prior) newweight(W3) pop(20000) iter(1000)
	timer off 3
	
	mat mean_var = xb\varxb
	gen linear_fit_var = ((linear_fit - xb[1,1])^2)*(`thetotsN'/(`thetotsN'-1))
	timer on 4	
	wentropy linear_fit linear_fit_var , constraints(mean_var) old(prior) new(W4) pop(20000) iter(1000)
	timer off 4
	
	forval w = 1/4{
		preserve
		forval s = 1/100{
			gen w_`s' = exp(linear_fit+e_`s') 
		}
		sp_groupfunction [aw=W`w'], poverty(w_1 - w_100)  povertyline(`mypovlines') gini(w_1 - w_100) by(all)
		groupfunction, by(measure reference) mean(value)
		gen method = "Weight `w'"	
		gen source = "`dta'"
		append using `full'
		tempfile full
		save `full' 
		restore
	}	
}

use `full', clear
gen sim = $zed

if $zed==1 save "$dpath/results_reweight_1.dta", replace

else{
	append using "$dpath/results_reweight_1.dta"
	save "$dpath/results_reweight_1.dta", replace
}


mat drop a 
mat drop v
mat drop xb
mat drop varxb
