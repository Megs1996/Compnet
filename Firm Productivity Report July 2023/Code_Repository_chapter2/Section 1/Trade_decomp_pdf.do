clear all
cap restore
cap log close
set more off

// The code produces charts on margin decomposition in Topic 2

global main_dr "C:\Users\Marco\Desktop\CompNet 2023" // Set the main directory here
global data_dr "9th Vintage" // Set the input data directory here

cd "$main_dr"

capture noisily mkdir "PDF_charts"

use "$data_dr\unconditional_country_20e_unweighted.dta", clear
keep country year TV02_exp_mn TV04_exp_ex_mn TV06_exp_in_mn TV08_imp_mn TV10_imp_ex_mn TV12_imp_in_mn TV02_exp_N TV04_exp_ex_N TV06_exp_in_N TV08_imp_N TV10_imp_ex_N TV12_imp_in_N

preserve
keep country year TV02_exp_*
keep if TV02_exp_mn!=.
keep if year>=2010 & year<=2020 // We obtain a balanced panel of 14 obs by restricting to these years and dropping NL
drop if country=="Netherlands"
gen TV02_exp_tot=TV02_exp_mn*TV02_exp_N
collapse (sum) TV02_exp_tot TV02_exp_N, by(year)
gen TV02_exp_mn=TV02_exp_tot/TV02_exp_N
tsset year

foreach v in tot mn N {
gen base_`v'_l=TV02_exp_`v' if year==2010
egen base_`v'=mean(base_`v'_l)
drop base_`v'_l
gen ind_`v'= (TV02_exp_`v'/base_`v')*100
gen gr_ind_`v'=((ind_`v'/l.ind_`v')-1)*100
}

keep year *ind*
*export excel using "Trade_decomp.xlsx", firstrow(varlabels) sheet (Exp, replace) // Total in chart b)

merge 1:1 year using "Enterprise Competitiveness Indicator\REER & Market Shares\Exp_wg_Reer_tot.dta"
drop _merge

gen adj_gr_ind_mn=gr_ind_mn

replace adj_gr_ind_mn=gr_ind_N+gr_ind_mn if gr_ind_N>=0 & gr_ind_mn>=0
replace adj_gr_ind_mn=gr_ind_N+gr_ind_mn if gr_ind_N<0 & gr_ind_mn<0

drop if year<2012

twoway  (bar adj_gr_ind_mn year, color(edkblue) barwidth(0.5)) (bar gr_ind_N year, color(cranberry) barwidth(0.5)) (line gr_ind_tot year, lcolor(dkgreen) lwidth(medthick) lpattern(solid)) (line wg_reer_42 year, lcolor(gold) lwidth(medthick) lpattern(dash) yaxis(2)), graphr(color(white)) plotr(color(white)) subtitle(, bcolor(white) lcolor(black)) xlabel(2012(2)2020,labsize(3)) yla(-15(5)20,labsize(3) angle(0) axis(1)) ytitle("", size(1) axis(1)) yla(98(2)108,labsize(3) angle(0) axis(2)) ytitle("", size(1) axis(2)) legend(on label(1 "Intensive") label(2 "Extensive") label(3 "Total") label(4 "REER (rhs)") size(4) cols(4) symxsize(*0.5) position(12) order(1 "Intensive" 2 "Extensive" 3 "Total" 4 "REER (rhs)") region(lwidth(none))) /*yline(0, lpattern() lcolor(grey))*/ xtitle("") title("Total", size(4) color(black)) note("") name("Margins_total")

graph export "PDF_charts\Margins_total.pdf", as(pdf) replace


restore

keep if TV04_exp_ex_mn!=. & TV06_exp_in_mn!=.
keep country year TV04_exp_ex_mn TV06_exp_in_mn TV04_exp_ex_N TV06_exp_in_N
keep if year>=2010 & year<=2020 // We obtain a balanced panel of 8 obs by restricting to these years and dropping NL and RO
drop if country=="Netherlands" | country=="Romania"

gen TV04_exp_ex_tot=TV04_exp_ex_mn*TV04_exp_ex_N
gen TV06_exp_in_tot=TV06_exp_in_mn*TV06_exp_in_N
collapse (sum) *_tot *_N, by(year)
gen TV04_exp_ex_mn=TV04_exp_ex_tot/TV04_exp_ex_N
gen TV06_exp_in_mn=TV06_exp_in_tot/TV06_exp_in_N
tsset year

foreach d in 4_exp_ex 6_exp_in {
foreach v in tot mn N {
gen base_`d'_`v'_l=TV0`d'_`v' if year==2010
egen base_`d'_`v'=mean(base_`d'_`v'_l)
drop base_`d'_`v'_l
gen ind_`d'_`v'= (TV0`d'_`v'/base_`d'_`v')*100
gen gr_ind_`d'_`v'=((ind_`d'_`v'/l.ind_`d'_`v')-1)*100
}
}

keep year *ind*
*export excel using "Trade_decomp.xlsx", firstrow(varlabels) sheet (Exp_ex_in, replace) // chart c)

drop if year<2012

gen d_ex=.
gen d_in=.

label var d_ex "Outside EU"
label var d_in "Inside EU"

merge 1:1 year using "Enterprise Competitiveness Indicator\REER & Market Shares\Exp_wg_Reer_dest.dta"
rename wg_reer_42 reer_ex
rename wg_reer_27 reer_in
drop _merge

foreach d in ex in {
	
rename gr_ind_*_`d'_tot gr_ind_`d'_tot 
rename gr_ind_*_`d'_mn gr_ind_`d'_mn 
rename gr_ind_*_`d'_N gr_ind_`d'_N 
	
gen adj_gr_ind_`d'_mn=gr_ind_`d'_mn

replace adj_gr_ind_`d'_mn=gr_ind_`d'_N+gr_ind_`d'_mn if gr_ind_`d'_N>=0 & gr_ind_`d'_mn>=0
replace adj_gr_ind_`d'_mn=gr_ind_`d'_N+gr_ind_`d'_mn if gr_ind_`d'_N<0 & gr_ind_`d'_mn<0

twoway  (bar adj_gr_ind_`d'_mn year, color(edkblue) barwidth(0.5)) (bar gr_ind_`d'_N year, color(cranberry) barwidth(0.5)) (line gr_ind_`d'_tot year, lcolor(dkgreen) lwidth(medthick) lpattern(solid)) (line reer_`d' year, lcolor(gold) lwidth(medthick) lpattern(dash) yaxis(2)), graphr(color(white)) plotr(color(white)) subtitle(, bcolor(white) lcolor(black)) xlabel(2012(2)2020,labsize(3)) yla(-15(5)20,labsize(3) angle(0) axis(1)) ytitle("", size(1) axis(1)) yla(98(2)108,labsize(3) angle(0) axis(2)) ytitle("", size(1) axis(2)) legend(on label(1 "Intensive") label(2 "Extensive") label(3 "Total") label(4 "REER (rhs)") size(4) cols(4) symxsize(*0.5) position(12) order(1 "Intensive" 2 "Extensive" 3 "Total" 4 "REER (rhs)") region(lwidth(none))) /*yline(0, lpattern() lcolor(grey))*/ xtitle("") title("`: var label d_`d''", size(4) color(black)) note("") name("Margins_dest_`d'")
graph export "PDF_charts\Margins_dest_`d'.pdf", as(pdf) replace
}


********************

use "$data_dr\unconditional_macsec_szcl_20e_unweighted.dta", clear
keep country year macsec_szcl TV02_exp_mn TV04_exp_ex_mn TV06_exp_in_mn TV08_imp_mn TV10_imp_ex_mn TV12_imp_in_mn TV02_exp_N TV04_exp_ex_N TV06_exp_in_N TV08_imp_N TV10_imp_ex_N TV12_imp_in_N

gen mac_sec=substr(macsec_szcl, 1, 6)
gen szcl=substr(macsec_szcl, 8, 5)
drop macsec_szcl
order country year mac_sec szcl
sort country year mac_sec szcl

*preserve
keep country year mac_sec szcl TV02_exp_*
keep if TV02_exp_mn!=.
keep if year>=2010 & year<=2020 // We obtain a balanced panel of 42 obs by restricting to these years and dropping NL
drop if country=="Netherlands"
gen TV02_exp_tot=TV02_exp_mn*TV02_exp_N
collapse (sum) TV02_exp_tot TV02_exp_N, by(year szcl)
gen TV02_exp_mn=TV02_exp_tot/TV02_exp_N
egen szcl_g=group(szcl)
drop szcl
xtset szcl_g year
sort szcl_g year

foreach v in tot mn N {
gen base_`v'_l=TV02_exp_`v' if year==2010
bys szcl: egen base_`v'=mean(base_`v'_l)
drop base_`v'_l
gen ind_`v'= (TV02_exp_`v'/base_`v')*100
gen gr_`v'=((ind_`v'/l.ind_`v')-1)*100 
gen chg_`v'=(gr_`v'/100)*l.TV02_exp_`v'
}

*preserve
keep year szcl ind* gr* chg*
rename ind* ind*_
rename gr* gr*_
rename chg* chg*_
reshape wide ind_tot_- chg_N_, i(year) j(szcl_g)
*export excel using "Trade_decomp.xlsx", firstrow(varlabels) sheet (Exp_szcl, replace) // chart b)
keep year gr*

drop if year<2012

rename gr_*_1 gr_1_*
rename gr_*_2 gr_2_*
rename gr_*_3 gr_3_*

gen d_1=.
gen d_2=.
gen d_3=.

label var d_1 "20-49 empl."
label var d_2 "50-249 empl."
label var d_3 ">249 empl."

merge 1:1 year using "Enterprise Competitiveness Indicator\REER & Market Shares\Exp_wg_Reer_szcl.dta"
drop _merge

rename wg_reer_42_3 wg_reer_42_1
rename wg_reer_42_4 wg_reer_42_2
rename wg_reer_42_5 wg_reer_42_3

foreach s in 1 2 3 {
	
gen adj_gr_`s'_mn=gr_`s'_mn

replace adj_gr_`s'_mn=gr_`s'_N+gr_`s'_mn if gr_`s'_N>=0 & gr_`s'_mn>=0
replace adj_gr_`s'_mn=gr_`s'_N+gr_`s'_mn if gr_`s'_N<0 & gr_`s'_mn<0

twoway  (bar adj_gr_`s'_mn year, color(edkblue) barwidth(0.5)) (bar gr_`s'_N year, color(cranberry) barwidth(0.5)) (line gr_`s'_tot year, lcolor(dkgreen) lwidth(medthick) lpattern(solid)) (line wg_reer_42_`s' year, lcolor(gold) lwidth(medthick) lpattern(dash) yaxis(2)), graphr(color(white)) plotr(color(white)) subtitle(, bcolor(white) lcolor(black)) xlabel(2012(2)2020,labsize(3)) yla(-15(5)20,labsize(3) angle(0) axis(1)) ytitle("", size(1) axis(1)) yla(98(2)108,labsize(3) angle(0) axis(2)) ytitle("", size(1) axis(2)) legend(on label(1 "Intensive") label(2 "Extensive") label(3 "Total") label(4 "REER (rhs)") size(4) cols(4) symxsize(*0.5) position(12) order(1 "Intensive" 2 "Extensive" 3 "Total" 4 "REER (rhs)") region(lwidth(none))) /*yline(0, lpattern() lcolor(grey))*/ xtitle("") title("`: var label d_`s''", size(4) color(black)) note("") name("Margins_szcl_`s'")
graph export "PDF_charts\Margins_szcl_`s'.pdf", as(pdf) replace
}

grc1leg Margins_total Margins_szcl_3 Margins_szcl_2 Margins_szcl_1 Margins_dest_in Margins_dest_ex, cols(3) graphregion(color(white)) position(12)
graph export "PDF_charts\Margins.pdf", as(pdf) replace 
