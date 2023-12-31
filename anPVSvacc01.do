
* Analysis: Health system quality and COVID vaccination in 14 countries
* Created by C.Arsenault, April 2023
/*------------------------------------------------------------------------------*

This dofile includes the STATA code for:
	 -  Creating Figure 1, and Table 1
	 -  Performing the regression analyses for Model 1 (health care utilization) 
	 -  Creating the graphs in figure 2A
	 -  Creating the supplemental tables 
	 -  Performing the meta-analysis for the pooled estimates included in table 2 & supplemental materials

*------------------------------------------------------------------------------*/
global user "/Users/catherine.arsenault/Dropbox"
global data "SPH Kruk QuEST Network/Core Research/People's Voice Survey/PVS External/Data/Multi-country/02 recoded data"
global analysis "SPH Kruk Active Projects/Vaccine hesitancy/Analyses/Paper 7 vaccination/Results"

cd "$user/$analysis/"
u "$user/$analysis/pvs_vacc_analysis.dta", clear

set more off
*------------------------------------------------------------------------------*
* FIGURE 1 COVID DOSES
ta nb_doses c  [aw=weight] , nofreq col
*------------------------------------------------------------------------------*
* DESCRIPTIVE TABLES
* TABLE 1	
summtab, catvars(visits4 usual_source  preventive unmet_need  ///
				 vgusual_quality discrim mistake conf_getafford ///
				 vconf_opinion vgcovid_manage) contvars(visits_total) ///
				 by(country) mean meanrow catrow wts(weight) ///
		         replace excel excelname(Table_1)  	
* SUPPLEMENTAL TABLE 4	
summtab, catvars(health_chronic ever_covid post_secondary high_income female urban minority) ///
		         contvars(age) by(country) mean meanrow catrow wts(weight) ///
		         replace excel excelname(supptable demog)  				

*------------------------------------------------------------------------------*
* COUNTRY-SPECIFIC REGRESSIONS - MODEL 1: UTILIZATION
foreach x in  Ethiopia Kenya LaoPDR Mexico Peru SouthAfrica USA UK {

	putexcel set "$user/$analysis/utilization model.xlsx", sheet("`x'")  modify
			
	logistic fullvax i.visits4 ///
				age2 health_chronic ever_covid post_secondary ///
				high_income female urban minority if c=="`x'", vce(robust) // countries with the variable minority
	putexcel (A1) = etable	
	}
foreach x in Argentina Colombia India Korea Uruguay Italy {

	putexcel set "$user/$analysis/utilization model.xlsx", sheet("`x'")  modify
			
	logistic fullvax i.visits4 ///
				age2 health_chronic ever_covid post_secondary ///
				high_income female urban  if c=="`x'", vce(robust) // countries without the variable minority		
	putexcel (A1) = etable	
	}
*------------------------------------------------------------------------------*
* Importing estimates
import excel using "$user/$analysis/utilization model.xlsx", sheet(Ethiopia) firstrow clear
	drop if B=="" | B=="Odds ratio"
	gen country="Ethiopia"
	save "$user/$analysis/graphs.dta", replace
	
foreach x in  Argentina Colombia India Korea  Uruguay Italy  Kenya LaoPDR Mexico Peru SouthAfrica USA UK { 
	import excel using  "$user/$analysis/utilization model.xlsx", sheet("`x'") firstrow clear
	drop if B=="" | B=="Odds ratio"
	gen country="`x'"
	append using "$user/$analysis/graphs.dta"
	save "$user/$analysis/graphs.dta", replace
	}
	keep A B E F G country 
	gen co = 1 if country=="Ethiopia"
	replace co =2  if country=="Kenya"
	replace co =3  if country=="India"
	replace co =4  if country=="LaoPDR"
	replace co =5  if country=="Peru"
	replace co =6  if country=="SouthAfrica"
	replace co =7  if country=="Colombia"
	replace co =8  if country=="Mexico"
	replace co =9  if country=="Argentina"
	replace co =10  if country=="Uruguay"
	replace co =11  if country=="Italy"
	replace co =12  if country=="Korea"
	replace co =13  if country=="UK"
	replace co =14  if country=="USA"
	
	foreach v in E B F G  {
		destring `v', replace
		gen ln`v' = ln(`v')
	}
	rename (B E F G) (aOR p_value LCL UCL)
* Income groups	
	gen inc_group = 1 if country=="LaoPDR" | countr=="Kenya" | count=="Ethiopia" | country=="India"
	replace inc_group = 2 if count=="SouthAfrica" | count=="Peru" | count=="Mexico" | ///
						     count=="Argentina" | count=="Colombia"
	replace inc_group = 3 if count=="Uruguay" | count=="USA" | count=="Korea" | count=="Italy" | count=="UK"
	lab def inc_group 1"LMI"  2"UMI" 3"HI"
	lab val inc_group inc_group

* COVID severity groups
	gen covidgroup = 1 if  country=="LaoPDR" | countr=="Kenya" | count=="Ethiopia" | country=="India" | count=="Korea" 
	replace covidgroup = 2 if count=="SouthAfrica" | count=="Uruguay" | count=="Mexico" | count=="Colombia" | count=="Argentina"
	replace covidgroup = 3 if count=="Italy" | count=="UK" |  count=="USA" | count=="Peru"
	lab def covidgroup 1"> 1000 deaths per million" 2"1500-3000 deaths per million" 3"3000-6500 deaths per million"
	lab val covidgroup covidgroup
	
*Supplemental table 
	export excel using "$user/$analysis/supp table utilization.xlsx", sheet(Sheet1) firstrow(variable) replace 
	
* GRAPHS UTILIZATION MODELS
preserve 
	replace UCL=6 if UCL==6.89416 // Uruguay outlier UCL
		twoway (rspike UCL LCL co if A=="1-2visits" & co>=1 & co<=4, lwidth(medthick) lcolor(pink)) ///
			   (scatter aOR co if A=="1-2visits" & co>=1 & co<=4, msize(medsmall) mcolor(pink))  ///
			   (rspike UCL LCL co if A=="1-2visits" & co>=5 & co<=9, lwidth(medthick) lcolor(lime)) ///
			   (scatter aOR co if A=="1-2visits" & co>=5 & co<=9, msize(medsmall) mcolor(lime))  ///
			   (rspike UCL LCL co if A=="1-2visits" & co>=10 & co<=14, lwidth(medthick) lcolor(orange)) ///
			   (scatter aOR co if A=="1-2visits" & co>=10 & co<=14, msize(medsmall) mcolor(orange)) , ///
				graphregion(color(white)) legend(off) ///
				xlabel(1"ETH" 2"KEN" 3"IND" 4"LAO" 5"PER" 6"ZAF" 7"COL" 8"MEX" ///
				9"ARG" 10"URY" 11"ITA" 12"KOR" 13"GBR" 14"USA", labsize(vsmall)) xtitle("") ///
				ylabel(0.40(0.4)6, labsize(tiny) gstyle(minor)) ///
				yline(1, lstyle(foreground) lpattern(dash)) xsize(1) ysize(1) ///
				title("Had 1 or 2 visits in last year", size(medium))
		graph export "$user/$analysis/1-2 visits.pdf", replace 

		* GRAPHS UTILIZATION MODELS
		twoway (rspike UCL LCL co if A=="3-4visits" & co>=1 & co<=4, lwidth(medthick) lcolor(pink)) ///
			   (scatter aOR co if A=="3-4visits"& co>=1 & co<=4, msize(medsmall) mcolor(pink))  ///
			   (rspike UCL LCL co if A=="3-4visits" & co>=5 & co<=9, lwidth(medthick) lcolor(lime)) ///
			   (scatter aOR co if A=="3-4visits"& co>=5 & co<=9, msize(medsmall) mcolor(lime))  ///
			   (rspike UCL LCL co if A=="3-4visits" & co>=10 & co<=14, lwidth(medthick) lcolor(orange)) ///
			   (scatter aOR co if A=="3-4visits"& co>=10 & co<=14, msize(medsmall) mcolor(orange)),  ///
				graphregion(color(white)) legend(off) ///
				xlabel(1"ETH" 2"KEN" 3"IND" 4"LAO" 5"PER" 6"ZAF" 7"COL" 8"MEX" ///
				9"ARG" 10"URY" 11"ITA" 12"KOR" 13"GBR" 14"USA", labsize(vsmall)) xtitle("") ///
				ylabel(0.40(0.4)6, labsize(tiny) gstyle(minor)) ///
				yline(1, lstyle(foreground) lpattern(dash) ) xsize(1) ysize(1) ///
				title("Had 3 or 4 visits in last year", size(medium)) 
		graph export "$user/$analysis/3-4 visits.pdf", replace 

			* GRAPHS UTILIZATION MODELS
		twoway (rspike UCL LCL co if A=="5ormorevisits" & co>=1 & co<=4, lwidth(medthick) lcolor(pink)) ///
			   (scatter aOR co if A=="5ormorevisits" & co>=1 & co<=4, msize(medsmall) mcolor(pink))  ///
			   (rspike UCL LCL co if A=="5ormorevisits" & co>=5 & co<=9, lwidth(medthick) lcolor(lime)) ///
			   (scatter aOR co if A=="5ormorevisits" & co>=5 & co<=9, msize(medsmall) mcolor(lime))  ///
			   (rspike UCL LCL co if A=="5ormorevisits" & co>=10 & co<=14, lwidth(medthick) lcolor(orange)) ///
			   (scatter aOR co if A=="5ormorevisits" & co>=10 & co<=14, msize(medsmall) mcolor(orange)) , ///
				graphregion(color(white)) legend(off) ///
				xlabel(1"ETH" 2"KEN" 3"IND" 4"LAO" 5"PER" 6"ZAF" 7"COL" 8"MEX" ///
				9"ARG" 10"URY" 11"ITA" 12"KOR" 13"GBR" 14"USA", labsize(vsmall)) xtitle("") ///
				ylabel(0.40(0.4)6, labsize(tiny) gstyle(minor)) ///
				yline(1, lstyle(foreground) lpattern(dash)) xsize(1) ysize(1) ///
				title("Had 5 or more visits in last year", size(medium))
		graph export "$user/$analysis/5+ visits.pdf", replace 	
restore 
*------------------------------------------------------------------------------*	
* META ANALYSIS - BY INCOME GROUPS
	local row = 1
	
	putexcel set "$user/$analysis/pooled estimates.xlsx", sheet("utilization")  modify
	foreach v in 1-2visits  3-4visits 5ormorevisits {
	
		metan lnB lnF lnG if A=="`v'" , by(inc_group) random ///
				eform nograph  label(namevar=country) effect(aOR) 
	putexcel A`row'="`v'"
	matrix b= r(bystats)
	putexcel B`row'= matrix(b), rownames 
	local row = `row' + 9
	}
* META ANALYSIS - ALL COUNTRIES 
	local row = 1
	
	putexcel set "$user/$analysis/pooled estimates.xlsx", sheet("utilization_all")  modify
	foreach v in 1-2visits  3-4visits 5ormorevisits {
	
		metan lnB lnF lnG if A=="`v'"  ,  random ///
				eform nograph  label(namevar=country) effect(aOR) 
	putexcel A`row'="`v'"
	matrix b= r(ovstats)
	putexcel B`row'= matrix(b), rownames 
	local row = `row' + 9
	}
	
* META ANALYSIS - BY COVID DEATHS
local row = 1
	
	putexcel set "$user/$analysis/pooled estimates_covid sever.xlsx", sheet("utilization")  modify
	foreach v in 1-2visits  3-4visits 5ormorevisits {
	
		metan lnB lnF lnG if A=="`v'" , by(covidgroup) random ///
				eform nograph  label(namevar=country) effect(aOR) 
	putexcel A`row'="`v'"
	matrix b= r(bystats)
	putexcel B`row'= matrix(b), rownames 
	local row = `row' + 9
	}
	