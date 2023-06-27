// This do file identifies the top and bottom country-industry observations by share of export, import, and total trade (=export+import) on revenues (shares being averaged over years)
use "C:\Users\Marco\Desktop\CompNet 2023\9th Vintage\unconditional_industry2d_20e_weighted.dta", clear

keep country industry2d year TV03_exp_adj_mn TV03_exp_adj_sw TV09_imp_adj_mn TV09_imp_adj_sw FV08_nrev_mn FV08_nrev_sw CV07_hhi_rev_pop_2D_tot

gen TV03_exp_adj_tot=TV03_exp_adj_mn*TV03_exp_adj_sw // Compute total exports (multiplying by the sum of weights since we are using weighted data)
gen TV09_imp_adj_tot=TV09_imp_adj_mn*TV09_imp_adj_sw // Compute total imports
gen FV08_nrev_tot=FV08_nrev_mn*FV08_nrev_sw // Compute total revenues
gen tot_trade=TV03_exp_adj_tot+TV09_imp_adj_tot // Compute total trade = total export + total import
replace CV07_hhi_rev_pop_2D_tot=CV07_hhi_rev_pop_2D_tot*100 // HHIs should be multiplied by 100

gen exp_share=(TV03_exp_adj_tot/FV08_nrev_tot)*100 // Compute export share on revenues at the country-industry level
gen imp_share=(TV09_imp_adj_tot/FV08_nrev_tot)*100 // Compute import share on revenues at the country-industry level
gen trade_share=(tot_trade/FV08_nrev_tot)*100 // Compute total trade share on revenues at the country-industry level

keep if year >=2015 & year<=2020
gen cov=0
replace cov=1 if year==2020 // Isolate COVID-19 year
collapse (mean) *_share CV07_hhi_rev_pop_2D_tot, by(country industry2d cov) // Average 2015-2019
reshape wide *_share CV07_hhi_rev_pop_2D_tot, i(country industry2d) j(cov) // Make different variables for each group of years (2015-2019 vs 2020)

keep country industry2d exp_share* CV07_hhi_rev_pop_2D_tot*

format %6.4gc exp_share0
format %6.4gc exp_share1
format %6.4gc CV07_hhi_rev_pop_2D_tot0
format %6.4gc CV07_hhi_rev_pop_2D_tot1

drop if exp_share0==. | exp_share0>=100 | exp_share1==. | exp_share1>=100 // Drop missing or unreasonable data

// Rank country-industry observations by the export share and select the top and the bottom ones, both for the 2015-2019 period and for 2020
preserve
keep country industry2d exp_share0 CV07_hhi_rev_pop_2D_tot0
sort exp_share0
keep if _n>=1 & _n<=10 | _n>=239
export excel using "C:\Users\Marco\Desktop\CompNet 2023\Competitiveness\Top_exprev.xlsx", sheet(nocov, replace) firstrow(variables)
restore

keep country industry2d exp_share1 CV07_hhi_rev_pop_2D_tot1
sort exp_share1
keep if _n>=1 & _n<=10 | _n>=239
export excel using "C:\Users\Marco\Desktop\CompNet 2023\Competitiveness\Top_exprev.xlsx", sheet(cov, replace) firstrow(variables)