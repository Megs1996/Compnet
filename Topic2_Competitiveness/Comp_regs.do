clear all
cap restore
cap log close
set more off

global main_dr "C:\Users\Marco\Desktop\CompNet 2023" // Set the main directory here
global data_dr "9th Vintage" // Set the input data directory here
global sub_dr "Competitiveness" // Set the sub-directory here

cd "$main_dr"

use "$data_dr\jd_inp_industry2d_20e_weighted.dta", clear // We use industry-level Joint Distributions to revert
// the share of the top 10 revenue firms on revenues
keep if by_var=="FD04_t10_rev_2D"
gen n=1
bys country year industry2d: egen N=sum(n)
drop if N!=2 // This drops country-industry observations that do not have both categories (in the top 10 and not)
drop n N

gen FV17_rrev_tot=FV17_rrev_mn*FV17_rrev_sw // Compute total revenues (multiplying by sum of weights because we are using weighted data)
bys country industry2d year: egen FV17_rrev_sum=sum(FV17_rrev_tot) // Total revenues at the country-industry level
gen FV17_rrev_share=FV17_rrev_tot/FV17_rrev_sum // Share of each category (in the top 10 and not) on total country-industry revenues
keep if by_var_value==1 // Keep only the top 10 share
keep country year industry2d FV17_rrev_share
rename FV17_rrev_share top10_share

sort country year industry2d

save "$sub_dr\Top10_share.dta", replace


use "$data_dr\unconditional_industry2d_20e_weighted.dta", clear // Use the unconditional dataset for measures of markup, markdown, and HHIs

keep country year industry2d CV07_hhi_rev_pop_2D_tot CE45_markup_1_mn CE33_markdown_l_1_mn PV06_lprod_rev_mn FR30_rk_l_mn FR38_invest_rev_mn FR40_ener_costs_mn FR41_ener_rev_mn
sort country year industry2d

egen cntr=group(country)
egen ind=group(industry2d)

levelsof cntr, local(cntr)
levelsof ind, local(ind)

// Construct country-industry dummies
foreach c in `cntr' {
	foreach i in `ind'{
		gen d_`c'_`i'=0
		replace d_`c'_`i'=1 if cntr==`c' & ind==`i'
	}
}

// Construct year dummies
tabulate year, gen(d_)


// Construct a dummy for year-country-industry observations in the top quartile of the HHI distribution
gen high_hhi=0
replace high_hhi=1 if CV07_hhi_rev_pop_2D_tot >=0.086 // Last quartile of HHI distribution
gen high_hhi_markup= CE45_markup_1_mn*high_hhi // Interaction between markup and high-HHI dummy
gen high_hhi_markdown= CE33_markdown_l_1_mn*high_hhi // Interaction between markdown and high-HHI dummy

merge 1:1 country industry2d year using "$sub_dr\Top10_share.dta" // Adding the top 10 firms' revenue share
drop _merge

egen cntr_ind=group(country industry2d)
xtset cntr_ind year // Setting panel data

// Construct a dummy for year-country-industry observations in the top quartile of the top 10 firms' revenue share
gen high_top10=0
replace high_top10=1 if top10_share>=0.70 // Last quartile of top 10 firms' revenue share
gen high_top10_markup= CE45_markup_1_mn*high_top10 // Interaction between markup and high-top 10 share
gen high_top10_markdown= CE33_markdown_l_1_mn*high_top10 // Interaction between markdown and high-top 10 share

sort country year industry2d

// All regression at the year-country-industry level with heteroskedasticity-robust standard errors

// Regress HHI on markup, country-industry and year FE
reg CV07_hhi_rev_pop_2D_tot CE45_markup_1_mn d*, vce(robust)
outreg2 using "$sub_dr\Comp_regressions.doc", replace ctitle(1) addtext(Country x Industry FE, YES, Year FE, YES) keep(CE45_markup_1_mn) dec(4) 

// Regress HHI on markup and markdown, country-industry and year FE
reg CV07_hhi_rev_pop_2D_tot CE45_markup_1_mn CE33_markdown_l_1_mn d*, vce(robust)
outreg2 using "$sub_dr\Comp_regressions.doc", append ctitle(2) addtext(Country x Industry FE, YES, Year FE, YES) keep(CE45_markup_1_mn CE33_markdown_l_1_mn) dec(4) 

// Regress HHI on markup and markdown, their interaction with high-HHI dummies, and country-industry and year FE
reg CV07_hhi_rev_pop_2D_tot CE45_markup_1_mn CE33_markdown_l_1_mn high_hhi_markup high_hhi_markdown d*, vce(robust)
outreg2 using "$sub_dr\Comp_regressions.doc", append ctitle(3) addtext(Country x Industry FE, YES, Year FE, YES) keep(CE45_markup_1_mn CE33_markdown_l_1_mn high_hhi_markup high_hhi_markdown) dec(4) 

// Regress HHI on markup and markdown, their interaction with high-HHI dummies, labor productivity, and country-industry and year FE
reg CV07_hhi_rev_pop_2D_tot CE45_markup_1_mn high_hhi_markup CE33_markdown_l_1_mn high_hhi_markdown PV06_lprod_rev_mn d*, vce(robust)
outreg2 using "$sub_dr\Comp_regressions.doc", append ctitle(4) addtext(Country x Industry FE, YES, Year FE, YES) keep(CE45_markup_1_mn high_hhi_markup CE33_markdown_l_1_mn high_hhi_markdown PV06_lprod_rev_mn) dec(4) 

// Regress HHI on markup and markdown, their interaction with high-HHI dummies, labor productivity, capital intensity (capital/labor), and country-industry and year FE
reg CV07_hhi_rev_pop_2D_tot CE45_markup_1_mn high_hhi_markup CE33_markdown_l_1_mn high_hhi_markdown PV06_lprod_rev_mn FR30_rk_l_mn d*, vce(robust)
outreg2 using "$sub_dr\Comp_regressions.doc", append ctitle(5) addtext(Country x Industry FE, YES, Year FE, YES) keep(CE45_markup_1_mn high_hhi_markup CE33_markdown_l_1_mn high_hhi_markdown PV06_lprod_rev_mn FR30_rk_l_mn) dec(4) 

// Regress HHI on markup and markdown, their interaction with high-HHI dummies, labor productivity, capital intensity (capital/labor), lagged investment on revenues, and country-industry and year FE
reg CV07_hhi_rev_pop_2D_tot CE45_markup_1_mn high_hhi_markup CE33_markdown_l_1_mn high_hhi_markdown PV06_lprod_rev_mn FR30_rk_l_mn l.FR38_invest_rev_mn l3.FR38_invest_rev_m d*, vce(robust)
outreg2 using "$sub_dr\Comp_regressions.doc", append ctitle(6) addtext(Country x Industry FE, YES, Year FE, YES) keep(CE45_markup_1_mn high_hhi_markup CE33_markdown_l_1_mn high_hhi_markdown PV06_lprod_rev_mn FR30_rk_l_mn l.FR38_invest_rev_mn l3.FR38_invest_rev_mn) dec(4) 

// Regress HHI on markup and markdown, their interaction with high-HHI dummies, labor productivity, capital intensity (capital/labor), lagged investment on revenues, energy on revenues, and country-industry and year FE
reg CV07_hhi_rev_pop_2D_tot CE45_markup_1_mn high_hhi_markup CE33_markdown_l_1_mn high_hhi_markdown PV06_lprod_rev_mn FR30_rk_l_mn l.FR38_invest_rev_mn l3.FR38_invest_rev_mn FR41_ener_rev_mn d*, vce(robust)
outreg2 using "$sub_dr\Comp_regressions.doc", append ctitle(7) addtext(Country x Industry FE, YES, Year FE, YES) keep(CE45_markup_1_mn high_hhi_markup CE33_markdown_l_1_mn high_hhi_markdown PV06_lprod_rev_mn FR30_rk_l_mn l.FR38_invest_rev_mn l3.FR38_invest_rev_mn FR41_ener_rev_mn) dec(4) 

// Regress HHI on markup and markdown, their interaction with high-HHI dummies, labor productivity, capital intensity (capital/labor), lagged investment on revenues, energy on costs, and country-industry and year FE
reg CV07_hhi_rev_pop_2D_tot CE45_markup_1_mn high_hhi_markup CE33_markdown_l_1_mn high_hhi_markdown PV06_lprod_rev_mn FR30_rk_l_mn l.FR38_invest_rev_mn l3.FR38_invest_rev_mn FR40_ener_costs_mn d*, vce(robust)
outreg2 using "$sub_dr\Comp_regressions.doc", append ctitle(8) addtext(Country x Industry FE, YES, Year FE, YES) keep(CE45_markup_1_mn high_hhi_markup CE33_markdown_l_1_mn high_hhi_markdown PV06_lprod_rev_mn FR30_rk_l_mn l.FR38_invest_rev_mn l3.FR38_invest_rev_mn FR40_ener_costs_mn) dec(4) 

// Regress HHI on markup and markdown, their interaction with high-HHI dummies, labor productivity, capital intensity (capital/labor), lagged investment on revenues, and country-industry and year FE
reg CV07_hhi_rev_pop_2D_tot CE45_markup_1_mn high_hhi_markup CE33_markdown_l_1_mn high_hhi_markdown PV06_lprod_rev_mn FR30_rk_l_mn l.FR38_invest_rev_mn l2.FR38_invest_rev_mn l3.FR38_invest_rev_mn l4.FR38_invest_rev_mn l5.FR38_invest_rev_mn d*, vce(robust)
outreg2 using "$sub_dr\Comp_regressions.doc", append ctitle(9) addtext(Country x Industry FE, YES, Year FE, YES) keep(CE45_markup_1_mn high_hhi_markup CE33_markdown_l_1_mn high_hhi_markdown PV06_lprod_rev_mn FR30_rk_l_mn l.FR38_invest_rev_mn 2.FR38_invest_rev_mn l3.FR38_invest_rev_mn l4.FR38_invest_rev_mn l5.FR38_invest_rev_mn) dec(4)

******************************

// Regress HHI on markup, country-industry and year FE
reg CV07_hhi_rev_pop_2D_tot CE45_markup_1_mn d*, vce(robust)
outreg2 using "$sub_dr\Comp_regressions_top10e.doc", replace ctitle(1) addtext(Country x Industry FE, YES, Year FE, YES) keep(CE45_markup_1_mn) dec(4) 

// Regress HHI on markup and markdown, country-industry and year FE
reg CV07_hhi_rev_pop_2D_tot CE45_markup_1_mn CE33_markdown_l_1_mn d*, vce(robust)
outreg2 using "$sub_dr\Comp_regressions_top10e.doc", append ctitle(2) addtext(Country x Industry FE, YES, Year FE, YES) keep(CE45_markup_1_mn CE33_markdown_l_1_mn) dec(4) 

// Regress HHI on markup and markdown, their interaction with high top10 revenue share dummies, and country-industry and year FE
reg CV07_hhi_rev_pop_2D_tot CE45_markup_1_mn CE33_markdown_l_1_mn high_top10_markup high_top10_markdown d*, vce(robust)
outreg2 using "$sub_dr\Comp_regressions_top10e.doc", append ctitle(3) addtext(Country x Industry FE, YES, Year FE, YES) keep(CE45_markup_1_mn CE33_markdown_l_1_mn high_top10_markup high_top10_markdown) dec(4) 

// Regress HHI on markup and markdown, their interaction with high top10 revenue share dummies, labor productivity, and country-industry and year FE
reg CV07_hhi_rev_pop_2D_tot CE45_markup_1_mn high_top10_markup CE33_markdown_l_1_mn high_top10_markdown PV06_lprod_rev_mn d*, vce(robust)
outreg2 using "$sub_dr\Comp_regressions_top10e.doc", append ctitle(4) addtext(Country x Industry FE, YES, Year FE, YES) keep(CE45_markup_1_mn high_top10_markup CE33_markdown_l_1_mn high_top10_markdown PV06_lprod_rev_mn) dec(4) 

// Regress HHI on markup and markdown, their interaction with high top10 revenue share dummies, labor productivity, capital intensity (capital/labor), and country-industry and year FE
reg CV07_hhi_rev_pop_2D_tot CE45_markup_1_mn high_top10_markup CE33_markdown_l_1_mn high_top10_markdown PV06_lprod_rev_mn FR30_rk_l_mn d*, vce(robust)
outreg2 using "$sub_dr\Comp_regressions_top10e.doc", append ctitle(5) addtext(Country x Industry FE, YES, Year FE, YES) keep(CE45_markup_1_mn high_top10_markup CE33_markdown_l_1_mn high_top10_markdown PV06_lprod_rev_mn FR30_rk_l_mn) dec(4) 

sort cntr_ind year

// Regress HHI on markup and markdown, their interaction with high top10 revenue share dummies, labor productivity, capital intensity (capital/labor), lagged investment on revenues, and country-industry and year FE
reg CV07_hhi_rev_pop_2D_tot CE45_markup_1_mn high_top10_markup CE33_markdown_l_1_mn high_top10_markdown PV06_lprod_rev_mn FR30_rk_l_mn l.FR38_invest_rev_mn l3.FR38_invest_rev_m d*, vce(robust)
outreg2 using "$sub_dr\Comp_regressions_top10e.doc", append ctitle(6) addtext(Country x Industry FE, YES, Year FE, YES) keep(CE45_markup_1_mn high_top10_markup CE33_markdown_l_1_mn high_top10_markdown PV06_lprod_rev_mn FR30_rk_l_mn l.FR38_invest_rev_mn l3.FR38_invest_rev_mn) dec(4) 

// Regress HHI on markup and markdown, their interaction with high top10 revenue share dummies, labor productivity, capital intensity (capital/labor), lagged investment on revenues, energy on revenues, and country-industry and year FE
reg CV07_hhi_rev_pop_2D_tot CE45_markup_1_mn high_top10_markup CE33_markdown_l_1_mn high_top10_markdown PV06_lprod_rev_mn FR30_rk_l_mn l.FR38_invest_rev_mn l3.FR38_invest_rev_mn FR41_ener_rev_mn d*, vce(robust)
outreg2 using "$sub_dr\Comp_regressions_top10e.doc", append ctitle(7) addtext(Country x Industry FE, YES, Year FE, YES) keep(CE45_markup_1_mn high_top10_markup CE33_markdown_l_1_mn high_top10_markdown PV06_lprod_rev_mn FR30_rk_l_mn l.FR38_invest_rev_mn l3.FR38_invest_rev_mn FR41_ener_rev_mn) dec(4) 

// Regress HHI on markup and markdown, their interaction with high top10 revenue share dummies, labor productivity, capital intensity (capital/labor), lagged investment on revenues, energy on costs, and country-industry and year FE
reg CV07_hhi_rev_pop_2D_tot CE45_markup_1_mn high_top10_markup CE33_markdown_l_1_mn high_top10_markdown PV06_lprod_rev_mn FR30_rk_l_mn l.FR38_invest_rev_mn l3.FR38_invest_rev_mn FR40_ener_costs_mn d*, vce(robust)
outreg2 using "$sub_dr\Comp_regressions_top10e.doc", append ctitle(8) addtext(Country x Industry FE, YES, Year FE, YES) keep(CE45_markup_1_mn high_top10_markup CE33_markdown_l_1_mn high_top10_markdown PV06_lprod_rev_mn FR30_rk_l_mn l.FR38_invest_rev_mn l3.FR38_invest_rev_mn FR40_ener_costs_mn) dec(4) 

// Regress HHI on markup and markdown, their interaction with high top10 revenue share dummies, labor productivity, capital intensity (capital/labor), lagged investment on revenues, and country-industry and year FE
reg CV07_hhi_rev_pop_2D_tot CE45_markup_1_mn high_top10_markup CE33_markdown_l_1_mn high_top10_markdown PV06_lprod_rev_mn FR30_rk_l_mn l.FR38_invest_rev_mn l2.FR38_invest_rev_mn l3.FR38_invest_rev_mn l4.FR38_invest_rev_mn l5.FR38_invest_rev_mn d*, vce(robust)
outreg2 using "$sub_dr\Comp_regressions_top10e.doc", append ctitle(9) addtext(Country x Industry FE, YES, Year FE, YES) keep(CE45_markup_1_mn high_top10_markup CE33_markdown_l_1_mn high_top10_markdown PV06_lprod_rev_mn FR30_rk_l_mn l.FR38_invest_rev_mn 2.FR38_invest_rev_mn l3.FR38_invest_rev_mn l4.FR38_invest_rev_mn l5.FR38_invest_rev_mn) dec(4)  


******************************

// Regress top 10 firms' revenue share on markup, country-industry and year FE
reg top10_share CE45_markup_1_mn d*, vce(robust)
outreg2 using "$sub_dr\Comp_regressions_top10dep.doc", replace ctitle(1) addtext(Country x Industry FE, YES, Year FE, YES) keep(CE45_markup_1_mn) dec(4) 

// Regress top 10 firms' revenue share on markup and markdown, country-industry and year FE
reg top10_share CE45_markup_1_mn CE33_markdown_l_1_mn d*, vce(robust)
outreg2 using "$sub_dr\Comp_regressions_top10dep.doc", append ctitle(2) addtext(Country x Industry FE, YES, Year FE, YES) keep(CE45_markup_1_mn CE33_markdown_l_1_mn) dec(4) 

// Regress HHI on markup and markdown, their interaction with high top10 revenue share dummies, and country-industry and year FE
reg top10_share CE45_markup_1_mn CE33_markdown_l_1_mn high_top10_markup high_top10_markdown d*, vce(robust)
outreg2 using "$sub_dr\Comp_regressions_top10dep.doc", append ctitle(3) addtext(Country x Industry FE, YES, Year FE, YES) keep(CE45_markup_1_mn CE33_markdown_l_1_mn high_top10_markup high_top10_markdown) dec(4) 

// Regress top 10 firms' revenue share on markup and markdown, their interaction with high top10 revenue share dummies, labor productivity, and country-industry and year FE
reg top10_share CE45_markup_1_mn high_top10_markup CE33_markdown_l_1_mn high_top10_markdown PV06_lprod_rev_mn d*, vce(robust)
outreg2 using "$sub_dr\Comp_regressions_top10dep.doc", append ctitle(4) addtext(Country x Industry FE, YES, Year FE, YES) keep(CE45_markup_1_mn high_top10_markup CE33_markdown_l_1_mn high_top10_markdown PV06_lprod_rev_mn) dec(4) 

// Regress top 10 firms' revenue share on markup and markdown, their interaction with high top10 revenue share dummies, labor productivity, capital intensity (capital/labor), and country-industry and year FE
reg top10_share CE45_markup_1_mn high_top10_markup CE33_markdown_l_1_mn high_top10_markdown PV06_lprod_rev_mn FR30_rk_l_mn d*, vce(robust)
outreg2 using "$sub_dr\Comp_regressions_top10dep.doc", append ctitle(5) addtext(Country x Industry FE, YES, Year FE, YES) keep(CE45_markup_1_mn high_top10_markup CE33_markdown_l_1_mn high_top10_markdown PV06_lprod_rev_mn FR30_rk_l_mn) dec(4) 

sort cntr_ind year

// Regress top 10 firms' revenue share on markup and markdown, their interaction with high top10 revenue share dummies, labor productivity, capital intensity (capital/labor), lagged investment on revenues, and country-industry and year FE
reg top10_share CE45_markup_1_mn high_top10_markup CE33_markdown_l_1_mn high_top10_markdown PV06_lprod_rev_mn FR30_rk_l_mn l.FR38_invest_rev_mn l3.FR38_invest_rev_m d*, vce(robust)
outreg2 using "$sub_dr\Comp_regressions_top10dep.doc", append ctitle(6) addtext(Country x Industry FE, YES, Year FE, YES) keep(CE45_markup_1_mn high_top10_markup CE33_markdown_l_1_mn high_top10_markdown PV06_lprod_rev_mn FR30_rk_l_mn l.FR38_invest_rev_mn l3.FR38_invest_rev_mn) dec(4) 

// Regress top 10 firms' revenue share on markup and markdown, their interaction with high top10 revenue share dummies, labor productivity, capital intensity (capital/labor), lagged investment on revenues, energy on revenues, and country-industry and year FE
reg top10_share CE45_markup_1_mn high_top10_markup CE33_markdown_l_1_mn high_top10_markdown PV06_lprod_rev_mn FR30_rk_l_mn l.FR38_invest_rev_mn l3.FR38_invest_rev_mn FR41_ener_rev_mn d*, vce(robust)
outreg2 using "$sub_dr\Comp_regressions_top10dep.doc", append ctitle(7) addtext(Country x Industry FE, YES, Year FE, YES) keep(CE45_markup_1_mn high_top10_markup CE33_markdown_l_1_mn high_top10_markdown PV06_lprod_rev_mn FR30_rk_l_mn l.FR38_invest_rev_mn l3.FR38_invest_rev_mn FR41_ener_rev_mn) dec(4) 

// Regress top 10 firms' revenue share on markup and markdown, their interaction with high top10 revenue share dummies, labor productivity, capital intensity (capital/labor), lagged investment on revenues, energy on costs, and country-industry and year FE
reg top10_share CE45_markup_1_mn high_top10_markup CE33_markdown_l_1_mn high_top10_markdown PV06_lprod_rev_mn FR30_rk_l_mn l.FR38_invest_rev_mn l3.FR38_invest_rev_mn FR40_ener_costs_mn d*, vce(robust)
outreg2 using "$sub_dr\Comp_regressions_top10dep.doc", append ctitle(8) addtext(Country x Industry FE, YES, Year FE, YES) keep(CE45_markup_1_mn high_top10_markup CE33_markdown_l_1_mn high_top10_markdown PV06_lprod_rev_mn FR30_rk_l_mn l.FR38_invest_rev_mn l3.FR38_invest_rev_mn FR40_ener_costs_mn) dec(4) 

// Regress top 10 firms' revenue share on markup and markdown, their interaction with high top10 revenue share dummies, labor productivity, capital intensity (capital/labor), lagged investment on revenues, and country-industry and year FE
reg top10_share CE45_markup_1_mn high_top10_markup CE33_markdown_l_1_mn high_top10_markdown PV06_lprod_rev_mn FR30_rk_l_mn l.FR38_invest_rev_mn l2.FR38_invest_rev_mn l3.FR38_invest_rev_mn l4.FR38_invest_rev_mn l5.FR38_invest_rev_mn d*, vce(robust)
outreg2 using "$sub_dr\Comp_regressions_top10dep.doc", append ctitle(9) addtext(Country x Industry FE, YES, Year FE, YES) keep(CE45_markup_1_mn high_top10_markup CE33_markdown_l_1_mn high_top10_markdown PV06_lprod_rev_mn FR30_rk_l_mn l.FR38_invest_rev_mn 2.FR38_invest_rev_mn l3.FR38_invest_rev_mn l4.FR38_invest_rev_mn l5.FR38_invest_rev_mn) dec(4)  


********************
****** EXPORT ******
********************

use "$data_dr\unconditional_industry2d_20e_weighted.dta", clear // Use the unconditional dataset at the year-country-industry level
keep country year industry2d TV03_exp_adj_mn TV09_imp_adj_mn TV03_exp_adj_sw TV09_imp_adj_sw CV07_hhi_rev_pop_2D_tot CE45_markup_1_mn CE33_markdown_l_1_mn FR40_ener_costs_mn FV08_nrev_mn FV08_nrev_sw LV21_l_mn LV21_l_sw FV04_nk_mn FV04_nk_sw // Keep variables of interest
sort country year industry2d

gen TV03_exp_adj_tot=TV03_exp_adj_mn*TV03_exp_adj_sw // Compute total exports (multiplying by the sum of weights since we are using weighted data)
gen TV09_imp_adj_tot=TV09_imp_adj_mn*TV09_imp_adj_sw // Compute total imports
gen FV08_nrev_tot=FV08_nrev_mn*FV08_nrev_sw // Compute total revenues
gen LV21_l_tot=LV21_l_mn*LV21_l_sw // Compute total labor
gen FV04_nk_tot=FV04_nk_mn*FV04_nk_sw // Compute total capital

gen lprod=FV08_nrev_tot/LV21_l_tot // Compute labor productivity at the country-industry level
gen capint=FV04_nk_tot/LV21_l_tot // Compute capital intensity at the country-industry level
gen TV03_exp_adj_share=TV03_exp_adj_tot/FV08_nrev_tot // Compute export share on revenues at the country-industry level
gen TV09_imp_adj_share=TV09_imp_adj_tot/FV08_nrev_tot // Compute import share on revenues at the country-industry level

merge 1:1 country industry2d year using "$sub_dr\Top10_share.dta" // Adding the top 10 firms' revenue share
drop _merge

egen cntr=group(country)
egen ind=group(industry2d)

levelsof cntr, local(cntr)
levelsof ind, local(ind)

// Construct country-industry dummies
foreach c in `cntr' {
	foreach i in `ind'{
		gen d_`c'_`i'=0
		replace d_`c'_`i'=1 if cntr==`c' & ind==`i'
	}
}

// Construct year dummies
tabulate year, gen(d_)


// Construct a dummy for year-country-industry observations in the top quartile of energy cost
gen high_enerc=0
replace high_enerc=1 if FR40_ener_costs_mn>=0.034 // 75th pct of energy cost
gen high_enerc_exp=high_enerc*TV03_exp_adj_share // Interaction between export revenue share and high-energy cost dummy
gen high_enerc_imp=high_enerc*TV09_imp_adj_share // Interaction between import revenue share and high-energy cost dummy

// Construct a dummy for year-country-industry observations in the top quartile of labor productivity
gen high_lprod=0
replace high_lprod=1 if lprod>=229 // 75th pct of labor productivity
gen high_lprod_exp=high_lprod*TV03_exp_adj_share // Interaction between export revenue share and high-labor productivity dummy
gen high_lprod_imp=high_lprod*TV09_imp_adj_share // Interaction between import revenue share and high-labor productivity dummy

// Construct a dummy for year-country-industry observations in the top quartile of capital intensity
gen high_capint=0
replace high_capint=1 if capint>=64 // 75th pct of capital intensity
gen high_capint_exp=high_capint*TV03_exp_adj_share // Interaction between export revenue share and high-capital intensity dummy
gen high_capint_imp=high_capint*TV09_imp_adj_share // Interaction between import revenue share and high-capital intensity dummy

// All regressions are with country-industry and year FE, and with heteroskedasticity-robust standard errors

// Regress HHI on export and import shares on revenues
reg CV07_hhi_rev_pop_2D_tot TV03_exp_adj_share TV09_imp_adj_share d_*, vce(robust)
outreg2 using "$sub_dr\Comptrade_regressions.doc", replace ctitle(HHI) addtext(Country x Industry FE, YES, Year FE, YES) keep(TV03_exp_adj_share TV09_imp_adj_share) dec(4) 
 
// Regress markup on export and import shares on revenues
reg CE45_markup_1_mn TV03_exp_adj_share TV09_imp_adj_share d_*, vce(robust)
outreg2 using "$sub_dr\Comptrade_regressions.doc", append ctitle(Markup) addtext(Country x Industry FE, YES, Year FE, YES) keep(TV03_exp_adj_share TV09_imp_adj_share) dec(4) 

// Regress markdown on export and import shares on revenues
reg CE33_markdown_l_1_mn TV03_exp_adj_share TV09_imp_adj_share d_*, vce(robust)
outreg2 using "$sub_dr\Comptrade_regressions.doc", append ctitle(Markdown) addtext(Country x Industry FE, YES, Year FE, YES) keep(TV03_exp_adj_share TV09_imp_adj_share) dec(4) 

// Regress top 10 firms' revenue share on export and import shares on revenues
reg top10_share TV03_exp_adj_share TV09_imp_adj_share d_*, vce(robust)
outreg2 using "$sub_dr\Comptrade_regressions.doc", append ctitle(Top 10 share) addtext(Country x Industry FE, YES, Year FE, YES) keep(TV03_exp_adj_share TV09_imp_adj_share) dec(4) 

// Regress HHI on export and import shares on revenues and their interactions with dummies for high energy costs, high labor productivity, and high capital intensity
reg CV07_hhi_rev_pop_2D_tot TV03_exp_adj_share TV09_imp_adj_share high_enerc_exp high_enerc_imp high_lprod_exp high_lprod_imp high_capint_exp high_capint_imp d_*, vce(robust)
outreg2 using "$sub_dr\Comptrade_regressions.doc", append ctitle(HHI) addtext(Country x Industry FE, YES, Year FE, YES) keep(TV03_exp_adj_share TV09_imp_adj_share high_enerc_exp high_enerc_imp high_lprod_exp high_lprod_imp high_capint_exp high_capint_imp) dec(4) 

// Regress markup on export and import shares on revenues and their interactions with dummies for high energy costs, high labor productivity, and high capital intensity
reg CE45_markup_1_mn TV03_exp_adj_share TV09_imp_adj_share high_enerc_exp high_enerc_imp high_lprod_exp high_lprod_imp high_capint_exp high_capint_imp d_*, vce(robust)
outreg2 using "$sub_dr\Comptrade_regressions.doc", append ctitle(Markup) addtext(Country x Industry FE, YES, Year FE, YES) keep(TV03_exp_adj_share TV09_imp_adj_share high_enerc_exp high_enerc_imp high_lprod_exp high_lprod_imp high_capint_exp high_capint_imp) dec(4) 

// Regress markdown on export and import shares on revenues and their interactions with dummies for high energy costs, high labor productivity, and high capital intensity
reg CE33_markdown_l_1_mn TV03_exp_adj_share TV09_imp_adj_share high_enerc_exp high_enerc_imp high_lprod_exp high_lprod_imp high_capint_exp high_capint_imp d_*, vce(robust)
outreg2 using "$sub_dr\Comptrade_regressions.doc", append ctitle(Markdown) addtext(Country x Industry FE, YES, Year FE, YES) keep(TV03_exp_adj_share TV09_imp_adj_share high_enerc_exp high_enerc_imp high_lprod_exp high_lprod_imp high_capint_exp high_capint_imp) dec(4) 

// Regress top 10 firms' revenue share on export and import shares on revenues and their interactions with dummies for high energy costs, high labor productivity, and high capital intensity
reg top10_share TV03_exp_adj_share TV09_imp_adj_share high_enerc_exp high_enerc_imp high_lprod_exp high_lprod_imp high_capint_exp high_capint_imp d_*, vce(robust)
outreg2 using "$sub_dr\Comptrade_regressions.doc", append ctitle(Top 10 share) addtext(Country x Industry FE, YES, Year FE, YES) keep(TV03_exp_adj_share TV09_imp_adj_share high_enerc_exp high_enerc_imp high_lprod_exp high_lprod_imp high_capint_exp high_capint_imp) dec(4) 
