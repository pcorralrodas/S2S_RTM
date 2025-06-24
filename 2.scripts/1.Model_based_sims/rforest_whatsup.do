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

set seed 73730


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
// STep 2: Follow rforest
*===============================================================================
//use "$dpath/srs_sample_t.dta", clear
use "$dpath/srs_sample_t.dta", clear
append using "$dpath\full_sample_t.dta", gen(lamuestra)
	rforest Y_B x1-x5 in 1/4000, type(reg) numvars(3) iter(200) lsize(5)
	predict xb
	gen double res = Y_B - xb
	gen touse = !missing(res)
	putmata e      = res if touse==1
	putmata xb     = xb  if touse==1
	
	reg Y_B x1-x5 if lam==0, r
	predict xb_ols, xb
	predict res_ols, res
	
	putmata e_ols      = res_ols if touse==1
	putmata xb_ols     = xb_ols  if touse==1
	
	gen lny = ln(e_y)
	gen res_RF = lny - xb
	gen res_OLS = lny-xb_ols
	gen mse_RF = res_RF ^2
	gen mse_OLS = res_OLS ^2	
	
	tabstat mse_RF mse_OLS, by(lamuestra )
	
	
	
	//Simulate vector a la EBP
	local the_y
	forval z=1/100{
		qui:gen double y_`z' = .
		local the_y `the_y'  y_`z'
		local nv = `z'
	}
	
	mata: st_view(la_y=.,.,tokens("`the_y'"),"touse")
	mata: la_y[.,.] = xb:+_f_sampleepsi(`nv', rows(e),e)
	
	//Simulate vector a la EBP
	local the_y2
	forval z=1/100{
		qui:gen double y2_`z' = .
		local the_y2 `the_y2'  y2_`z'
		local nv = `z'
	}
	
	mata: st_view(la_y2=.,.,tokens("`the_y2'"),"touse")
	mata: la_y2[.,.] = xb_ols:+_f_sampleepsi(`nv', rows(e_ols),e_ols)
	
	egen var =rsd(y_*)
	egen var_ols =rsd(y2_*)
	
	egen mean =rmean(y_*)
	egen mean_ols =rmean(y2_*)
	
	xtile Q10 = Y_B, nq(10)
	gen res2 = res^2
	gen res2_ols = res_ols^2
	
	xtile true = Y_B, nq(5)
xtile qrf = xb, nq(5)
xtile qols = xb_ols, nq(5)
tab true qrf, row nofreq
tab true qols, row nofreq


	
	sum var*
	gen tile = Y_B

	