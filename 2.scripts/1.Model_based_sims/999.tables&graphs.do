*********************************************************************
* 			                                        				*
*   		The when, the why, and the how to impute: 			  	*
* A practitioners' guide to survey-to-survey imputation of poverty	*
* 			                                        				*
*********************************************************************  
*** Authors: Paul Corral, Leonardo Lucchetti, Andres Ham ***
*** THIS DO-FILE: * Calculates tables and graphs from simulation results ****
*** VERSION: 08/15/2024 ***

clear 

* Opens first set of simulation results
use "$dpath/results_reweight_1.dta", clear

* Defines matrix for table
mat simulation_results_1=J(18,10,.)

* Useful transformations
gen method_numeric=.
replace method_numeric=1 if method=="FULL"
replace method_numeric=2 if method=="SRS"
replace method_numeric=3 if method=="Standardize All"
replace method_numeric=4 if method=="Standardize xb"
replace method_numeric=5 if method=="Weight 1"
replace method_numeric=6 if method=="Weight 2"
replace method_numeric=7 if method=="Weight 3"
replace method_numeric=8 if method=="Weight 4"


*** True values ***

* Gini
summ value if measure=="gini" & method=="FULL"
mat simulation_results_1[1,1]=r(mean)

* Poverty
loc povlines "povline5 povline10 povline15 povline20 povline25 povline30 povline35 povline40 povline45"

loc j=2
foreach z of local povlines {
	
	summ value if measure=="fgt0" & reference=="`z'" & method=="FULL"
	mat simulation_results_1[1,`j']=r(mean)
	
	loc ++j
}

*** Sample ***

* Gini
summ value if measure=="gini" & method=="SRS"
mat simulation_results_1[3,1]=(r(mean)-simulation_results_1[1,1])*100

* Poverty
loc povlines "povline5 povline10 povline15 povline20 povline25 povline30 povline35 povline40 povline45"

loc j=2
foreach z of local povlines {
	
	summ value if measure=="fgt0" & reference=="`z'" & method=="SRS"
	mat simulation_results_1[3,`j']=(r(mean)-simulation_results_1[1,`j'])*100
	
	loc ++j
}


*** Bottom biased samples ***

loc i=5
forvalues m=3/8 {
	
	* Gini
	summ value if measure=="gini" & source=="biased_sample" & method_numeric==`m'
	mat simulation_results_1[`i',1]=(r(mean)-simulation_results_1[1,1])*100
	
	* Poverty
	loc povlines "povline5 povline10 povline15 povline20 povline25 povline30 povline35 povline40 povline45"
	
	loc j=2
	foreach z of local povlines {
	
		summ value if measure=="fgt0" & reference=="`z'" & source=="biased_sample" & method_numeric==`m'
		mat simulation_results_1[`i',`j']=(r(mean)-simulation_results_1[1,`j'])*100
	
		loc ++j
	}
	
	loc ++i
}


*** Bottom biased samples ***

loc i=13
forvalues m=3/8 {
	
	* Gini
	summ value if measure=="gini" & source=="biased_sample_topbottom" & method_numeric==`m'
	mat simulation_results_1[`i',1]=(r(mean)-simulation_results_1[1,1])*100
	
	* Poverty
	loc povlines "povline5 povline10 povline15 povline20 povline25 povline30 povline35 povline40 povline45"
	
	loc j=2
	foreach z of local povlines {
	
		summ value if measure=="fgt0" & reference=="`z'" & source=="biased_sample_topbottom" & method_numeric==`m'
		mat simulation_results_1[`i',`j']=(r(mean)-simulation_results_1[1,`j'])*100
	
		loc ++j
	}
	
	loc ++i
}

mat list simulation_results_1

preserve
drop _all
svmat double simulation_results_1
export excel using "$dpath/simulation_results_1.xlsx", replace
restore


***** GRAPHS ****
set scheme s1mono

* Stores poverty results in new matrices
mat SRS=simulation_results_1[3,2..10]'
mat bottom_biased_pov=simulation_results_1[5..10,2..10]'
mat topbottom_biased_pov=simulation_results_1[13..18,2..10]'

*** SRS RESULTS ***

preserve
drop _all
svmat double SRS

ren SRS1 sim1

gen z=.
replace z=5 if _n==1
replace z=10 if _n==2
replace z=15 if _n==3
replace z=20 if _n==4
replace z=25 if _n==5
replace z=30 if _n==6
replace z=35 if _n==7
replace z=40 if _n==8
replace z=45 if _n==9
label var z "Poverty line"

label var sim1 "Simple random sample"

* Options
global s1 mcolor(black) msymbol(O) mlcolor(black) mlwidth(thin) connect(l) lcolor(black) lwidth(medium) lpattern(solid)

* Graphs results
twoway (scatter sim1 z, $s1 ),												///
	ylabel(-4(1)2, format(%4.0fc) labsize(small)) ytitle("Bias (in %)")  ///
 	xtitle("Actual poverty") xlabel(5(5)45, labsize(small)) xscale(range(5 45)) ///
	legend(rows(3) cols(2) region(lstyle(none)) size(vsmall)) subtitle("Simple random sample", size(small))
graph export "$dpath/SRS_pov_results.pdf", replace

restore 

*** BOTTOM BIASED RESULTS ***

preserve
drop _all
svmat double bottom_biased_pov

ren bottom_biased_pov1 sim1
ren bottom_biased_pov2 sim2
ren bottom_biased_pov3 sim3
ren bottom_biased_pov4 sim4
ren bottom_biased_pov5 sim5
ren bottom_biased_pov6 sim6

gen z=.
replace z=5 if _n==1
replace z=10 if _n==2
replace z=15 if _n==3
replace z=20 if _n==4
replace z=25 if _n==5
replace z=30 if _n==6
replace z=35 if _n==7
replace z=40 if _n==8
replace z=45 if _n==9
label var z "Poverty line"

label var sim1 "Standardize all covariates"
label var sim2 "Standardize X{&beta}"
label var sim3 "Covariate mean match"
label var sim4 "Covariate mean and variance match"
label var sim5 "X{&beta} match"
label var sim6 "X{&beta} and Var[X{&beta}] match"

* Options
global s1 mcolor(black) msymbol(Oh) mlcolor(black) mlwidth(thin) connect(l) lcolor(black) lwidth(medium) lpattern(solid)
global s2 mcolor(black) msymbol(D) mlcolor(black) mlwidth(thin) connect(l) lcolor(black) lwidth(medium) lpattern(dash)
global s3 mcolor(cranberry) msymbol(Th) mlcolor(cranberry) mlwidth(thin) connect(l) lcolor(cranberry) lwidth(medium) lpattern(solid)
global s4 mcolor(cranberry) msymbol(S) mlcolor(cranberry) mlwidth(thin) connect(l) lcolor(cranberry) lwidth(medium) lpattern(dot)
global s5 mcolor(ebblue) msymbol(X) mlcolor(ebblue) mlwidth(thin) connect(l) lcolor(ebblue) lwidth(medium) lpattern(solid)
global s6 mcolor(ebblue) msymbol(+) mlcolor(ebblue) mlwidth(thin) connect(l) lcolor(ebblue) lwidth(medium) lpattern(shortdash)

* Graphs results
twoway (scatter sim1 z, $s1 ) 											///
	(scatter sim2 z, $s2 )												///
	(scatter sim3 z, $s3 )												///
	(scatter sim4 z, $s4 )												///
	(scatter sim5 z, $s5 )												///
	(scatter sim6 z, $s6 ),												///
	ylabel(-4(1)2, format(%4.0fc) labsize(small)) ytitle("Bias (in %)")  ///
 	xtitle("Actual poverty") xlabel(5(5)45, labsize(small)) xscale(range(5 45)) ///
	legend(rows(3) cols(2) region(lstyle(none)) size(vsmall)) subtitle("Bottom-biased samples", size(small))
graph export "$dpath/bottom_biased_pov_results.pdf", replace

restore 

*** TOP&BOTTOM BIASED RESULTS ***

preserve
drop _all
svmat double topbottom_biased_pov

ren topbottom_biased_pov1 sim1
ren topbottom_biased_pov2 sim2
ren topbottom_biased_pov3 sim3
ren topbottom_biased_pov4 sim4
ren topbottom_biased_pov5 sim5
ren topbottom_biased_pov6 sim6

gen z=.
replace z=5 if _n==1
replace z=10 if _n==2
replace z=15 if _n==3
replace z=20 if _n==4
replace z=25 if _n==5
replace z=30 if _n==6
replace z=35 if _n==7
replace z=40 if _n==8
replace z=45 if _n==9
label var z "Poverty line"

label var sim1 "Standardize all covariates"
label var sim2 "Standardize X{&beta}"
label var sim3 "Covariate mean match"
label var sim4 "Covariate mean and variance match"
label var sim5 "X{&beta} match"
label var sim6 "X{&beta} and Var[X{&beta}] match"

* Options
global s1 mcolor(black) msymbol(Oh) mlcolor(black) mlwidth(thin) connect(l) lcolor(black) lwidth(medium) lpattern(solid)
global s2 mcolor(black) msymbol(D) mlcolor(black) mlwidth(thin) connect(l) lcolor(black) lwidth(medium) lpattern(dash)
global s3 mcolor(cranberry) msymbol(Th) mlcolor(cranberry) mlwidth(thin) connect(l) lcolor(cranberry) lwidth(medium) lpattern(solid)
global s4 mcolor(cranberry) msymbol(S) mlcolor(cranberry) mlwidth(thin) connect(l) lcolor(cranberry) lwidth(medium) lpattern(dot)
global s5 mcolor(ebblue) msymbol(X) mlcolor(ebblue) mlwidth(thin) connect(l) lcolor(ebblue) lwidth(medium) lpattern(solid)
global s6 mcolor(ebblue) msymbol(+) mlcolor(ebblue) mlwidth(thin) connect(l) lcolor(ebblue) lwidth(medium) lpattern(shortdash)

* Graphs results
twoway (scatter sim1 z, $s1 ) 											///
	(scatter sim2 z, $s2 )												///
	(scatter sim3 z, $s3 )												///
	(scatter sim4 z, $s4 )												///
	(scatter sim5 z, $s5 )												///
	(scatter sim6 z, $s6 ),												///
	ylabel(-4(1)2, format(%4.0fc) labsize(small)) ytitle("Bias (in %)")  ///
 	xtitle("Actual poverty") xlabel(5(5)45, labsize(small)) xscale(range(5 45)) ///
	legend(rows(3) cols(2) region(lstyle(none)) size(vsmall)) subtitle("Top & Bottom-biased samples", size(small))
graph export "$dpath/topbottom_biased_pov_results.pdf", replace

restore 


* Opens second set of simulation results
import excel using "$dpath/Changing constant.xlsx", clear firstrow

* Defines matrix for table
mat simulation_results_2=J(50,9,.)

* Poverty
loc povlines "povline5 povline10 povline15 povline20 povline25 povline30 povline35 povline40 povline45"

loc j=1
foreach z of local povlines {
	
	loc i=1
	forvalues k=-25(1)24 {
	
		summ value if measure=="fgt0" & reference=="`z'" & pchange_constant==`k'
		mat simulation_results_2[`i',`j']=r(mean)
	
		loc ++i
	
		}
	
	loc ++j
}

preserve
drop _all
svmat double simulation_results_2

ren simulation_results_21 povline5
ren simulation_results_22 povline10
ren simulation_results_23 povline15
ren simulation_results_24 povline20
ren simulation_results_25 povline25
ren simulation_results_26 povline30
ren simulation_results_27 povline35
ren simulation_results_28 povline40
ren simulation_results_29 povline45

gen bias5=povline5-0.05
gen bias10=povline10-0.10
gen bias15=povline15-0.15
gen bias20=povline20-0.20
gen bias25=povline25-0.25
gen bias30=povline30-0.30
gen bias35=povline35-0.35
gen bias40=povline40-0.40
gen bias45=povline45-0.45

loc variables bias5 bias10 bias15 bias20 bias25 bias30 bias35 bias40 bias45
foreach var of local variables {
	replace `var'=`var'*100
}

label var bias5 "Poverty=5%"
label var bias10 "Poverty=10%"
label var bias15 "Poverty=15%"
label var bias20 "Poverty=20%"
label var bias25 "Poverty=25%"
label var bias30 "Poverty=30%"
label var bias35 "Poverty=35%"
label var bias40 "Poverty=40%"
label var bias45 "Poverty=45%"

gen pchange_constant = -26 + _n

* Options
global s1 msymbol(none) connect(l) lcolor(black) lwidth(medium) lpattern(solid)
global s2 msymbol(none) connect(l) lcolor(gs2) lwidth(medium) lpattern(solid)
global s3 msymbol(none) connect(l) lcolor(navy) lwidth(medium) lpattern(solid)
global s4 msymbol(none) connect(l) lcolor(blue) lwidth(medium) lpattern(solid)
global s5 msymbol(none) connect(l) lcolor(ebblue) lwidth(medium) lpattern(solid)
global s6 msymbol(none) connect(l) lcolor(teal) lwidth(medium) lpattern(solid)
global s7 msymbol(none) connect(l) lcolor(dkorange) lwidth(medium) lpattern(solid)
global s8 msymbol(none) connect(l) lcolor(orange_red) lwidth(medium) lpattern(solid)
global s9 msymbol(none) connect(l) lcolor(cranberry) lwidth(medium) lpattern(solid)

* Graphs results
twoway (scatter bias5 pchange_constant, $s1 ) ///
	(scatter bias10 pchange_constant, $s2 ) ///
	(scatter bias15 pchange_constant, $s3 ) ///
	(scatter bias20 pchange_constant, $s4 ) ///
	(scatter bias25 pchange_constant, $s5 ) ///
	(scatter bias30 pchange_constant, $s6 ) ///
	(scatter bias35 pchange_constant, $s7 ) 	///
	(scatter bias40 pchange_constant, $s8 ) 	///
	(scatter bias45 pchange_constant, $s9 ), ///
	ylabel(-50(25)50, format(%4.0fc) labsize(small)) ytitle("Bias (in %)")  ///
 	xtitle("Percent change in constant") xlabel(-25(5)25, labsize(small)) xscale(range(-25 25)) ///
	legend(rows(2) cols(5) region(lstyle(none)) size(vsmall))
graph export "$dpath/changing_constant.pdf", replace

restore

* Opens third set of simulation results
import excel using "$dpath/Changing sigma.xlsx", clear firstrow

* Defines matrix for table
mat simulation_results_3=J(50,9,.)

* Poverty
loc povlines "povline5 povline10 povline15 povline20 povline25 povline30 povline35 povline40 povline45"

loc j=1
foreach z of local povlines {
	
	loc i=1
	forvalues k=-25(1)24 {
	
		summ value if measure=="fgt0" & reference=="`z'" & pchange_sigma==`k'
		mat simulation_results_3[`i',`j']=r(mean)
	
		loc ++i
	
		}
	
	loc ++j
}

preserve
drop _all
svmat double simulation_results_2

ren simulation_results_21 povline5
ren simulation_results_22 povline10
ren simulation_results_23 povline15
ren simulation_results_24 povline20
ren simulation_results_25 povline25
ren simulation_results_26 povline30
ren simulation_results_27 povline35
ren simulation_results_28 povline40
ren simulation_results_29 povline45

gen bias5=povline5-0.05
gen bias10=povline10-0.10
gen bias15=povline15-0.15
gen bias20=povline20-0.20
gen bias25=povline25-0.25
gen bias30=povline30-0.30
gen bias35=povline35-0.35
gen bias40=povline40-0.40
gen bias45=povline45-0.45

loc variables bias5 bias10 bias15 bias20 bias25 bias30 bias35 bias40 bias45
foreach var of local variables {
	replace `var'=`var'*100
}

label var bias5 "Poverty=5%"
label var bias10 "Poverty=10%"
label var bias15 "Poverty=15%"
label var bias20 "Poverty=20%"
label var bias25 "Poverty=25%"
label var bias30 "Poverty=30%"
label var bias35 "Poverty=35%"
label var bias40 "Poverty=40%"
label var bias45 "Poverty=45%"

gen pchange_constant = -26 + _n

* Options
global s1 msymbol(none) connect(l) lcolor(black) lwidth(medium) lpattern(solid)
global s2 msymbol(none) connect(l) lcolor(gs2) lwidth(medium) lpattern(solid)
global s3 msymbol(none) connect(l) lcolor(navy) lwidth(medium) lpattern(solid)
global s4 msymbol(none) connect(l) lcolor(blue) lwidth(medium) lpattern(solid)
global s5 msymbol(none) connect(l) lcolor(ebblue) lwidth(medium) lpattern(solid)
global s6 msymbol(none) connect(l) lcolor(teal) lwidth(medium) lpattern(solid)
global s7 msymbol(none) connect(l) lcolor(dkorange) lwidth(medium) lpattern(solid)
global s8 msymbol(none) connect(l) lcolor(orange_red) lwidth(medium) lpattern(solid)
global s9 msymbol(none) connect(l) lcolor(cranberry) lwidth(medium) lpattern(solid)

* Graphs results
twoway (scatter bias5 pchange_constant, $s1 ) ///
	(scatter bias10 pchange_constant, $s2 ) ///
	(scatter bias15 pchange_constant, $s3 ) ///
	(scatter bias20 pchange_constant, $s4 ) ///
	(scatter bias25 pchange_constant, $s5 ) ///
	(scatter bias30 pchange_constant, $s6 ) ///
	(scatter bias35 pchange_constant, $s7 ) 	///
	(scatter bias40 pchange_constant, $s8 ) 	///
	(scatter bias45 pchange_constant, $s9 ), ///
	ylabel(-50(25)50, format(%4.0fc) labsize(small)) ytitle("Bias (in %)")  ///
 	xtitle("Percent change in {&sigma}") xlabel(-25(5)25, labsize(small)) xscale(range(-25 25)) ///
	legend(rows(2) cols(5) region(lstyle(none)) size(vsmall))
graph export "$dpath/changing_sigma.pdf", replace

restore

* Opens fourth set of simulation results
use "$dpath/results_micomps.dta", clear

* Useful transformations
gen method_numeric=.
replace method_numeric=1 if method=="FULL"
replace method_numeric=2 if method=="A la EBP"
replace method_numeric=3 if method=="MI 20"
replace method_numeric=4 if method=="MI 40"
replace method_numeric=5 if method=="MI 60"
replace method_numeric=6 if method=="MI 80"
replace method_numeric=7 if method=="MI 100"

* Defines matrix for table
mat simulation_results_4=J(9,10,.)

*** True values ***

* Gini
summ value if measure=="gini" & method=="FULL"
mat simulation_results_4[1,1]=r(mean)

* Poverty
loc povlines "povline5 povline10 povline15 povline20 povline25 povline30 povline35 povline40 povline45"

loc j=2
foreach z of local povlines {
	
	summ value if measure=="fgt0" & reference=="`z'" & method=="FULL"
	mat simulation_results_4[1,`j']=r(mean)
	
	loc ++j
}

*** A la EBP ***

* Gini
summ value if measure=="gini" & method=="A la EBP"
mat simulation_results_4[3,1]=(r(mean)-simulation_results_4[1,1])*100

* Poverty
loc povlines "povline5 povline10 povline15 povline20 povline25 povline30 povline35 povline40 povline45"

loc j=2
foreach z of local povlines {
	
	summ value if measure=="fgt0" & reference=="`z'" & method=="A la EBP"
	mat simulation_results_4[3,`j']=(r(mean)-simulation_results_4[1,`j'])*100
	
	loc ++j
}

*** MI ***

loc i=5
forvalues m=3/7 {
	
	* Gini
	summ value if measure=="gini" & method_numeric==`m'
	mat simulation_results_4[`i',1]=(r(mean)-simulation_results_4[1,1])*100
	
	* Poverty
	loc povlines "povline5 povline10 povline15 povline20 povline25 povline30 povline35 povline40 povline45"
	
	loc j=2
	foreach z of local povlines {
	
		summ value if measure=="fgt0" & reference=="`z'" & method_numeric==`m'
		mat simulation_results_4[`i',`j']=(r(mean)-simulation_results_4[1,`j'])*100
	
		loc ++j
	}
	
	loc ++i
}

mat list simulation_results_1

preserve
drop _all
svmat double simulation_results_4
export excel using "$dpath/simulation_results_4.xlsx", replace
restore

***** GRAPHS ****
set scheme s1mono

* Stores poverty results in new matrices
mat MI=simulation_results_1[5..9,2..10]'

*** MI RESULTS ***

preserve
drop _all
svmat double MI

ren MI1 MI20
ren MI2 MI40
ren MI3 MI60
ren MI4 MI80
ren MI5 MI100

gen z=.
replace z=5 if _n==1
replace z=10 if _n==2
replace z=15 if _n==3
replace z=20 if _n==4
replace z=25 if _n==5
replace z=30 if _n==6
replace z=35 if _n==7
replace z=40 if _n==8
replace z=45 if _n==9
label var z "Poverty line"

label var MI20 "MI 20"
label var MI40 "MI 40"
label var MI60 "MI 60"
label var MI80 "MI 80"
label var MI100 "MI 100"

* Options
global s1 mcolor(black) msymbol(Oh) mlcolor(black) mlwidth(thin) connect(l) lcolor(black) lwidth(medium) lpattern(solid)
global s2 mcolor(black) msymbol(D) mlcolor(black) mlwidth(thin) connect(l) lcolor(black) lwidth(medium) lpattern(dash)
global s3 mcolor(cranberry) msymbol(Th) mlcolor(cranberry) mlwidth(thin) connect(l) lcolor(cranberry) lwidth(medium) lpattern(solid)
global s4 mcolor(cranberry) msymbol(S) mlcolor(cranberry) mlwidth(thin) connect(l) lcolor(cranberry) lwidth(medium) lpattern(dot)
global s5 mcolor(ebblue) msymbol(X) mlcolor(ebblue) mlwidth(thin) connect(l) lcolor(ebblue) lwidth(medium) lpattern(solid)

* Graphs results
twoway (scatter MI20 z, $s1 ) 											///
	(scatter MI40 z, $s2 )												///
	(scatter MI60 z, $s3 )												///
	(scatter MI80 z, $s4 )												///
	(scatter MI100 z, $s5 ),												///
	ylabel(-4(1)2, format(%4.0fc) labsize(small)) ytitle("Bias (in %)")  ///
 	xtitle("Actual poverty") xlabel(5(5)45, labsize(small)) xscale(range(5 45)) ///
	legend(rows(1) cols(5) region(lstyle(none)) size(vsmall)) subtitle("Multiple imputation", size(small))
graph export "$dpath/MI_results.pdf", replace

restore 
*END
