clear
	
	global numobs = 20000
	global outsample = 50
	global areasize  = 500
	global psusize   = 50
	
	//We have 2 location effects below
	global sigmaeta   = 0.15   
	global sigmapsu  = 0.07
	//We have household specific errors
	global sigmaeps   = 0.45
	global model x1 x2
	
	local obsnum    = $numobs
	local areasize  = $areasize
	local psusize   = $psusize
	
*===============================================================================
//Create fake dataset
*===============================================================================

	set obs `obsnum'
	
	gen dom = (mod(_n,`areasize')==1)*_n 
	gen psu  = (mod(_n,`psusize')==1)*_n
	
	gen u1 = rnormal(0,$sigmaeta) if dom!=0
	gen u2 = rnormal(0, $sigmapsu)  if psu!=0
	
	replace dom = dom[_n-1] if dom==0
	replace psu = psu[_n-1] if psu==0
	
	replace u1 = u1[_n-1] if u1==.
	replace u2 = u2[_n-1] if u2==.
	gen e      = rnormal(0,$sigmaeps)
	
	foreach i in dom psu{
		egen g2 = group(`i')
		replace `i' = g2
		drop g2
	}
	
	gen tdom=real(substr(string(psu),-1,1))
	replace tdom = 10 if tdom==0
	drop psu

	//Household identifier
	gen hhid = _n
	//Hierarchical ID
	gen HID = 100*(100+dom) +tdom
	//Household expansion factors - assume all 1
	gen hhsize = 1
	//Covariates, some are corrlated to the area's label
	gen x1 = round(max(1,rpoisson(3)*(1-.1*dom/int(`obsnum'/`areasize'))),1)
	gen x2 = runiform()<=(0.2) //*0.05*x1 //artificial correlation
	gen x3 = runiform()<(0.5) if x2==1
	replace x3 = 0 if x2==0
	gen x4 = rnormal(2.5, 2)*(1+0.2*tdom/int(`areasize'/`psusize') +0.1*dom/int(`obsnum'/`areasize'))
	gen x5  = rt(5)*.25


	//Welfare vector
	gen linear_fit = 3 + 0.1* x1 + 0.5* x2 - 0.25*x3 - 0.2*x4 - 0.15*x5 
	gen Y_B        = linear_fit + u1 + u2 + e
	
	gen e_y = exp(Y_B)
	
	pctile ptiles= e_y, nq(100)
	
	forval z=5(5)95{
		gen povline`z' = ptiles[`z']
	}
	
	
	drop ptiles
	//Get centiles of the population
	xtile NQ = e_y, nq(100)
	//reg Y_B x*, r
	//sae model reml2 Y_B x*, area(2) subarea(HID)
	
//Sampling
preserve
	keep dom tdom
	duplicates drop dom tdom, force
	
	sample 4, count by(dom)
	
	count
	tempfile tdoms
	save `tdoms'
restore

preserve
	merge m:1 dom tdom using `tdoms'
		keep if _m==3
		sample 20, by(dom tdom)
	
	count	
	save "$dpath/srs_sample_cluster.dta", replace

restore

//Sampling
preserve
	keep dom tdom
	duplicates drop dom tdom, force
	
	sample 4, count by(dom)
	
	count
	tempfile tdoms
	save `tdoms'
restore

preserve
	merge m:1 dom tdom using `tdoms'
		keep if _m==3
		sample 20, by(dom tdom)
	drop Y_B
	count	
	save "$dpath/srs_sample_cluster_target.dta", replace

restore

save "$dpath/full_sample_cluster.dta", replace


