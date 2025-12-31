set more off
clear all

set seed 3739

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

*========================================================================
//Bring in the full data and get plines
*========================================================================
	
	foreach x in het normal nonnormal nonnormal_8{
		use lny_`x' hhsize using "$dpath\mex_census.dta", clear
		global themodel : char _dta[model]
		pctile pct_`x' = lny_`x' [aw=hhsize], nq(100)
		forval z=5(5)95{
			local pline_`x'_`z' = pct_`x'[`z']
		}
	}	
	
*=======================================================================
//Pick a random sample from 1 to 500 to act as source survey
************************************************************************
local sample_num = int(runiform()*500)
use "$mex\my_samples_pps_psu@.dta" if sim_sample==`sample_num', clear

merge 1:1 hhid using "$dpath\mex_census.dta"
	drop if _m!=3
	drop _m

tempfile modeldta
save `modeldta'
*=======================================================================
//Models
************************************************************************
cap: erase "$dpath\mex_results_rf.dta"

foreach etype in het normal nonnormal nonnormal_8{
	use `modeldta', clear
		
	//Now, predict
	use "$mex\my_samples_pps_psu@.dta" if inrange(sim_sample,501,1000), clear
	
	merge m:1 hhid using "$dpath\mex_census.dta"
		drop if _m!=3
		drop _m
	
	append using `modeldta', gen(model)
	sort sim_sample hhid
	rforest lny_`etype' $themodel in 1/23514 , type(reg) iter(100) lsize(5) 
	predict xb
	
	gen double res = lny_`etype' - xb if model==1
	gen touse = !missing(res) & model==1
	putmata e      = res if touse==1
	sum res if touse==1 [aw=Whh] 
	local rmse = r(sd)
	drop if model==1
	drop touse	
	
	//Predict model with RE, note that area effects are ignored!
	drop if missing(xb)
	gen touse=1
	//Simulate vectors
		local the_y
		forval z=5(5)95{
			qui:gen double rf_pov_`z' = .
			local the_y `the_y'rf_pov_`z'
			qui: gen double rfn_pov_`z' = normal((`pline_`etype'_`z'' - xb)/(`rmse'))
		}
		sort sim_sample hhid
		
		keep Whh hhsize rf_pov* sim_sample xb rfn_pov*
		local start = 500
		gen touse = 0
		forval s = 600(100)1000{
			replace touse = inrange(sim_sample,`=`start'+1',`s')
			putmata xb if touse==1
			mata: Yvec = xb:+_f_sampleepsi(100, rows(xb),e)
			forval z=5(5)95{
				dis as error "povline: `z'"
				mata: st_view(la_y=.,.,tokens("rf_pov_`z'"),"touse")
				mata: la_y[.,.] = mean((Yvec:<`pline_`etype'_`z'')')'
			}
			mata:mata drop xb Yvec
			local start = `s'
		}
		
	gen popw = Whh*hhsize
	groupfunction [aw=popw], mean(rf_pov* rfn_pov*) by(sim_sample)
	
	gen etype = "`etype'"
	
	cap: append using "$dpath\mex_results_rf.dta"
	save "$dpath\mex_results_rf.dta", replace
	mata:mata drop e
}	
	
	
	
	
	





