********************************************************************************
*****                       PRODUCTIVITY REPORT 2023                       *****  
********************************************************************************
*****                              Chapter 1                               ***** 
*****  The Productivity Puzzle Revisited: Firm Performance Post COVID-19   *****
********************************************************************************

***** ITEM 4: Output gap and potential output from the productivity distribution

***** Reference person: Daniele Aglio (CompNet) 
***** Contributors: Eric Bartelsman (Tinbergen Institute)
***** CompNet 9th Vintage Dataset


clear all
capture log close 
set more off
global directory "Enter Directory"
cd "$directory"


***** Data Preparation
{
*** Open Data
* CompNet Data, Joint Distribution
clear all
use "jd_inp_prod_industry2d_20e_weighted.dta", clear


* Focus on Productivity
keep if by_var=="PEj0_ln_tfp_1"


*** Capital and Labor for each Productivity Quintile by Country-Industry, and Logs
gen rrev_c_2d=FV17_rrev_mn*FV17_rrev_sw
gen rk_c_2d=FV14_rk_mn*FV14_rk_sw
gen lab_c_2d=LV21_l_mn*LV21_l_sw
gen ln_rrev_c_2d=log(rrev_c_2d)
gen ln_rk_c_2d=log(rk_c_2d)
gen ln_lab_c_2d=log(lab_c_2d)


*** Production Frontier for Real Revenue
* For each Productivity Quintile at Country-Industry Level 
sort country industry2d by_var_value year
rename by_var_value quintile
egen country_2d=group(country industry2d)
levelsof country_2d, local(levels)
foreach c of local levels {
	levelsof quintile, local(id_quintile)
	foreach dc of local id_quintile {
		preserve
		keep if country_2d==`c' & quintile==`dc'
		capture: frontier ln_rrev_c_2d ln_rk_c_2d ln_lab_c_2d, iter(80) 
		capture: predict yhat if e(ic)<80          // Frontier.
		capture: predict uhat if e(ic)<80, u       // Technical inefficiency.
		                                           // If e(ic)=50, it means that 
												   // regression did not converge.
		capture: gen neg_uhat=-uhat       		   // [-∞,0] with max is zero.
		capture: gen exp_nuhat=exp(neg_uhat)   	   // [0, 1] with max is one.
		capture: gen g_exp_nuhat=exp(neg_uhat)-1   // [-1,0] with max is zero.
		capture: save frontier_`c'_`dc'.dta, replace 
		restore
	}
}


*** Save Empty Data to be Appended Later
clear 
gen country=" "
gen industry2d=.
gen quintile=.
gen year=.
gen ln_rrev_c_2d=. 
gen ln_rk_c_2d=.
gen ln_lab_c_2d=.
gen yhat=.
gen uhat=.
gen exp_nuhat=.
gen neg_uhat=.
gen g_exp_nuhat=.
save frontier_data.dta, replace


*** Data on Frontier by Country-Industry-quintile
use "frontier_data.dta", clear
foreach c of local levels {
	foreach dc of local id_quintile {
	append using frontier_`c'_`dc'.dta
	erase frontier_`c'_`dc'.dta
	}
}
save frontier_data.dta, replace


*** Country-Level Inflation
use "deflator_all1.dta", clear
sort country industry2d year
bysort country industry2d: gen inflation=(defl_out_[_n]-defl_out_[_n-1])/defl_out_[_n-1]
bysort country industry2d: gen lag_inflation=inflation[_n-1]
bysort country year: egen inflation_country=mean(inflation)
bysort country year: egen lag_inflation_country=mean(lag_inflation)
keep country industry2d year inflation lag_inflation inflation_country lag_inflation_country
save "deflator_all2.dta", replace


*** Open Data Again
* CompNet Data, Joint Distribution
use "jd_inp_prod_industry2d_20e_weighted.dta", clear


* Focus on Productivity
keep if by_var=="PEj0_ln_tfp_1"


*** Aggregation for each Productivity Quintile at Country-Industry Level
* Labor Costs
gen rwage_c_2d=LV24_rwage_mn
* Real Revenue 
gen rrev_c_2d=FV17_rrev_mn*FV17_rrev_sw
sort country industry2d by_var_value year


*** Merge data
rename by_var_value quintile
merge 1:1 country industry2d quintile year using "frontier_data.dta"
drop _merge


*** Output Gap over Quintiles
gen rrev_c_2d_hat = exp(yhat)
gen output_gap_logs = ln_rrev_c_2d/yhat
gen output_gap_levels = rrev_c_2d/rrev_c_2d_hat
gen output_gap_logdiff = ln_rrev_c_2d-yhat


*** Growth Rates
* Real Revenue
sort country industry2d quintile year
bysort country industry2d quintile: gen rrev_c_2d_growth=(rrev_c_2d[_n]-rrev_c_2d[_n-1])/rrev_c_2d[_n-1] 
* Labor Costs
bysort country industry2d quintile: gen rwage_c_2d_growth=(rwage_c_2d[_n]-rwage_c_2d[_n-1])/rwage_c_2d[_n-1]


*** Keep Variables of Interest
//keep country year by_var quintile industry2d rwage_c_2d - rwage_c_2d_growth
encode country, gen(cnt)
sort country industry2d quintile year
bysort country industry2d quintile: gen lag_rwage_c_2d_growth=rwage_c_2d_growth[_n-1]
bysort country industry2d quintile: gen lag_rrev_c_2d_growth=rrev_c_2d_growth[_n-1]
gen labor_market_power=CE33_markdown_l_1_mn


*** Merge Inflation Data
merge m:1 country industry2d year using "deflator_all2.dta"
drop if _merge==2
drop _merge
sort country industry2d quintile year
}


***** Regressions 
{							
*** Table 2 
sort country industry2d quintile year
egen c2d=group(country industry2d quintile)
xtset c2d year
egen ci=group(country industry2d)
xtreg rwage_c_2d_growth output_gap_logdiff lag_rwage_c_2d_growth i.year, fe cluster(ci)
outreg2 using "regressions_c2d.xls", replace keep(output_gap_logdiff lag_rwage_c_2d_growth) ctitle(Real Wage Growth) alpha(0.01, 0.05, 0.10, 0.15) symbol(***, **, *, +) 
xtreg rwage_c_2d_growth output_gap_logdiff lag_rwage_c_2d_growth lag_inflation_country i.year, fe cluster(ci)
outreg2 using "regressions_c2d.xls", append keep(output_gap_logdiff lag_rwage_c_2d_growth lag_inflation_country) ctitle(Real Wage Growth) alpha(0.01, 0.05, 0.10, 0.15) symbol(***, **, *, +) 
}

***** Graphs
{
*** Figure 8 (a)
xtreg rwage_c_2d_growth output_gap_logdiff lag_rwage_c_2d_growth lag_inflation_country labor_market_power i.year if quintile==20, fe cluster(ci)
estimates store A
outreg2 using "regressions_q_c2d.xls", replace keep(output_gap_logdiff lag_rwage_c_2d_growth lag_inflation_country) ctitle(Q1) alpha(0.01, 0.05, 0.10, 0.15) symbol(***, **, *, +) 
xtreg rwage_c_2d_growth output_gap_logdiff lag_rwage_c_2d_growth lag_inflation_country labor_market_power i.year if quintile==40, fe cluster(ci)
estimates store B
outreg2 using "regressions_q_c2d.xls", append keep(output_gap_logdiff lag_rwage_c_2d_growth lag_inflation_country) ctitle(Q2) alpha(0.01, 0.05, 0.10, 0.15) symbol(***, **, *, +) 
xtreg rwage_c_2d_growth output_gap_logdiff lag_rwage_c_2d_growth lag_inflation_country labor_market_power i.year if quintile==60, fe cluster(ci)
estimates store C
outreg2 using "regressions_q_c2d.xls", append keep(output_gap_logdiff lag_rwage_c_2d_growth lag_inflation_country) ctitle(Q3) alpha(0.01, 0.05, 0.10, 0.15) symbol(***, **, *, +) 
xtreg rwage_c_2d_growth output_gap_logdiff lag_rwage_c_2d_growth lag_inflation_country labor_market_power i.year if quintile==80, fe cluster(ci)
estimates store D
outreg2 using "regressions_q_c2d.xls", append keep(output_gap_logdiff lag_rwage_c_2d_growth lag_inflation_country) ctitle(Q4) alpha(0.01, 0.05, 0.10, 0.15) symbol(***, **, *, +) 
xtreg rwage_c_2d_growth output_gap_logdiff lag_rwage_c_2d_growth lag_inflation_country labor_market_power i.year if quintile==100, fe cluster(ci)
estimates store E
outreg2 using "regressions_q_c2d.xls", append keep(output_gap_logdiff lag_rwage_c_2d_growth lag_inflation_country) ctitle(Q5) alpha(0.01, 0.05, 0.10, 0.15) symbol(***, **, *, +) 
coefplot A B C D E, keep(output_gap_logdiff) vertical ci(90) scheme(s2color) graphregion(color(white)) ytitle("Coefficients of Output Gap by Quintile") 

*** Figure 8 (b)
bysort country industry2d year: egen count_quintile=count(quintile)
bysort country industry2d year: egen rrev_aggr_c2d=total(rrev_c_2d) if count_quintile==5
gen market_share=rrev_c_2d/rrev_aggr_c2d
sort country industry2d quintile year
bysort country industry2d quintile: gen mk_growth=(market_share[_n]-market_share[_n-1])/market_share[_n-1]
preserve
keep country year by_var quintile industry2d rrev_aggr_c2d
duplicates drop country industry2d year, force
sort country industry2d year
egen c2d=group(country industry2d)
xtset c2d year
gen total_sales_growth=.
bysort country industry2d: replace total_sales_growth=1 if rrev_aggr_c2d[_n]>rrev_aggr_c2d[_n-1] 
bysort country industry2d: replace total_sales_growth=0 if rrev_aggr_c2d[_n]<rrev_aggr_c2d[_n-1] & rrev_aggr_c2d[_n-1] !=.
sort country industry2d year
drop rrev_aggr_c2d c2d
save "dummy_total_sales_growth.dta", replace
restore
merge m:1 country industry year using "dummy_total_sales_growth.dta"
drop _merge
forvalues i=20(20)100 {
gen q_`i'=0
replace q_`i'=1 if quintile==`i'
gen sg_d_`i'=total_sales_growth*q_`i'
}
xtreg rrev_c_2d_growth total_sales_growth sg_d_40 sg_d_60 sg_d_80 sg_d_100 i.year i.quintile, fe cluster(ci)
coefplot, keep(sg_d_*) vertical ci(90) ylabel(, angle(0)) xlabel(, angle(0)) graphregion(color(white)) ytitle("Coefficients of Interaction between Aggregate Production Growth and Quintile Dummies", size(vsmall)) 
}
