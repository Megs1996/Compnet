set more off
clear all

global main_dr "C:\Users\Marco\Desktop\CompNet 2023" // Set the main directory here
global data_dr "9th Vintage" // Set the input data directory here
global sub_dr "Ulc_Wage_Tfp" // Set the sub-directory here

*** This code produces the chart on ULC in Germany and Poland in Section 3

cd "$main_dr"

capture noisily mkdir "$sub_dr"
capture noisily mkdir "$sub_dr\Trends"

set more off
//set maxvar 15000


*----------------------------------*
*        VARs TRENDS       *
*----------------------------------*

*{
eststo clear 

use "$data_dr\jd_inp_prod_country_20e_weighted.dta", clear
keep if by_var=="PV03_lnlprod_va"

keep if by_var_value==10 | by_var_value==100

keep country year by_var_value /*LR01_lc_va_mn*/ LV24_rwage_p50 /*PEj0_ln_tfp_1_mn*/ PV03_lnlprod_va_p50
*rename PV07_lprod_va_mn PV07_lp_mn

rename LV24_rwage_p50 LV24_rwage_p50_
rename PV03_lnlprod_va_p50 PV03_lnlprod_va_p50_

reshape wide LV24_rwage_p50 PV03_lnlprod_va_p50, i(country year) j(by_var_value)

save "$main_dr\\$sub_dr\conditional_data.dta", replace




use "$data_dr\unconditional_country_20e_weighted.dta", clear

keep country year /*LR01_lc_va_p50 LV24_rwage_p50 PEj0_ln_tfp_1_p50 PV03_lnlprod_va_p50*/ LR03_ulc_p50
*rename PV07_lprod_va_mn PV07_lp_mn

*encode country, gen(cn)

merge 1:1 country year using "$main_dr\\$sub_dr\conditional_data.dta"
drop _merge

keep if year>=2008 & year<=2020
bys country: egen fy=min(year)

foreach v in LR03_ulc_p50 LV24_rwage_p50_10 PV03_lnlprod_va_p50_10 LV24_rwage_p50_100 PV03_lnlprod_va_p50_100 {
	gen base_l_`v'=`v' if year == fy
	bys country: egen base_`v'=mean(base_l_`v')
	gen ind_`v'=`v'/base_`v'
}

replace country="CzechRepublic" if country=="Czech Republic"

capture noisily mkdir "$main_dr\\$sub_dr\\By_country"

twoway (bar ind_LR03_ulc_p50 year if country=="France", color(edkblue) barwidth(0.2)) (line ind_LV24_rwage_p50_100 year if country=="France", lcolor(cranberry) lwidth(medthick)) (line ind_LV24_rwage_p50_10 year if country=="France", lcolor(cranberry) lpattern(dash_dot) lwidth(medthick)) (line ind_PV03_lnlprod_va_p50_100 year if country=="France", lcolor(dkgreen) lwidth(medthick)) (line ind_PV03_lnlprod_va_p50_10 year if country=="France", lcolor(dkgreen) lpattern(dash_dot) lwidth(medthick)), graphr(color(white)) plotr(color(white)) xlabel(2008(6)2020, labsize(3)) legend(on label(1 ULC) label(2 "Real Wage - Top productive firms") label(3 "Real Wage - Least productive firms") label(4 "Labor Productivity VA - Top productive firms") label(5 "Labor Productivity VA - Least productive firms") cols(2) size(vsmall) region(lwidth(none))) yla(0.6(0.4)1.4) ytitle("") xtitle("") title("France", color(black)) name(ch_France1)

levelsof country, local(countries)
foreach c of local countries {
	display "`c'"
	twoway (bar ind_LR03_ulc_p50 year if country=="`c'", color(edkblue) barwidth(0.8)) (line ind_LV24_rwage_p50_100 year if country=="`c'", lcolor(cranberry) lpattern(solid) lwidth(medthick)) (line ind_LV24_rwage_p50_10 year if country=="`c'", lcolor(cranberry) lpattern(dash_dot) lwidth(medthick)) (line ind_PV03_lnlprod_va_p50_100 year if country=="`c'", lcolor(dkgreen) lpattern(solid) lwidth(medthick)) (line ind_PV03_lnlprod_va_p50_10 year if country=="`c'", lcolor(dkgreen) lpattern(dash_dot) lwidth(medthick)), graphr(color(white)) plotr(color(white)) xlabel(2008(6)2020, labsize(3)) legend(on label(1 ULC) label(2 "Real Wage - Top productive") label(3 "Real Wage - Least productive") label(4 "Labor Productivity VA - Top productive") label(5 "Labor Productivity VA - Least productive") cols(2) size(small) region(lwidth(none))) yla(0.6(0.4)1.4) ytitle("") xtitle("") title("`c'", color(black)) name(ch_`c')
graph export "$main_dr\\$sub_dr\\By_country\Chart_`c'.pdf", replace

}

grc1leg ch_France ch_Germany ch_Italy ch_Netherlands ch_Poland ch_Spain, rows(1) graphregion(color(white)) position(12)
graph export "$main_dr\\$sub_dr\\By_country\Chart_big6.pdf", as(pdf) replace

grc1leg ch_Germany ch_Spain, rows(1) graphregion(color(white)) position(12)
graph export "$main_dr\\$sub_dr\\By_country\Chart_DE_ES.pdf", as(pdf) replace

grc1leg ch_Germany ch_Poland, rows(1) graphregion(color(white)) position(12)
graph export "$main_dr\\$sub_dr\\By_country\Chart_DE_PO.pdf", as(pdf) replace

