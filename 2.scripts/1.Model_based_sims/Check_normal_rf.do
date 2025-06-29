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
set maxvar 15000

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
		
		return(sige2)	
	}
end


*===============================================================================
// STep 2: Follow rforest
*===============================================================================
//use "$dpath/srs_sample_cluster.dta", clear
use "$dpath/srs_sample_t.dta", clear
//use "$dpath/srs_sample.dta", clear
	rforest Y_B x1-x5, type(reg) numvars(3) iter(200) lsize(5)
	predict xb
	gen res = Y_B - xb
	
	***The Concept and Empirical Evidence of SWIFT Methodology***
	sum res 
	local rmse = r(sd)
	
	forval z=1/100{
		gen N_y_`z' = exp(rnormal(xb,`rmse'))
	}
	*************************************************************
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
	
	sp_groupfunction, poverty(y_1 - y_100 N_y_*)  povertyline(`mypovlines')  by(all)
	gen method = "normal"*regexm(variable,"N_y")+"empirical"*(regexm(variable,"N_y")==0)
	
	groupfunction, by(measure method reference) mean(value)
	
	keep if measure=="fgt0"
	gen line = real(subinstr(ref,"povline","",.))
	gen bias =  100*value - line
	twoway (line bias line if method=="empirical", sort(line)) (scatter bias line if method!="empirical")
	//Same same!
