*********************************************************************
* 			                                        				*
*   		The when, the why, and the how to impute: 			  	*
* A practitioners' guide to survey-to-survey imputation of poverty	*
* 			                                        				*
*********************************************************************  
*** Authors: Paul Corral, Leonardo Lucchetti, Andres Ham ***
*** THIS DO-FILE: Creates data for simulations ****

clear all

*** CHANGE THE FIRST GLOBAL TO THE DIRECTORY WHERE YOU DOWNLOADED THE REPLICATION FILES ***
if (lower("`c(username)'")=="ham_andres"){
	global main    "/Users/ham_andres/Library/CloudStorage/Dropbox/research/wb/S2S/"
}
if (lower("`c(username)'")=="wb378870"){
	global main    "C:/Users//`c(username)'//Github/S2S_RTM/"
}
if (lower("`c(username)'")=="paul corral"){
	global main "C:\Users\Paul Corral\Documents\GitHub\S2S_RTM\"
}

global dpath   "$main/1.data"
global thedo   "$main/2.scripts/1.Model_based_sims"
global theado  "$main/2.scripts/0.ados"
global figs    "$main/5.figures"

set seed 26453

mata
	function _f_sampleepsi(real scalar n, real scalar dim, real matrix eps){				  
		sige2 = J(dim,n,0)
		N = rows(eps)
		if (cols(eps)==1) for(i=1; i<=n; i++) sige2[.,i]=eps[ceil(N*runiform(dim,1)),1]
		else              for(i=1; i<=n; i++) sige2[.,i]=eps[ceil(N*runiform(dim,1)),i]
		
		return(sige2)	
	}
end

//Would you impute?
//Gini under log normal dist
local obsnum    = 20000 	//Number of observations in our survey
local outsample = 20	 	//sample size to take
local sigmaeps  = 0.5      	//Sigma eps

// Create area random effects
set obs `=`obsnum''

//Household identifier
gen hhid = _n
//Household expansion factors - assume all 1
gen hhsize = 1
//Household specific residual	
gen e = rnormal(0,`sigmaeps')
//Covariates, some are corrlated to the area's label
gen x1 = round(max(1,rpoisson(4)),1)
gen x2 = runiform()<=(0.2) //*0.05*x1 //artificial correlation
gen x3 = runiform()<(0.5) if x2==1
replace x3 = 0 if x2==0
gen x4 = rnormal(2.5, 2)
gen x5  = rt(5)*.25


//Welfare vector
gen linear_fit = 3 + 0.1* x1 + 0.5* x2 - 0.25*x3 - 0.2*x4 - 0.15*x5 
gen Y_B = linear_fit + e
gen e_y = exp(Y_B)

pctile ptiles= e_y, nq(100)

forval z=5(5)95{
    gen povline`z' = ptiles[`z'] //Not logged!
	local pline`z' = ptiles[`z'] 
}

drop ptiles

tempfile full

save `full', replace

sample 20
sort hhid //sort to ensure replicability

tempfile sample
save `sample', replace

// Now fit the model
reg Y_B x1 x2 x3 x4 x5, r
//RMSE
local rmse = e(rmse)

//predict residuals
predict res, res
//send residuals to mata
putmata e = res

//Bring in the full data
use `full', replace	

//predict linear fit
predict xb, xb

gen mse_xb = (Y_B - xb)^2

gen xb_e = rnormal(xb,`rmse')

gen mse_xb_e = (Y_B - xb_e)^2

//so xb minimizes the MSE, by a LOT!
sum mse*

spearman Y_B xb xb_e //The spearman rank is highest for xb 

//But, look at what matches the distribution better
tabstat Y_B xb xb_e, stat(min p5 p10 p25 p50 p75 p90 p95 mean sd max)

//Produce figure
foreach x in Y_B xb xb_e{
	pctile pt_`x' = `x', nq(100) 
}

gen ptile = _n if pt_Y_B!=.

twoway (line pt_Y_B ptile, lcolor(black) ) ///
(line pt_xb ptile, lcolor(blue) lpattern(-.-)) ///
(scatter pt_xb_e ptile, mcolor(red) msymbol(Oh)), ///
legend(label(1 "True values") label(2 "XB values") label(3 "XB+e values")) ytitle("Welfare in nat. log") xtitle("Cumulative percent of population") legend(cols(3)) legend(position(6)) 

graph export "$figs\why_errors.eps", as(eps) name("Graph") replace


forval z=5(5)95{
	foreach w in Y_B xb xb_e{
		gen pov`z'_`w' = `w'<ln(`pline`z'')
	}
}

groupfunction, mean(pov*Y_B pov*xb* mse*) 

foreach w in xb xb_e{
	gen diff2_`w' = 0
	forval z= 5(5)95{
		replace diff2_`w' = diff2_`w' + (pov`z'_Y_B-pov`z'_`w')^2 
	}
	gen rmse_pov_`w' = sqrt(diff2_`w'/19)
	gen rmse_`w' = sqrt(mse_`w')
}

sum rmse_pov*
sum rmse_xb*
