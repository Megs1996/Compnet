******************************************************************************************************************
* This do files constructs the micro-aggregated ECI for each country by applying the cross-country "min-max"
* normalization within each macro-sector and then averaging over macro-sectors within the same country
******************************************************************************************************************

clear all
cap restore
cap log close
set more off

global main_dr "C:\Users\Marco\Desktop\CompNet 2023" // Set the main directory here
global data_dr "9th Vintage" // Set the input data directory here
global sub_dr "Enterprise Competitiveness Indicator" // Set the sub-directory here

cd "$main_dr"

capture noisily mkdir "$sub_dr"

global vars FR31_roa FR35_va_rev FR25_rev_capcost FR27_rev_lc FR29_rev_m PV07_lprod_va /*FR30_rk_l*/ FR03_collateral_ta FR18_leverage FR36_ifa_rev /*FR37_invest_k FR38_invest_rev*/ CE46_markup_2 FR21_pcm_kvar /*PEb0_tfp_0*/ PV00_kprod_va /*FR15_lc_capcost*/ LV24_rwage PEi5_rts_2 FR02_cashflow_ta FR22_profitmargin FR30_rk_l

use "$data_dr\jd_inp_country_20e_weighted.dta", clear

keep if by_var=="LV24_rwage"
drop if year<2012
drop if year>2020
keep if by_var_value==10
keep country year LV24_rwage_p1
rename LV24_rwage_p1 min_wage
save "$sub_dr/Output/Min_Wage.dta", replace

// We are using weighted data since they guarantee better alignment with numerosity of the
// official Eurostat SBS statistics
use "$data_dr\unconditional_mac_sector_20e_weighted.dta", clear
drop if year<2012
drop if year>2020

// We drop macro-sectors with many missing value
drop if mac_sector==5 | mac_sector==7 

egen id=group(country mac_sector)
xtset id year
*replace PEi5_rts_2_mn=((FV14_rk_mn/l.FV14_rk_mn)-1)*100 if country=="Germany" & mac_sector==2
drop id

joinby country year using "$sub_dr/Output/Min_Wage.dta", unmatched (both)
drop _merge
foreach m in mn p1 p99 {
replace LV24_rwage_`m'=LV24_rwage_`m'/min_wage
} 

// We exclude observations for which the necessary data are either missing or exhibiting suspicious patterns,
// e.g., the mean being above or below the 99th and 1th percentiles respectively (this can be the case for
// extremely skewed distributions); this lowers observations from 1281 to 1095
foreach v in $vars {
gen er_`v'=0
replace er_`v'=1 if `v'_mn==. | `v'_p1==. | `v'_p99==.
replace er_`v'=1 if `v'_mn<`v'_p1 | `v'_mn>`v'_p99
replace `v'_mn=. if er_`v'==1
replace `v'_p1=. if er_`v'==1
replace `v'_p99=. if er_`v'==1
drop er_`v'

// We build the cross-country macro-sectoral distribution's minimum and maximum by taking respectively the least 1st
// percentile and the highest 99th percentile across countries within each macro-sector; we do this in three ways:
// - for the first year
// - for each specific year
// - over all years

// First Year (fy)
bys mac_sector: egen min_fyy=min(`v'_p1) if year==2012
bys mac_sector: egen max_fyy=max(`v'_p99) if year==2012
bys mac_sector: egen min_fy=mean(min_fyy)
bys mac_sector: egen max_fy=mean(max_fyy)
drop min_fyy max_fyy

// Year Specific (ys)
bys year mac_sector: egen min_ys=min(`v'_p1)
bys year mac_sector: egen max_ys=max(`v'_p99)

// All Years (ay)
bys mac_sector: egen min_ay=min(`v'_p1)
bys mac_sector: egen max_ay=max(`v'_p99)

preserve
keep country year mac_sector min* max*
rename min* `v'_min* 
rename max* `v'_max*
sort country year mac_sector
save "$sub_dr/Output/Mcs_minmax_`v'.dta", replace
restore

// We compute the min-max normalized variable for each macro-sector: it can be showed that using
// the macrosectoral mean is equivalent to first computing the min-max normalized value for each firm
// and then averaging across firms within the macro-sector
foreach m in fy ys ay {
gen `v'_norm_`m'=((`v'_mn-min_`m')/(max_`m'-min_`m'))*100
}
drop min* max*
}

// The value of leverage needs to be inverted (because a higher leverage likely hinders competitiveness)
foreach m in fy ys ay {
	replace FR18_leverage_norm_`m'=100-FR18_leverage_norm_`m'
}	

egen id=group(country mac_sector)
xtset id year
sort id year

*** Missing values ****
foreach v in $vars {
gen ch_`v'_sw=(`v'_sw/l.`v'_sw)-1
by id: egen mch_`v'_sw=mean(ch_`v'_sw)
replace `v'_sw=l.`v'_sw*(1+mch_`v'_sw) if `v'_sw==.
foreach m in fy ys ay {
gen ch_`v'_norm_`m'=`v'_norm_`m'-l.`v'_norm_`m'
by id: egen mch_`v'_norm_`m'=mean(ch_`v'_norm_`m')
replace `v'_norm_`m'=l.`v'_norm_`m'+mch_`v'_norm_`m' if `v'_norm_`m'==.
}
drop ch_* mch_*
}

drop id

foreach v in $vars {
foreach m in fy ys ay {
	drop if  `v'_norm_`m'==.
}
}

keep country year mac_sector *norm* FR31_roa_sw FR35_va_rev_sw FR25_rev_capcost_sw FR27_rev_lc_sw FR29_rev_m_sw PV07_lprod_va_sw FR30_rk_l_sw FR03_collateral_ta_sw FR18_leverage_sw FR36_ifa_rev_sw /*FR37_invest_k_sw FR38_invest_rev_sw*/ CE46_markup_2_sw FR21_pcm_kvar_sw /*PEb0_tfp_0_sw*/ PV00_kprod_va_sw /*FR15_lc_capcost_sw*/ LV24_rwage_sw PEi5_rts_2_sw  FR02_cashflow_ta_sw FR22_profitmargin_sw FR30_rk_l_sw

*******************************************************
// We first build the ECI for each country-macrosector
*******************************************************

// As first we compute the weights within every dimension

* Dimensions 3, 4, and 5 have three variables each
foreach v in PV07_lprod_va PV00_kprod_va FR30_rk_l FR03_collateral_ta FR18_leverage FR02_cashflow_ta FR36_ifa_rev LV24_rwage PEi5_rts_2 {
gen weight_`v'=1/3
}

* Dimensions 1 and 2 have four variables each
foreach v in FR31_roa CE46_markup_2 FR35_va_rev FR22_profitmargin FR21_pcm_kvar FR25_rev_capcost FR27_rev_lc FR29_rev_m {
gen weight_`v'=1/4
}

// The following delivers the normalized scores weighted within the respective Dimension
foreach m in fy ys ay {
foreach v in $vars {
	gen weighted_`v'_`m'=weight_`v'*`v'_norm_`m'
}
}

// We now compute the ECI for every Dimension and the overall ECI*
// Notice we weigh every Dimension by 1/5; this weight is further split between the variables that 
// compose each Dimension
foreach m in fy ys ay {
gen ECI_`m'=(1/5)*(weighted_FR31_roa_`m'+weighted_CE46_markup_2_`m'+weighted_FR35_va_rev_`m'+weighted_FR22_profitmargin_`m'+weighted_FR21_pcm_kvar_`m'+weighted_FR25_rev_capcost_`m'+weighted_FR27_rev_lc_`m'+weighted_FR29_rev_m_`m'+weighted_PV07_lprod_va_`m'+weighted_PV00_kprod_va_`m'+weighted_FR30_rk_l_`m'+weighted_FR03_collateral_ta_`m'+weighted_FR18_leverage_`m'+weighted_FR02_cashflow_ta_`m'+weighted_FR36_ifa_rev_`m'+weighted_LV24_rwage_`m'+weighted_PEi5_rts_2_`m')
gen ECI_dim1_`m'=weighted_FR31_roa_`m'+weighted_CE46_markup_2_`m'+weighted_FR35_va_rev_`m'+weighted_FR22_profitmargin_`m'
gen ECI_dim2_`m'=weighted_FR21_pcm_kvar_`m'+weighted_FR25_rev_capcost_`m'+weighted_FR27_rev_lc_`m'+weighted_FR29_rev_m_`m'
gen ECI_dim3_`m'=weighted_PV07_lprod_va_`m'+weighted_PV00_kprod_va_`m'+weighted_FR30_rk_l_`m'
gen ECI_dim4_`m'=weighted_FR03_collateral_ta_`m'+weighted_FR18_leverage_`m'+weighted_FR02_cashflow_ta_`m'
gen ECI_dim5_`m'=weighted_FR36_ifa_rev_`m'+weighted_LV24_rwage_`m'+weighted_PEi5_rts_2_`m'
gen ECI2_`m'=(1/5)*(ECI_dim1_`m'+ECI_dim2_`m'+ECI_dim3_`m'+ECI_dim4_`m'+ECI_dim5_`m') // Just as a check
gen ECI_dif_`m'=ECI_`m'-ECI2_`m'
}
drop ECI_dif* ECI2*

sort year country mac_sector

// Replacing country names with their respective 2-digits ISO codes
replace country="BE" if country=="Belgium"
replace country="HR" if country=="Croatia"
replace country="CZ" if country=="Czech Republic"
replace country="DK" if country=="Denmark"
replace country="FI" if country=="Finland"
replace country="FR" if country=="France"
replace country="DE" if country=="Germany"
replace country="HU" if country=="Hungary"
replace country="IT" if country=="Italy"
replace country="LV" if country=="Latvia"
replace country="LT" if country=="Lithuania"
replace country="MT" if country=="Malta"
replace country="NL" if country=="Netherlands"
replace country="PL" if country=="Poland"
replace country="PT" if country=="Portugal"
replace country="RO" if country=="Romania"
replace country="SK" if country=="Slovakia"
replace country="SI" if country=="Slovenia"
replace country="ES" if country=="Spain"
replace country="SE" if country=="Sweden"
replace country="CH" if country=="Switzerland"

save "$sub_dr/Output/MacSec_ECI.dta", replace

preserve

replace country="W" if country=="BE" 
replace country="E" if country=="HR" 
replace country="E" if country=="CZ" 
replace country="N" if country=="DK" 
replace country="N" if country=="FI" 
replace country="W" if country=="FR" 
drop if country=="DE" 
replace country="E" if country=="HU" 
replace country="S" if country=="IT" 
drop if country=="LV" 
replace country="N" if country=="LT" 
replace country="S" if country=="MT" 
drop if country=="NL" 
replace country="E" if country=="PL" 
replace country="S" if country=="PT" 
replace country="E" if country=="RO" 
replace country="E" if country=="SK" 
replace country="E" if country=="SI" 
replace country="S" if country=="ES" 
replace country="N" if country=="SE" 
replace country="W" if country=="CH" 

collapse (mean) ECI*, by(year country mac_sector)

save "$sub_dr/Output/MacSec_ECI_means.dta", replace

restore

append using "$sub_dr/Output/MacSec_ECI_means.dta"
sort year country mac_sector

gen fy=""
gen ys=""
gen ay=""

label var fy "fixed to first year"
label var ys "taken for every specific year"
label var ay "taken over the whole time span"

local fy_output First_Year
local ys_output Specific_Year
local ay_output All_Years

drop if country=="N" | country=="W" | country=="E" | country=="S"

// We revert the country-level ECI as the weighted mean of macrosector-level ECIs
// the weight of each macro-sector is the macrosectoral share on the country's total population
// (see the proof).

// Since we are using the weighted dataset, we have to take sum of weights (sw) instead of numerosity (N).
// Since variables slightly differ in terms of sw for the same country-macrosector, we build a weighted sw
// across variables where the weight of each variable is equal to its weight within the ECI.
// First, we make the dataset rectangular by filling the missing year-country-macrosector observations with 
// their most recent lag.

foreach v in $vars {
gen popwg_`v'=(1/5)*weight_`v'*`v'_sw
}
egen popwg=rowtotal(popwg_FR31_roa-popwg_FR30_rk_l)
*replace popwg=. if popwg==0
*replace popwg=l.popwg if popwg==.

bys country year: egen tot_popwg=sum(popwg)
gen sh= popwg/tot_popwg

*sort id year

foreach m in fy ys ay {
forval n = 1/5 {
	*replace ECI_dim`n'_`m'=l.ECI_dim`n'_`m' if ECI_dim`n'_`m'==.
	gen mccntr_ECI_dim`n'_`m'=ECI_dim`n'_`m'*sh
}
*replace ECI_`m'=l.ECI_`m' if ECI_`m'==.
gen mccntr_ECI_`m'=ECI_`m'*sh
}

// Summing the weighted min-max normalized macrosectoral values is equivalent to averaging the min-max
// normalized values across all firms in the population
collapse (sum) mccntr_ECI_*, by(country year)
rename mccntr_* *

save "$sub_dr/Output/Country_ECI.dta", replace

preserve

replace country="W" if country=="BE" 
replace country="E" if country=="HR" 
replace country="E" if country=="CZ" 
replace country="N" if country=="DK" 
replace country="N" if country=="FI" 
replace country="W" if country=="FR" 
drop if country=="DE" 
replace country="E" if country=="HU" 
replace country="S" if country=="IT" 
drop if country=="LV" 
replace country="N" if country=="LT" 
replace country="S" if country=="MT" 
drop if country=="NL" 
replace country="E" if country=="PL" 
replace country="S" if country=="PT" 
replace country="E" if country=="RO" 
replace country="E" if country=="SK" 
replace country="E" if country=="SI" 
replace country="S" if country=="ES" 
replace country="N" if country=="SE" 
replace country="W" if country=="CH" 

collapse (mean) ECI*, by(year country)

save "$sub_dr/Output/Country_ECI_means.dta", replace

restore

append using "$sub_dr/Output/Country_ECI_means.dta"
sort country year

gen dim1=""
gen dim2=""
gen dim3=""
gen dim4=""
gen dim5=""

local dim1_min 25
local dim2_min 12
local dim3_min 0
local dim4_min 32
local dim5_min 12

local dim1_int 5
local dim2_int 4
local dim3_int 2
local dim4_int 4
local dim5_int 4

local dim1_max 55
local dim2_max 32
local dim3_max 10
local dim4_max 60
local dim5_max 28

local dim1_N_text_y 42.8
local dim1_W_text_y 46.2
local dim1_E_text_y 41.9
local dim1_S_text_y 36.3
local dim2_N_text_y 22.8
local dim2_W_text_y 23
local dim2_E_text_y 24.4
local dim2_S_text_y 19.4
local dim3_N_text_y 5
local dim3_W_text_y 6.6
local dim3_E_text_y 3.3
local dim3_S_text_y 4.3
local dim4_N_text_y 48.6
local dim4_W_text_y 50.5
local dim4_E_text_y 51.2
local dim4_S_text_y 43.7
local dim5_N_text_y 16.4
local dim5_W_text_y 18.1
local dim5_E_text_y 16.9
local dim5_S_text_y 15.9

label var dim1 "Return"
label var dim2 "Production Costs"
label var dim3 "Productivity"
label var dim4 "Risk"
label var dim5 "Quality Orientation"


gen fy=""
gen ys=""
gen ay=""

label var fy "fixed to first year"
label var ys "taken for every specific year"
label var ay "taken over the whole time span"

foreach m in fy ys ay {
twoway (line ECI_`m' year if country=="DK", lcolor(edkblue) lwidth(medthick) lpattern(solid)) (line ECI_`m' year if country=="FI", lcolor(cranberry) lwidth(medthick) lpattern(solid)) (line ECI_`m' year if country=="LV", lcolor(dkgreen) lwidth(medthick) lpattern(solid)) (line ECI_`m' year if country=="LT", lcolor(gold) lwidth(medthick) lpattern(solid)) (line ECI_`m' year if country=="SE", lcolor(dkorange) lwidth(medthick) lpattern(solid)) (line ECI_`m' year if country=="N", lcolor(midblue) lpattern(dash) lwidth(vthick)), graphr(color(white)) plotr(color(white)) subtitle(, bcolor(white) lcolor(black)) xlabel(2012(4)2020,labsize(5)) yla(15(5)35,labsize(5) angle(0)) ytitle("", size(1)) legend(on label(1 "DK") label(2 "FI") label(3 "LV") label(4 "LT") label(5 "SE") size(4) cols(3) symxsize(*0.5) position(12) order(1 "DK" 2 "FI" 3 "LV" 4 "LT" 5 "SE") region(lwidth(none))) /*yline(0, lpattern() lcolor(grey))*/ xtitle("") title("Northern Europe") note("") name(ECI_cntr_`m'_n, replace) text(27 2019 "Mean", placement(c) justification(left) size(5) color(midblue))	
	
twoway (line ECI_`m' year if country=="BE", lcolor(edkblue) lwidth(medthick) lpattern(solid)) (line ECI_`m' year if country=="FR", lcolor(cranberry) lwidth(medthick) lpattern(solid)) (line ECI_`m' year if country=="DE", lcolor(dkgreen) lwidth(medthick) lpattern(solid)) (line ECI_`m' year if country=="NL", lcolor(gold) lwidth(medthick) lpattern(solid)) (line ECI_`m' year if country=="CH", lcolor(dkorange) lwidth(medthick) lpattern(solid)) (line ECI_`m' year if country=="W", lcolor(midblue) lpattern(dash) lwidth(vthick)), graphr(color(white)) plotr(color(white)) subtitle(, bcolor(white) lcolor(black)) xlabel(2012(4)2020,labsize(5)) yla(15(5)35,labsize(5) angle(0) nolabels) ytitle("", size(1)) legend(on label(1 "BE") label(2 "FR") label(3 "DE") label(4 "NL") label(5 "CH") size(4) cols(3) symxsize(*0.5) position(12) order(1 "BE" 2 "FR" 3 "DE" 4 "NL" 5 "CH") region(lwidth(none))) /*yline(0, lpattern() lcolor(grey))*/ xtitle("") title("Western Europe") note("") name(ECI_cntr_`m'_w, replace) text(29.5 2019 "Mean", placement(c) justification(left) size(5) color(midblue))

twoway (line ECI_`m' year if country=="HR", lcolor(edkblue) lwidth(medthick) lpattern(solid)) (line ECI_`m' year if country=="CZ", lcolor(cranberry) lwidth(medthick) lpattern(solid)) (line ECI_`m' year if country=="HU", lcolor(dkgreen) lwidth(medthick) lpattern(solid)) (line ECI_`m' year if country=="PL", lcolor(gold) lwidth(medthick) lpattern(solid)) (line ECI_`m' year if country=="RO", lcolor(dkorange) lwidth(medthick) lpattern(solid)) (line ECI_`m' year if country=="SK", lcolor(gs10) lwidth(medthick) lpattern(solid)) (line ECI_`m' year if country=="SI", lcolor(maroon) lwidth(medthick) lpattern(solid)) (line ECI_`m' year if country=="E", lcolor(midblue) lpattern(dash) lwidth(vthick)), graphr(color(white)) plotr(color(white)) subtitle(, bcolor(white) lcolor(black)) xlabel(2012(4)2020,labsize(5)) yla(15(5)35,labsize(5) angle(0) nolabels) ytitle("", size(1)) legend(on label(1 "HR") label(2 "CZ") label(3 "HU") label(4 "PL") label(5 "RO") label(6 "SK") label(7 "SI") size(4) cols(3) symxsize(*0.5) position(12) order(1 "HR" 2 "CZ" 3 "HU" 4 "PL" 5 "RO" 6 "SK" 7 "SI") region(lwidth(none))) /*yline(0, lpattern() lcolor(grey))*/ xtitle("") title("Eastern Europe") note("") name(ECI_cntr_`m'_e, replace) text(27.4 2019 "Mean", placement(c) justification(left) size(5) color(midblue))

twoway (line ECI_`m' year if country=="IT", lcolor(edkblue) lwidth(medthick) lpattern(solid)) (line ECI_`m' year if country=="MT", lcolor(cranberry) lwidth(medthick) lpattern(solid)) (line ECI_`m' year if country=="PT", lcolor(dkgreen) lwidth(medthick) lpattern(solid)) (line ECI_`m' year if country=="ES", lcolor(gold) lwidth(medthick) lpattern(solid)) (line ECI_`m' year if country=="S", lcolor(midblue) lpattern(dash) lwidth(vthick)), graphr(color(white)) plotr(color(white)) subtitle(, bcolor(white) lcolor(black)) xlabel(2012(4)2020,labsize(5)) yla(15(5)35,labsize(5) angle(0) nolabels) ytitle("", size(1)) legend(on label(1 "IT") label(2 "MT") label(3 "PT") label(4 "ES") size(4) cols(3) symxsize(*0.5) position(12) order(1 "IT" 2 "MT" 3 "PT" 4 "ES") region(lwidth(none))) /*yline(0, lpattern() lcolor(grey))*/ xtitle("") title("Southern Europe") note("") name(ECI_cntr_`m'_s, replace) text(25.4 2019 "Mean", placement(c) justification(left) size(5) color(midblue))
}

foreach n in dim1 dim2 dim3 dim4 dim5 {
foreach m in fy ys ay {
twoway (line ECI_`n'_`m' year if country=="DK", lcolor(edkblue) lwidth(medthick) lpattern(solid)) (line ECI_`n'_`m' year if country=="FI", lcolor(cranberry) lwidth(medthick) lpattern(solid)) (line ECI_`n'_`m' year if country=="LV", lcolor(dkgreen) lwidth(medthick) lpattern(solid)) (line ECI_`n'_`m' year if country=="LT", lcolor(gold) lwidth(medthick) lpattern(solid)) (line ECI_`n'_`m' year if country=="SE", lcolor(dkorange) lwidth(medthick) lpattern(solid)) (line ECI_`n'_`m' year if country=="N", lcolor(midblue) lpattern(dash) lwidth(vthick)), graphr(color(white)) plotr(color(white)) subtitle(, bcolor(white) lcolor(black)) xlabel(2012(4)2020,labsize(5)) yla(``n'_min'(``n'_int')``n'_max',labsize(5) angle(0)) ytitle("", size(1)) legend(on label(1 "DK") label(2 "FI") label(3 "LV") label(4 "LT") label(5 "SE") size(4) cols(3) symxsize(*0.5) position(12) order(1 "DK" 2 "FI" 3 "LV" 4 "LT" 5 "SE") region(lwidth(none))) /*yline(0, lpattern() lcolor(grey))*/ xtitle("") title("Northern Europe"/*, size(3)*/) note("") name(ECI_cntr_`n'_`m'_n, replace) text(``n'_N_text_y' 2019 "Mean", placement(c) justification(left) size(5) color(midblue))

twoway (line ECI_`n'_`m' year if country=="BE", lcolor(edkblue) lwidth(medthick) lpattern(solid)) (line ECI_`n'_`m' year if country=="FR", lcolor(cranberry) lwidth(medthick) lpattern(solid)) (line ECI_`n'_`m' year if country=="DE", lcolor(dkgreen) lwidth(medthick) lpattern(solid)) (line ECI_`n'_`m' year if country=="NL", lcolor(gold) lwidth(medthick) lpattern(solid)) (line ECI_`n'_`m' year if country=="CH", lcolor(dkorange) lwidth(medthick) lpattern(solid)) (line ECI_`n'_`m' year if country=="W", lcolor(midblue) lpattern(dash) lwidth(vthick)), graphr(color(white)) plotr(color(white)) subtitle(, bcolor(white) lcolor(black)) xlabel(2012(4)2020,labsize(5)) yla(``n'_min'(``n'_int')``n'_max',labsize(5) angle(0) nolabels) ytitle("", size(1)) legend(on label(1 "BE") label(2 "FR") label(3 "DE") label(4 "NL") label(5 "CH") size(4) cols(3) symxsize(*0.5) position(12) order(1 "BE" 2 "FR" 3 "DE" 4 "NL" 5 "CH") region(lwidth(none))) /*yline(0, lpattern() lcolor(grey))*/ xtitle("") title("Western Europe"/*, size(3)*/) note("") name(ECI_cntr_`n'_`m'_w, replace) text(``n'_W_text_y' 2019 "Mean", placement(c) justification(left) size(5) color(midblue))

twoway (line ECI_`n'_`m' year if country=="HR", lcolor(edkblue) lwidth(medthick) lpattern(solid)) (line ECI_`n'_`m' year if country=="CZ", lcolor(cranberry) lwidth(medthick) lpattern(solid)) (line ECI_`n'_`m' year if country=="HU", lcolor(dkgreen) lwidth(medthick) lpattern(solid)) (line ECI_`n'_`m' year if country=="PL", lcolor(gold) lwidth(medthick) lpattern(solid)) (line ECI_`n'_`m' year if country=="RO", lcolor(dkorange) lwidth(medthick) lpattern(solid)) (line ECI_`n'_`m' year if country=="SK", lcolor(gs10) lwidth(medthick) lpattern(solid)) (line ECI_`n'_`m' year if country=="SI", lcolor(maroon) lwidth(medthick) lpattern(solid)) (line ECI_`n'_`m' year if country=="E", lcolor(midblue) lpattern(dash) lwidth(vthick)), graphr(color(white)) plotr(color(white)) subtitle(, bcolor(white) lcolor(black)) xlabel(2012(4)2020,labsize(5)) yla(``n'_min'(``n'_int')``n'_max',labsize(5) angle(0) nolabels) ytitle("", size(1)) legend(on label(1 "HR") label(2 "CZ") label(3 "HU") label(4 "PL") label(5 "RO") label(6 "SK") label(7 "SI") size(4) cols(3) symxsize(*0.5) position(12) order(1 "HR" 2 "CZ" 3 "HU" 4 "PL" 5 "RO" 6 "SK" 7 "SI") region(lwidth(none))) /*yline(0, lpattern() lcolor(grey))*/ xtitle("") title("Eastern Europe"/*, size(3)*/) note("") name(ECI_cntr_`n'_`m'_e, replace) text(``n'_E_text_y' 2019 "Mean", placement(c) justification(left) size(5) color(midblue))

twoway (line ECI_`n'_`m' year if country=="IT", lcolor(edkblue) lwidth(medthick) lpattern(solid)) (line ECI_`n'_`m' year if country=="MT", lcolor(cranberry) lwidth(medthick) lpattern(solid)) (line ECI_`n'_`m' year if country=="PT", lcolor(dkgreen) lwidth(medthick) lpattern(solid)) (line ECI_`n'_`m' year if country=="ES", lcolor(gold) lwidth(medthick) lpattern(solid)) (line ECI_`n'_`m' year if country=="S", lcolor(midblue) lpattern(dash) lwidth(vthick)), graphr(color(white)) plotr(color(white)) subtitle(, bcolor(white) lcolor(black)) xlabel(2012(4)2020,labsize(5)) yla(``n'_min'(``n'_int')``n'_max',labsize(5) angle(0) nolabels) ytitle("", size(1)) legend(on label(1 "IT") label(2 "MT") label(3 "PT") label(4 "ES") size(4) cols(3) symxsize(*0.5) position(12) order(1 "IT" 2 "MT" 3 "PT" 4 "ES") region(lwidth(none))) /*yline(0, lpattern() lcolor(grey))*/ xtitle("") title("Southern Europe"/*, size(3)*/) note("") name(ECI_cntr_`n'_`m'_s, replace) text(``n'_S_text_y' 2019 "Mean", placement(c) justification(left) size(5) color(midblue))
}
}

foreach m in fy ys ay {
		
graph combine ECI_cntr_`m'_n ECI_cntr_`m'_w ECI_cntr_`m'_e ECI_cntr_`m'_s, graphr(color(white)) graphregion(color(white)) rows(1) /*note("Note: Normalization procedure implemented using min and max `: var label `m''. Mean is simple" "average by group of countries." )*/
graph export "$sub_dr/Output//``m'_output'//Charts_ECI_cntr.pdf", replace

graph combine ECI_cntr_dim1_`m'_n ECI_cntr_dim1_`m'_w ECI_cntr_dim1_`m'_e ECI_cntr_dim1_`m'_s, graphr(color(white)) graphregion(color(white)) rows(1) /*note("Note: Normalization procedure implemented using min and max `: var label `m''. Mean is simple" "average by group of countries." )*/
graph export "$sub_dr/Output//``m'_output'//Charts_ECI1_cntr.pdf", replace

graph combine ECI_cntr_dim2_`m'_n ECI_cntr_dim2_`m'_w ECI_cntr_dim2_`m'_e ECI_cntr_dim2_`m'_s, graphr(color(white)) graphregion(color(white)) rows(1) /*note("Note: Normalization procedure implemented using min and max `: var label `m''. Mean is simple" "average by group of countries." )*/
graph export "$sub_dr/Output//``m'_output'//Charts_ECI2_cntr.pdf", replace

graph combine ECI_cntr_dim3_`m'_n ECI_cntr_dim3_`m'_w ECI_cntr_dim3_`m'_e ECI_cntr_dim3_`m'_s, graphr(color(white)) graphregion(color(white)) rows(1) /*note("Note: Normalization procedure implemented using min and max `: var label `m''. Mean is simple" "average by group of countries." )*/
graph export "$sub_dr/Output//``m'_output'//Charts_ECI3_cntr.pdf", replace

graph combine ECI_cntr_dim4_`m'_n ECI_cntr_dim4_`m'_w ECI_cntr_dim4_`m'_e ECI_cntr_dim4_`m'_s, graphr(color(white)) graphregion(color(white)) rows(1) /*note("Note: Normalization procedure implemented using min and max `: var label `m''. Mean is simple" "average by group of countries." )*/
graph export "$sub_dr/Output//``m'_output'//Charts_ECI4_cntr.pdf", replace

graph combine ECI_cntr_dim5_`m'_n ECI_cntr_dim5_`m'_w ECI_cntr_dim5_`m'_e ECI_cntr_dim5_`m'_s, graphr(color(white)) graphregion(color(white)) rows(1) /*note("Note: Normalization procedure implemented using min and max `: var label `m''. Mean is simple" "average by group of countries." )*/
graph export "$sub_dr/Output//``m'_output'//Charts_ECI5_cntr.pdf", replace

}

preserve

keep if country=="N" | country=="W" | country=="E" | country=="S"

export excel using "$sub_dr\Output\Growth_rates.xlsx", firstrow(variables) replace

restore

drop if country=="N" | country=="W" | country=="E" | country=="S"

keep country year *_ay

egen id=group(country)
xtset id year 

gen ECI_ay_chng=((ECI_ay/l.ECI_ay)-1)*100

foreach n in dim1 dim2 dim3 dim4 dim5 {
	gen ECI_`n'_ay_chng=((ECI_`n'_ay/l.ECI_`n'_ay)-1)*100
}

replace country="Austria" if country=="AT"
replace country="Belgium" if country=="BE"
replace country="Bulgaria" if country=="BG"
replace country="Switzerland" if country=="CH"
replace country="Cyprus" if country=="CY"
replace country="Czech Republic" if country=="CZ"
replace country="Germany" if country=="DE"
replace country="Denmark" if country=="DK"
replace country="EA" if country=="EA19"
replace country="Estonia" if country=="EE"
replace country="Greece" if country=="EL"
replace country="Spain" if country=="ES"
replace country="Finland" if country=="FI"
replace country="France" if country=="FR"
replace country="Croatia" if country=="HR"
replace country="Hungary" if country=="HU"
replace country="Ireland" if country=="IE"
replace country="Italy" if country=="IT"
replace country="Lithuania" if country=="LT"
replace country="Latvia" if country=="LV"
replace country="Malta" if country=="MT"
replace country="Netherlands" if country=="NL"
replace country="Norway" if country=="NO"
replace country="Poland" if country=="PL"
replace country="Portugal" if country=="PT"
replace country="Romania" if country=="RO"
replace country="Sweden" if country=="SE"
replace country="Slovenia" if country=="SI"
replace country="Slovakia" if country=="SK"
replace country="EU" if country=="EU27_2020"

merge 1:1 country year using "$sub_dr\REER & Market Shares\Reer_Mkt_sh.dta"
keep if _merge==3
drop _merge

drop id

reghdfe mkt_sh_GS ECI_ay reer_47, absorb(year)
outreg2 using "$sub_dr\Reg_overall.doc", replace ctitle(Goods & Services) addtext() dec(4) label adjr2 

reghdfe mkt_sh_G ECI_ay reer_47, absorb(year)
outreg2 using "$sub_dr\Reg_overall.doc", append ctitle(Goods) addtext() dec(4) label adjr2 

reghdfe mkt_sh_S ECI_ay reer_47, absorb(year)
outreg2 using "$sub_dr\Reg_overall.doc", append ctitle(Services) addtext() dec(4) label adjr2 


reghdfe mkt_sh_GS ECI_dim1_ay ECI_dim2_ay ECI_dim3_ay ECI_dim4_ay ECI_dim5_ay reer_47, absorb(year)
estimates store A

reghdfe mkt_sh_G ECI_dim1_ay ECI_dim2_ay ECI_dim3_ay ECI_dim4_ay ECI_dim5_ay reer_47, absorb(year)
estimates store G

reghdfe mkt_sh_S ECI_dim1_ay ECI_dim2_ay ECI_dim3_ay ECI_dim4_ay ECI_dim5_ay reer_47, absorb(year)
estimates store S

label var ECI_dim1_ay "Return"
label var ECI_dim2_ay "Production Cost"
label var ECI_dim3_ay "Productivity"
label var ECI_dim4_ay "Risk"
label var ECI_dim5_ay "Quality Orientation"
label var reer_47 "REER"


coefplot (A, label(Goods&Services) lcolor(edkblue) color(edkblue) ciopts(lc(edkblue))) (G, label(Goods) lcolor(cranberry) color(cranberry) ciopts(lc(cranberry))) (S, label(Services) lcolor(dkgreen) color(dkgreen) ciopts(lc(dkgreen))), drop(_cons) xline(0, lcolor(gray) lpattern(dash)) graphregion(color(white)) legend(col(3)) msymbol(C) legend(position(12) region(lwidth(none)))
graph export "$sub_dr/Reg_dimensions.pdf", replace
