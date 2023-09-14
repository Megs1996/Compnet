set more off
clear all

*** This code generates results in the Startup Box, plus additional ones (regressions of characteristics of young firms
*** on startups' composition)

global main_dr "C:\Users\Marco\Desktop\CompNet 2023" // Set the main directory here
global data_dr "9th Vintage" // Set the input data directory here
global sub_dr "Startup Box" // Set the sub-directory here

cd "$main_dr"

capture noisily mkdir "$sub_dr"
capture noisily mkdir "$sub_dr\Tot_firms"
capture noisily mkdir "$sub_dr\Vars"
capture noisily mkdir "$sub_dr\Vars_young"
capture noisily mkdir "$sub_dr\Startups"
capture noisily mkdir "$sub_dr\Output"

*capture noisily mkdir "$sub_dr\"

set more off
//set maxvar 15000

**********************************************************************
**** Variables for total and young firms, at macro-sectoral level ****
**********************************************************************

use "9th Vintage/unconditional_mac_sector_all_unweighted.dta", clear

keep country year mac_sector PV03G1_lprod_va_mn TV02G1_exp_val_adj_mn FV08GH_dhs_rev_growth_mn LV21GH_dhs_labor_growth_mn FR36_ifa_rev_mn FR40_ener_costs_mn CE46_markup_2_mn FD01_safe_mn CV05_hhi_rev_sam_M_tot CV13_hhi_ifa_sam_M_tot CV21_hhi_l_sam_M_tot CV29_hhi_lc_sam_M_tot CV37_hhi_rk_sam_M_tot FR35_va_rev_mn

tostring mac_sec, replace force
destring mac_sec, replace


foreach v in FR36_ifa_rev_mn FR40_ener_costs_mn FV08GH_dhs_rev_growth_mn LV21GH_dhs_labor_growth_mn FD01_safe_mn PV03G1_lprod_va_mn CV05_hhi_rev_sam_M_tot CV13_hhi_ifa_sam_M_tot CV21_hhi_l_sam_M_tot CV29_hhi_lc_sam_M_tot CV37_hhi_rk_sam_M_tot FR35_va_rev_mn {
	replace `v'=`v'*100
}


save "$sub_dr\Vars\Mac_sec_vars.dta", replace

*****************************

use "Enterprise Competitiveness Indicator\Output\MacSec_ECI.dta", clear
keep country year mac_sec ECI_ay ECI_dim1_ay ECI_dim2_ay ECI_dim3_ay ECI_dim4_ay ECI_dim5_ay
tostring mac_sec, replace force
destring mac_sec, replace

rename mac_sec Sectorcode

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

save "$sub_dr\Vars\Mac_sec_ECI.dta", replace

*****************************

use "$data_dr\unconditional_mac_sector_all_unweighted.dta", replace
keep country year mac_sector LV21_l_N
rename mac_sector Sectorcode
rename LV21_l_N Totalnumberoffirms

tostring Sectorcode, replace force
destring Sectorcode, replace

drop if Sectorcode==7

save "$sub_dr\Vars\Tot_cou_macsec_firms.dta", replace

preserve

collapse (sum) Totalnumberoffirms, by(country year)

save "$sub_dr\Vars\Tot_cou_firms.dta", replace

restore

collapse (sum) Totalnumberoffirms, by(Sectorcode year)

save "$sub_dr\Vars\Tot_macsec_firms.dta", replace


**********************************************************************
****************** Share of startups on total firms ******************
**********************************************************************

* By country

import excel "$sub_dr\StartupTypesSector_16June23.xlsx", sheet("1 Country-year-sector") firstrow clear

rename Country country
rename Startupyear year
drop if country=="Lithuania" & year>2015

drop Totalnumberoffirms

merge 1:1 year country Sectorcode using "$sub_dr\Vars\Tot_cou_macsec_firms.dta"
keep if _merge==3
drop _merge

collapse (sum)  Totalnumberofstartupscount Totalnumberoffirms, by(year country)

gen start_up_sh_total=Totalnumberofstartupscount/Totalnumberoffirms

save "$sub_dr\Startups\Type_total.dta", replace


import excel "$sub_dr\StartupTypesSector_16June23.xlsx", sheet("2 Country-year-type-sector") firstrow clear
rename Country country
rename Startupyear year
rename Type type

drop if country=="Lithuania" & year>2015

drop Totalnumberoffirms Startupshare2

rename Totalnumberofstartupscount startup_

replace type="capitalintensive" if type=="capital intensive"
replace type="cashrich" if type=="cash rich"
keep country year Sectorcode Sector type startup_
reshape wide startup_, i(country year Sectorcode Sector) j(type) s

merge 1:1 year country Sectorcode using "$sub_dr\Vars\Tot_cou_macsec_firms.dta"
keep if _merge==3
drop _merge

collapse (sum) startup_* Totalnumberoffirms, by(year country)

foreach t in basic capitalintensive cashrich large leverage {
gen start_up_sh_`t'=startup_`t'/Totalnumberoffirms
}

merge 1:1 country year using "$sub_dr\Startups\Type_total.dta"
drop _merge

drop if year>2020 | year<2010

collapse (mean) start_up_sh_*, by(country)

foreach t in total basic capitalintensive cashrich large leverage {
	replace start_up_sh_`t'=start_up_sh_`t'*100
}

graph hbar start_up_sh_basic start_up_sh_capitalintensive start_up_sh_cashrich start_up_sh_large start_up_sh_leverage, over(country, sort(start_up_sh_total) descending label(labsize(5) angle(0))) /*blabel(bar, orientation(vertical) position(center) format(%4.2f) size(vsmall) color(black))*/ graphr(color(white)) plotr(color(white)) bar(1, color(edkblue)) bar(2, color(cranberry)) bar(3, color(dkgreen)) bar(4, color(gold)) bar(5, color(dkorange)) subtitle(, bcolor(white) lcolor(black)) yla(0(2)10,labsize(5)) ytitle(" ", size(.5)) title("", size(4) color(black)) legend( on label(1 "Basic") label(2 "Capital Intensive") label(3 "Cash Rich") label(4 "Large") label(5 "High Leverage") span size(4) position(12) cols(3) region(lwidth(none))) stack name(su_share_cou, replace)

****************

* By macro-sector

import excel "$sub_dr\StartupTypesSector_16June23.xlsx", sheet("1 Country-year-sector") firstrow clear

rename Country country
rename Startupyear year
rename Type Sector

drop if country=="Lithuania" & year>2015

drop Totalnumberoffirms

merge 1:1 year country Sectorcode using "$sub_dr\Vars\Tot_cou_macsec_firms.dta"
keep if _merge==3
drop _merge

collapse (sum) Totalnumberofstartupscount Totalnumberoffirms, by(year Sector Sectorcode)
rename Totalnumberofstartupscount startups
gen start_up_sh_total=(startups/Totalnumberoffirms)*100
save "$sub_dr\Startups\Tot_startup_sector.dta", replace


import excel "$sub_dr\StartupTypesSector_16June23.xlsx", sheet("2 Country-year-type-sector") firstrow clear

rename Country country
rename Startupyear year
rename Type type

drop if country=="Lithuania" & year>2015

drop Totalnumberoffirms Startupshare2

rename Totalnumberofstartupscount startup_

replace type="capitalintensive" if type=="capital intensive"
replace type="cashrich" if type=="cash rich"
keep country year Sectorcode Sector type startup_
reshape wide startup_, i(country year Sectorcode Sector) j(type) s

merge 1:1 year country Sectorcode using "$sub_dr\Vars\Tot_cou_macsec_firms.dta"
keep if _merge==3
drop _merge

collapse (sum) startup_* Totalnumberoffirms, by(year Sector Sectorcode)

foreach t in basic capitalintensive cashrich large leverage {
gen start_up_sh_`t'=(startup_`t'/Totalnumberoffirms)*100
}

save "$sub_dr\Startups\Type_startup_sector.dta", replace

merge 1:1 Sectorcode year using "$sub_dr\Startups\Tot_startup_sector.dta"
keep if _merge==3
drop _merge

drop if year>2020 | year<2010
collapse (mean) start_up_sh_*, by(Sector)

graph hbar start_up_sh_basic start_up_sh_capitalintensive start_up_sh_cashrich start_up_sh_large start_up_sh_leverage, over(Sector, sort(start_up_sh_total) descending label(labsize(5) angle(0))) blabel(bar, orientation(vertical) position(center) format(%4.2f) size(vsmall) color(black)) graphr(color(white)) plotr(color(white)) bar(1, color(edkblue)) bar(2, color(cranberry)) bar(3, color(dkgreen)) bar(4, color(gold)) bar(5, color(dkorange)) subtitle(, bcolor(white) lcolor(black)) yla(0(2)12,labsize(5)) ytitle(" ", size(.5)) title("", size(4) color(black)) legend( on label(1 "Basic") label(2 "Capital Intensive") label(3 "Cash Rich") label(4 "Large") label(5 "High Leverage") span size(4) position(12) cols(3) region(lwidth(none))) stack name(su_share_mcs_lab, replace)

graph hbar start_up_sh_basic start_up_sh_capitalintensive start_up_sh_cashrich start_up_sh_large start_up_sh_leverage, over(Sector, sort(start_up_sh_total) descending label(labsize(5) angle(0))) /*blabel(bar, orientation(vertical) position(center) format(%4.2f) size(vsmall) color(black))*/ graphr(color(white)) plotr(color(white)) bar(1, color(edkblue)) bar(2, color(cranberry)) bar(3, color(dkgreen)) bar(4, color(gold)) bar(5, color(dkorange)) subtitle(, bcolor(white) lcolor(black)) yla(0(2)12,labsize(5)) ytitle(" ", size(.5)) title("", size(4) color(black)) legend( on label(1 "Basic") label(2 "Capital Intensive") label(3 "Cash Rich") label(4 "Large") label(5 "High Leverage") span size(4) position(12) cols(3) region(lwidth(none))) stack name(su_share_mcs, replace)

grc1leg su_share_cou su_share_mcs, graphr(color(white)) plotr(color(white)) position(12)
graph export "$sub_dr/Output/Shares.pdf", replace


*************************************************
*************************************************

***** Share on startups vs on total firms *****

* By country

import excel "$sub_dr\StartupTypesSector_16June23.xlsx", sheet("1 Country-year-sector") firstrow clear

rename Country country
rename Startupyear year

drop if country=="Lithuania" & year>2015

drop Totalnumberoffirms

merge 1:1 year country Sectorcode using "$sub_dr\Vars\Tot_cou_macsec_firms.dta"
keep if _merge==3
drop _merge

collapse (sum)  Totalnumberofstartupscount Totalnumberoffirms, by(year country)

drop if year>2020 | year<2010

collapse (mean) Totalnumberofstartupscount Totalnumberoffirms, by(country)

egen sum_firms=sum(Totalnumberoffirms)
egen sum_startups=sum(Totalnumberofstartupscount)

gen share_firms=(Totalnumberoffirms/sum_firms)*100
gen share_startups=(Totalnumberofstartupscount/sum_startups)*100

keep country share_*
reshape long share_, i(country) j(group) s
reshape wide share_, i(group) j(country) s

graph hbar share_Croatia share_Denmark share_Finland /*share_France*/ share_Italy share_Lithuania share_Netherlands share_Slovenia share_Spain share_Sweden, over(group, descending label(labsize(4) angle(0))) graphr(color(white)) plotr(color(white)) bar(1, color(edkblue)) bar(2, color(cranberry)) bar(3, color(dkgreen)) bar(4, color(gold)) bar(5, color(dkorange)) bar(6, color(gs10)) bar(7, color(maroon)) bar(8, color(black)lpattern(dashed)) bar(9, color(pink)) subtitle(, bcolor(white) lcolor(black)) yla(0(20)100,labsize(4)) ytitle(" ", size(.5)) title("Share on startups and on total firms", size(4) color(black)) legend( on label(1 "HR") label(2 "DK") label(3 "FI") label(4 "IT") label(5 "LT") label(6 "NL") label(7 "SI") label(8 "ES") label(9 "SE") span size(4) position(12) cols(5) region(lwidth(none))) stack


* By macro-sector

import excel "$sub_dr\StartupTypesSector_16June23.xlsx", sheet("1 Country-year-sector") firstrow clear

rename Country country
rename Startupyear year
rename Type Sector

drop if country=="Lithuania" & year>2015

drop Totalnumberoffirms

merge 1:1 year country Sectorcode using "$sub_dr\Vars\Tot_cou_macsec_firms.dta"
keep if _merge==3
drop _merge

collapse (sum) Totalnumberofstartupscount Totalnumberoffirms, by(year Sector Sectorcode)

drop if year>2020 | year<2010

collapse (mean) Totalnumberofstartupscount Totalnumberoffirms, by(Sector)

egen sum_firms=sum(Totalnumberoffirms)
egen sum_startups=sum(Totalnumberofstartupscount)

gen share_firms=(Totalnumberoffirms/sum_firms)*100
gen share_startups=(Totalnumberofstartupscount/sum_startups)*100

keep Sector share_*
reshape long share_, i(Sector) j(group) s
reshape wide share_, i(group) j(Sector) s

replace group="Startups" if group=="startups"
replace group="All firms" if group=="firms"

format share_* %4.2f

graph hbar share_Admin share_Construction share_Hospitality share_ICT share_Manufacturing share_Professional share_Trade share_Transport, over(group, descending label(labsize(4) angle(0))) blabel(bar, position(center) format(%4.2f) size(small) color(black)) graphr(color(white)) plotr(color(white)) bar(1, color(edkblue)) bar(2, color(cranberry)) bar(3, color(dkgreen)) bar(4, color(gold)) bar(5, color(dkorange)) bar(6, color(gs10)) bar(7, color(maroon)) bar(8, color(lavender)) bar(9, color(pink)) subtitle(, bcolor(white) lcolor(black)) yla(0(20)100,labsize(4)) ytitle(" ", size(.5)) title(/*"Share on startups and on total firms"*/, size(4) color(black)) legend( on label(1 "Admin") label(2 "Construction") label(3 "Hospitality") label(4 "ICT") label(5 "Manufacturing") label(6 "Professional") label(7 "Trade") label(8 "Transport") span size(4) position(12) cols(3) region(lwidth(none))) stack
graph export "$sub_dr/Output/Shares_pop_stu.pdf", replace


**************************************
**************************************
**************************************
************ REGRESSIONS ************* 
**************************************
**************************************
**************************************

***** BASE DATA *****

import excel "$sub_dr\StartupTypesSector_16June23.xlsx", sheet("1 Country-year-sector") firstrow clear

rename Country country
rename Startupyear year
rename Type Sector
drop if country=="Lithuania" & year>2015

keep country year Sectorcode Sector Totalnumberofstartupscount

merge 1:1 country year Sectorcode using "$sub_dr\Vars\Tot_cou_macsec_firms.dta"
keep if _merge==3
drop _merge

gen start_up_sh=(Totalnumberofstartupscount/Totalnumberoffirms)*100

save "$sub_dr\Startups\Reg_base.dta", replace

*******************

import excel "$sub_dr\StartupTypesSector_16June23.xlsx", sheet("2 Country-year-type-sector") firstrow clear

rename Country country
rename Startupyear year

drop if country=="Lithuania" & year>2015

keep country year Sectorcode Sector Type Totalnumberofstartupscount

rename Totalnumberofstartupscount startups_
replace Type="capitalintensive" if Type=="capital intensive"
replace Type="cashrich" if Type=="cash rich"
reshape wide startups_, i(country year Sectorcode Sector) j(Type) s

foreach t in basic capitalintensive cashrich large leverage {
	replace startups_`t'=0 if startups_`t'==.
}

merge 1:1 country year Sectorcode using "$sub_dr\Vars\Tot_cou_macsec_firms.dta"
keep if _merge==3
drop _merge

foreach t in basic capitalintensive cashrich large leverage {
	gen start_up_sh_`t'=startups_`t'/Totalnumberoffirms
	replace start_up_sh_`t'=start_up_sh_`t'*100
}

merge 1:1 country year Sectorcode using "$sub_dr\Startups\Reg_base.dta"
keep if _merge==3
drop _merge

foreach t in basic capitalintensive cashrich large leverage {
	gen su_portion_`t'=startups_`t'/Totalnumberofstartupscount
	replace su_portion_`t'=su_portion_`t'*100
}

save "$sub_dr\Startups\Reg_type_base.dta", replace


*************************************
*********** YOUNG FIRMS *************
*************************************

use "$data_dr/jd_demo_ene_mac_sector_all_unweighted.dta", clear
keep if by_var=="OC00_firm_age"
keep if by_var_value==1

tostring mac_sector, replace force
destring mac_sector, replace

keep country year mac_sector FR40_ener_costs_mn
replace FR40_ener_costs_mn=FR40_ener_costs_mn*100

rename mac_sector Sectorcode

merge 1:1 country year Sectorcode using "$sub_dr\Startups\Reg_type_base.dta"
keep if _merge==3
drop _merge

egen id=group(country Sectorcode)
xtset id year

foreach v in FR40_ener_costs_mn su_portion_basic su_portion_capitalintensive su_portion_cashrich su_portion_large su_portion_leverage {
	gen d_`v'=D.`v'
}

reghdfe FR40_ener_costs_mn su_portion_capitalintensive su_portion_cashrich su_portion_large su_portion_leverage l.su_portion_capitalintensive l.su_portion_cashrich l.su_portion_large l.su_portion_leverage, absorb(id year)
reghdfe d_FR40_ener_costs_mn d_su_portion_capitalintensive d_su_portion_cashrich d_su_portion_large d_su_portion_leverage l.d_su_portion_capitalintensive l.d_su_portion_cashrich l.d_su_portion_large l.d_su_portion_leverage, absorb(id year)

*save "$sub_dr\Ener.dta", replace 


**********
use "$data_dr/jd_trad_demo_mac_sector_all_unweighted.dta", clear
keep if by_var=="OC00_firm_age"
keep if by_var_value==1

tostring mac_sector, replace force
destring mac_sector, replace

keep country year mac_sector TR02_exp_adj_rev_mn

rename mac_sector Sectorcode

merge 1:1 country year Sectorcode using "$sub_dr\Startups\Reg_type_base.dta"
keep if _merge==3
drop _merge

egen id=group(country Sectorcode)
xtset id year

foreach v in TR02_exp_adj_rev_mn su_portion_basic su_portion_capitalintensive su_portion_cashrich su_portion_large su_portion_leverage {
	gen d_`v'=D.`v'
}

reghdfe TR02_exp_adj_rev_mn su_portion_capitalintensive su_portion_cashrich su_portion_large su_portion_leverage l.su_portion_capitalintensive l.su_portion_cashrich l.su_portion_large l.su_portion_leverage, absorb(id year)
reghdfe d_TR02_exp_adj_rev_mn d_su_portion_capitalintensive d_su_portion_cashrich d_su_portion_large d_su_portion_leverage l.d_su_portion_capitalintensive l.d_su_portion_cashrich l.d_su_portion_large l.d_su_portion_leverage, absorb(id year)

*save "$sub_dr\Trad.dta", replace 


**********
use "$data_dr/jd_prod_demo_mac_sector_all_unweighted.dta", clear
keep if by_var=="OC00_firm_age"
keep if by_var_value==1

tostring mac_sector, replace force
destring mac_sector, replace

keep country year mac_sector CE46_markup_2_mn

rename mac_sector Sectorcode

merge 1:1 country year Sectorcode using "$sub_dr\Startups\Reg_type_base.dta"
keep if _merge==3
drop _merge

egen id=group(country Sectorcode)
xtset id year

foreach v in CE46_markup_2_mn su_portion_basic su_portion_capitalintensive su_portion_cashrich su_portion_large su_portion_leverage {
	gen d_`v'=D.`v'
}

reghdfe CE46_markup_2_mn su_portion_capitalintensive su_portion_cashrich su_portion_large su_portion_leverage l.su_portion_capitalintensive l.su_portion_cashrich l.su_portion_large l.su_portion_leverage, absorb(id year)
reghdfe d_CE46_markup_2_mn d_su_portion_capitalintensive d_su_portion_cashrich d_su_portion_large d_su_portion_leverage l.d_su_portion_capitalintensive l.d_su_portion_cashrich l.d_su_portion_large l.d_su_portion_leverage, absorb(id year)

*save "$sub_dr\Prod.dta", replace 


**********
use "$data_dr/jd_grow_demo_mac_sector_all_unweighted.dta", clear
keep if by_var=="OC00_firm_age"
keep if by_var_value==1

tostring mac_sector, replace force
destring mac_sector, replace

keep country year mac_sector PV03G1_lprod_va_mn TV02G1_exp_val_adj_mn PEb0G1_tfp_0_mn FV08GH_dhs_rev_growth_mn 

rename mac_sector Sectorcode

merge 1:1 country year Sectorcode using "$sub_dr\Startups\Reg_type_base.dta"
keep if _merge==3
drop _merge

egen id=group(country Sectorcode)
xtset id year

foreach v in PV03G1_lprod_va_mn TV02G1_exp_val_adj_mn PEb0G1_tfp_0_mn FV08GH_dhs_rev_growth_mn su_portion_basic su_portion_capitalintensive su_portion_cashrich su_portion_large su_portion_leverage {
	gen d_`v'=D.`v'
}

reghdfe PV03G1_lprod_va_mn su_portion_capitalintensive su_portion_cashrich su_portion_large su_portion_leverage l.su_portion_capitalintensive l.su_portion_cashrich l.su_portion_large l.su_portion_leverage, absorb(id year)
reghdfe d_PV03G1_lprod_va_mn d_su_portion_capitalintensive d_su_portion_cashrich d_su_portion_large d_su_portion_leverage l.d_su_portion_capitalintensive l.d_su_portion_cashrich l.d_su_portion_large l.d_su_portion_leverage, absorb(id year)

reghdfe TV02G1_exp_val_adj_mn su_portion_capitalintensive su_portion_cashrich su_portion_large su_portion_leverage l.su_portion_capitalintensive l.su_portion_cashrich l.su_portion_large l.su_portion_leverage, absorb(id year)
reghdfe d_TV02G1_exp_val_adj_mn d_su_portion_capitalintensive d_su_portion_cashrich d_su_portion_large d_su_portion_leverage l.d_su_portion_capitalintensive l.d_su_portion_cashrich l.d_su_portion_large l.d_su_portion_leverage, absorb(id year)

reghdfe PEb0G1_tfp_0_mn su_portion_capitalintensive su_portion_cashrich su_portion_large su_portion_leverage l.su_portion_capitalintensive l.su_portion_cashrich l.su_portion_large l.su_portion_leverage, absorb(id year)
reghdfe d_PEb0G1_tfp_0_mn d_su_portion_capitalintensive d_su_portion_cashrich d_su_portion_large d_su_portion_leverage l.d_su_portion_capitalintensive l.d_su_portion_cashrich l.d_su_portion_large l.d_su_portion_leverage, absorb(id year)

reghdfe FV08GH_dhs_rev_growth_mn su_portion_capitalintensive su_portion_cashrich su_portion_large su_portion_leverage l.su_portion_capitalintensive l.su_portion_cashrich l.su_portion_large l.su_portion_leverage, absorb(id year)
reghdfe d_FV08GH_dhs_rev_growth_mn d_su_portion_capitalintensive d_su_portion_cashrich d_su_portion_large d_su_portion_leverage l.d_su_portion_capitalintensive l.d_su_portion_cashrich l.d_su_portion_large l.d_su_portion_leverage, absorb(id year)



*************************************
************ ALL FIRMS **************
*************************************

use "$sub_dr\Vars\Mac_sec_vars.dta", clear
rename mac_sec Sectorcode

merge 1:1 country year Sectorcode using "$sub_dr\Startups\Reg_type_base.dta"
keep if _merge==3
drop _merge

egen id=group(country Sectorcode)
xtset id year

************************************
************************************

label var FD01_safe_mn "Financial constraint (%)"
label var FV08GH_dhs_rev_growth_mn "Revenues growth (%)"
label var LV21GH_dhs_labor_growth_mn "Employment growth (%)"
label var PV03G1_lprod_va_mn "Productivity growth (%)"
label var CV37_hhi_rk_sam_M_tot "Capital HHI"
label var CV13_hhi_ifa_sam_M_tot "Intangibles HHI"

reghdfe start_up_sh FD01_safe_mn l.FD01_safe_mn, absorb(id year) 
outreg2 using "$sub_dr\Output\Reg_safe.doc", replace ctitle(All) addtext(Country-Macrosector FE, YES, Year FE, YES) dec(4) label adjr2 
ivregress gmm start_up_sh i.id i.year (FD01_safe_mn l.FD01_safe_mn=l2.FD01_safe_mn l3.FD01_safe_mn)
outreg2 using "$sub_dr\Output\Reg_iv_safe.doc", replace ctitle(All) addtext(Country-Macrosector FE, YES, Year FE, YES) dec(4) label adjr2 

reghdfe start_up_sh FV08GH_dhs_rev_growth_mn l.FV08GH_dhs_rev_growth_mn, absorb(id year)
outreg2 using "$sub_dr\Output\Reg_rev.doc", replace ctitle(All) addtext(Country-Macrosector FE, YES, Year FE, YES) dec(4) label adjr2 
ivregress gmm start_up_sh i.id i.year (FV08GH_dhs_rev_growth_mn l.FV08GH_dhs_rev_growth_mn=l2.FV08GH_dhs_rev_growth_mn l3.FV08GH_dhs_rev_growth_mn)
outreg2 using "$sub_dr\Output\Reg_iv_rev.doc", replace ctitle(All) addtext(Country-Macrosector FE, YES, Year FE, YES) dec(4) label adjr2 

reghdfe start_up_sh LV21GH_dhs_labor_growth_mn l.LV21GH_dhs_labor_growth_mn, absorb(id year)
outreg2 using "$sub_dr\Output\Reg_lab.doc", replace ctitle(All) addtext(Country-Macrosector FE, YES, Year FE, YES) dec(4) label adjr2 
ivregress gmm start_up_sh i.id i.year (LV21GH_dhs_labor_growth_mn l.LV21GH_dhs_labor_growth_mn=l2.LV21GH_dhs_labor_growth_mn l3.LV21GH_dhs_labor_growth_mn)
outreg2 using "$sub_dr\Output\Reg_iv_lab.doc", replace ctitle(All) addtext(Country-Macrosector FE, YES, Year FE, YES) dec(4) label adjr2 

reghdfe start_up_sh PV03G1_lprod_va_mn l.PV03G1_lprod_va_mn, absorb(id year)
outreg2 using "$sub_dr\Output\Reg_lprod.doc", replace ctitle(All) addtext(Country-Macrosector FE, YES, Year FE, YES) dec(4) label adjr2 
ivregress gmm start_up_sh i.id i.year (PV03G1_lprod_va_mn l.PV03G1_lprod_va_mn=l2.PV03G1_lprod_va_mn l3.PV03G1_lprod_va_mn)
outreg2 using "$sub_dr\Output\Reg_iv_lprod.doc", replace ctitle(All) addtext(Country-Macrosector FE, YES, Year FE, YES) dec(4) label  

reghdfe start_up_sh CV37_hhi_rk_sam_M_tot l.CV37_hhi_rk_sam_M_tot, absorb(id year)
outreg2 using "$sub_dr\Output\Reg_khhi.doc", replace ctitle(All) addtext(Country-Macrosector FE, YES, Year FE, YES) dec(4) label adjr2 
ivregress gmm start_up_sh i.id i.year (CV37_hhi_rk_sam_M_tot l.CV37_hhi_rk_sam_M_tot=l2.CV37_hhi_rk_sam_M_tot l3.CV37_hhi_rk_sam_M_tot)
outreg2 using "$sub_dr\Output\Reg_iv_khhi.doc", replace ctitle(All) addtext(Country-Macrosector FE, YES, Year FE, YES) dec(4) label  

reghdfe start_up_sh CV13_hhi_ifa_sam_M_tot l.CV13_hhi_ifa_sam_M_tot, absorb(id year)
outreg2 using "$sub_dr\Output\Reg_ihhi.doc", replace ctitle(All) addtext(Country-Macrosector FE, YES, Year FE, YES) dec(4) label adjr2 
ivregress gmm start_up_sh i.id i.year (CV13_hhi_ifa_sam_M_tot l.CV13_hhi_ifa_sam_M_tot=l2.CV13_hhi_ifa_sam_M_tot l3.CV13_hhi_ifa_sam_M_tot)
outreg2 using "$sub_dr\Output\Reg_iv_ihhi.doc", replace ctitle(All) addtext(Country-Macrosector FE, YES, Year FE, YES) dec(4) label  


foreach t in basic capitalintensive cashrich large leverage {
	
reghdfe start_up_sh_`t' FD01_safe_mn l.FD01_safe_mn, absorb(id year) 
outreg2 using "$sub_dr\Output\Reg_safe.doc", append ctitle(`t') addtext(Country-Macrosector FE, YES, Year FE, YES) dec(4) label adjr2 
ivregress gmm start_up_sh_`t' i.id i.year (FD01_safe_mn l.FD01_safe_mn=l2.FD01_safe_mn l3.FD01_safe_mn)
outreg2 using "$sub_dr\Output\Reg_iv_safe.doc", append ctitle(`t') addtext(Country-Macrosector FE, YES, Year FE, YES) dec(4) label adjr2

reghdfe start_up_sh_`t' FV08GH_dhs_rev_growth_mn l.FV08GH_dhs_rev_growth_mn, absorb(id year)
outreg2 using "$sub_dr\Output\Reg_rev.doc", append ctitle(`t') addtext(Country-Macrosector FE, YES, Year FE, YES) dec(4) label adjr2 
ivregress gmm start_up_sh_`t' i.id i.year (FV08GH_dhs_rev_growth_mn l.FV08GH_dhs_rev_growth_mn=l2.FV08GH_dhs_rev_growth_mn l3.FV08GH_dhs_rev_growth_mn)
outreg2 using "$sub_dr\Output\Reg_iv_rev.doc", append ctitle(`t') addtext(Country-Macrosector FE, YES, Year FE, YES) dec(4) label adjr2 

reghdfe start_up_sh_`t' LV21GH_dhs_labor_growth_mn l.LV21GH_dhs_labor_growth_mn, absorb(id year)
outreg2 using "$sub_dr\Output\Reg_lab.doc", append ctitle(`t') addtext(Country-Macrosector FE, YES, Year FE, YES) dec(4) label adjr2
ivregress gmm start_up_sh_`t' i.id i.year (LV21GH_dhs_labor_growth_mn l.LV21GH_dhs_labor_growth_mn=l2.LV21GH_dhs_labor_growth_mn l3.LV21GH_dhs_labor_growth_mn)
outreg2 using "$sub_dr\Output\Reg_iv_lab.doc", append ctitle(`t') addtext(Country-Macrosector FE, YES, Year FE, YES) dec(4) label adjr2  

reghdfe start_up_sh_`t' PV03G1_lprod_va_mn l.PV03G1_lprod_va_mn, absorb(id year)
outreg2 using "$sub_dr\Output\Reg_lprod.doc", append ctitle(`t') addtext(Country-Macrosector FE, YES, Year FE, YES) dec(4) label adjr2 
ivregress gmm start_up_sh_`t' i.id i.year (PV03G1_lprod_va_mn l.PV03G1_lprod_va_mn=l2.PV03G1_lprod_va_mn l3.PV03G1_lprod_va_mn)
outreg2 using "$sub_dr\Output\Reg_iv_lprod.doc", append ctitle(`t') addtext(Country-Macrosector FE, YES, Year FE, YES) dec(4) label

reghdfe start_up_sh_`t' CV37_hhi_rk_sam_M_tot l.CV37_hhi_rk_sam_M_tot, absorb(id year)
outreg2 using "$sub_dr\Output\Reg_khhi.doc", append ctitle(`t') addtext(Country-Macrosector FE, YES, Year FE, YES) dec(4) label adjr2 
ivregress gmm start_up_sh_`t' i.id i.year (CV37_hhi_rk_sam_M_tot l.CV37_hhi_rk_sam_M_tot=l2.CV37_hhi_rk_sam_M_tot l3.CV37_hhi_rk_sam_M_tot)
outreg2 using "$sub_dr\Output\Reg_iv_khhi.doc", append ctitle(`t') addtext(Country-Macrosector FE, YES, Year FE, YES) dec(4) label 

reghdfe start_up_sh_`t' CV13_hhi_ifa_sam_M_tot l.CV13_hhi_ifa_sam_M_tot, absorb(id year)
outreg2 using "$sub_dr\Output\Reg_ihhi.doc", append ctitle(`t') addtext(Country-Macrosector FE, YES, Year FE, YES) dec(4) label adjr2 
ivregress gmm start_up_sh_`t' i.id i.year (CV13_hhi_ifa_sam_M_tot l.CV13_hhi_ifa_sam_M_tot=l2.CV13_hhi_ifa_sam_M_tot l3.CV13_hhi_ifa_sam_M_tot)
outreg2 using "$sub_dr\Output\Reg_iv_ihhi.doc", append ctitle(`t') addtext(Country-Macrosector FE, YES, Year FE, YES) dec(4) label 

}



************************************
************************************
