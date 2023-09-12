clear all
cap restore
cap log close
set more off

*** This code performs computations in Section 2 (plus some additional ones like shift-share analysis)

global main_dr "C:\Users\Marco\Desktop\CompNet 2023" // Set the main directory here
global data_dr "9th Vintage" // Set the input data directory here
global sub_dr "GVC Analysis" // Set the sub-directory here

cd "$main_dr\\$sub_dr"

capture noisily mkdir "Shift_share"

use "IOTs\Trade_TOT_NACE.dta", clear

keep if country=="BEL" | country=="HRV" | country=="CZE" | country=="DNK" | country=="FIN" | country=="FRA" | country=="DEU" | country=="HUN" | country=="ITA" | country=="LVA" | country=="LTU" | country=="MLT" | country=="NLD" | country=="POL" | country=="PRT" | country=="ROU" | country=="SVK" | country=="SVN" | country=="ESP" | country=="SWE" | country=="CHE"

keep if country_partner=="BEL" | country_partner=="HRV" | country_partner=="CZE" | country_partner=="DNK" | country_partner=="FIN" | country_partner=="FRA" | country_partner=="DEU" | country_partner=="HUN" | country_partner=="ITA" | country_partner=="LVA" | country_partner=="LTU" | country_partner=="MLT" | country_partner=="NLD" | country_partner=="POL" | country_partner=="PRT" | country_partner=="ROU" | country_partner=="SVK" | country_partner=="SVN" | country_partner=="ESP" | country_partner=="SWE" | country_partner=="CHE"

replace country="Belgium" if country=="BEL"
replace country="Croatia" if country=="HRV"
replace country="Czech Republic" if country=="CZE"
replace country="Denmark" if country=="DNK"
replace country="Finland" if country=="FIN"
replace country="France" if country=="FRA"
replace country="Germany" if country=="DEU"
replace country="Hungary" if country=="HUN"
replace country="Italy" if country=="ITA"
replace country="Latvia" if country=="LVA"
replace country="Lithuania" if country=="LTU"
replace country="Malta" if country=="MLT"
replace country="Netherlands" if country=="NLD"
replace country="Poland" if country=="POL"
replace country="Portugal" if country=="PRT"
replace country="Romania" if country=="ROU"
replace country="Slovakia" if country=="SVK"
replace country="Slovenia" if country=="SVN"
replace country="Spain" if country=="ESP"
replace country="Sweden" if country=="SWE"
replace country="Switzerland" if country=="CHE"

replace country_partner="Belgium" if country_partner=="BEL"
replace country_partner="Croatia" if country_partner=="HRV"
replace country_partner="Czech Republic" if country_partner=="CZE"
replace country_partner="Denmark" if country_partner=="DNK"
replace country_partner="Finland" if country_partner=="FIN"
replace country_partner="France" if country_partner=="FRA"
replace country_partner="Germany" if country_partner=="DEU"
replace country_partner="Hungary" if country_partner=="HUN"
replace country_partner="Italy" if country_partner=="ITA"
replace country_partner="Latvia" if country_partner=="LVA"
replace country_partner="Lithuania" if country_partner=="LTU"
replace country_partner="Malta" if country_partner=="MLT"
replace country_partner="Netherlands" if country_partner=="NLD"
replace country_partner="Poland" if country_partner=="POL"
replace country_partner="Portugal" if country_partner=="PRT"
replace country_partner="Romania" if country_partner=="ROU"
replace country_partner="Slovakia" if country_partner=="SVK"
replace country_partner="Slovenia" if country_partner=="SVN"
replace country_partner="Spain" if country_partner=="ESP"
replace country_partner="Sweden" if country_partner=="SWE"
replace country_partner="Switzerland" if country_partner=="CHE"

rename industry* macro_sector*
tostring macro_sector, replace force
tostring macro_sector_partner, replace force

bys year country macro_sector: egen tot_output=sum(export)

foreach f in export import trade {
bys year country macro_sector: egen tot_`f'=sum(`f') if country!=country_partner
bys year country macro_sector: egen tot_`f'_l=mean(tot_`f')
gen `f'GVC_share=tot_`f'_l/tot_output
}
drop tot_*

drop if country==country_partner

foreach f in export import {
bys year country macro_sector: egen tot_`f'=sum(`f')
gen share_`f'=`f'/tot_`f'
}

joinby year country macro_sector using "TFP\TFP_PEj0_ln_tfp_1.dta", unmatched(both)
keep if _merge==3
drop _merge

joinby year country_partner macro_sector_partner using "TFP\Prt_TFP_PEj0_ln_tfp_1.dta", unmatched(both)
keep if _merge==3
drop _merge

sort year country macro_sector country_partner macro_sector_partner

foreach f in export import {
bys year country macro_sector: egen tot_share_`f'=sum(share_`f')
}
keep if tot_share_export>=0.5
keep if tot_share_import>=0.5
drop tot_* share_*

foreach f in export import {
bys year country macro_sector: egen tot_`f'=sum(`f')
gen share_`f'=`f'/tot_`f'
gen sq_share_`f'=(share_`f')^2

gen wg`f'_PEj0_ln_tfp_1_loggr=share_`f'*Prt_PEj0_ln_tfp_1_loggr_Frontier
gen wg`f'_PV03_lnlprod_va_mn=share_`f'*Prt_PV03_lnlprod_va_mn_Frontier

bys year country macro_sector: egen `f'_GVC_PEj0_ln_tfp_1_loggr=sum(wg`f'_PEj0_ln_tfp_1_loggr)
bys year country macro_sector: egen `f'_GVC_PV03_lnlprod_va_mn=sum(wg`f'_PV03_lnlprod_va_mn)
bys year country macro_sector: egen `f'_HHI=sum(sq_share_`f')
drop wg*
}

collapse (mean) PEj0_ln_tfp_1_loggr_Frontier PV03_lnlprod_va_mn_Frontier PEj0_ln_tfp_1_loggr_Laggard PV03_lnlprod_va_mn_Laggard PEj0_ln_tfp_1_loggr_Mid_prod PV03_lnlprod_va_mn_Mid_prod *GVC_PEj0_ln_tfp_1_loggr *GVC_PV03_lnlprod_va_mn *GVC_share *_HHI, by(year country macro_sector)

sort year country macro_sector

egen id=group(country macro_sector)
xtset id year

foreach f in export import {
foreach pct in Frontier Mid_prod Laggard {
gen catch_up_`f'GVC_`pct'=(log(`f'_GVC_PV03_lnlprod_va_mn/PV03_lnlprod_va_mn_`pct'))*100
gen lag_catch_up_`f'GVC_`pct'=l.catch_up_`f'GVC_`pct'
}	
}

foreach pct in Mid_prod Laggard {
gen catch_up_Front_`pct'=(log(PV03_lnlprod_va_mn_Frontier/PV03_lnlprod_va_mn_`pct'))*100
gen lag_catch_up_Front_`pct'=l.catch_up_Front_`pct'
}

joinby year country macro_sector using "TFP\Lab_hor_PEj0_ln_tfp_1.dta", unmatched(both)
keep if _merge==3
drop _merge id

sort year country macro_sector

egen id=group(country macro_sector)
xtset id year

foreach pct in Frontier Mid_prod Laggard {
gen lag_LV21_l_tot_`pct'=l.LV21_l_tot_`pct'
}

gen LV21_l_tot_MS=LV21_l_tot_Frontier+LV21_l_tot_Laggard+LV21_l_tot_Mid_prod
gen lag_LV21_l_tot_MS=l.LV21_l_tot_Frontier+l.LV21_l_tot_Laggard+l.LV21_l_tot_Mid_prod
gen lag_FV18_rva_tot_MS=l.FV18_rva_tot_Frontier+l.FV18_rva_tot_Laggard+l.FV18_rva_tot_Mid_prod
gen lag_FV18_rva_tot_Frontier=l.FV18_rva_tot_Frontier
gen lag_FV18_rva_tot_Mid_prod=l.FV18_rva_tot_Mid_prod
gen lag_FV18_rva_tot_Laggard=l.FV18_rva_tot_Laggard

gen PEj0_ln_tfp_1_loggr_MS=(l.LV21_l_tot_Frontier/lag_LV21_l_tot_MS)*PEj0_ln_tfp_1_loggr_Frontier+(l.LV21_l_tot_Laggard/lag_LV21_l_tot_MS)*PEj0_ln_tfp_1_loggr_Laggard+(l.LV21_l_tot_Mid_prod/lag_LV21_l_tot_MS)*PEj0_ln_tfp_1_loggr_Mid_prod

gen PV03_lnlprod_va_mn_MS=(l.LV21_l_tot_Frontier/lag_LV21_l_tot_MS)*PV03_lnlprod_va_mn_Frontier+(l.LV21_l_tot_Laggard/lag_LV21_l_tot_MS)*PV03_lnlprod_va_mn_Laggard+(l.LV21_l_tot_Mid_prod/lag_LV21_l_tot_MS)*PV03_lnlprod_va_mn_Mid_prod

foreach f in export import {
gen chg_`f'GVC_share=`f'GVC_share-l.`f'GVC_share
}

foreach f in export import {
gen catch_up_`f'GVC_MS=(log(`f'_GVC_PV03_lnlprod_va_mn/PV03_lnlprod_va_mn_MS))*100
gen lag_catch_up_`f'GVC_MS=l.catch_up_`f'GVC_MS
}	

gen d_gfc=(year>=2008 & year<=2010)
gen d_covid=(year==2020)

*********************************************************
rename *_catch_up_* *_ctup_*

foreach p in Frontier Mid_prod Laggard {
gen gfPEj0_ln_tfp_1_loggr_`p'=PEj0_ln_tfp_1_loggr_`p'*d_gfc
gen cvPEj0_ln_tfp_1_loggr_`p'=PEj0_ln_tfp_1_loggr_`p'*d_covid
}

foreach p in Mid_prod Laggard {
	gen gflag_ctup_Front_`p'=lag_ctup_Front_`p'*d_gfc
	gen cvlag_ctup_Front_`p'=lag_ctup_Front_`p'*d_covid
	}	

foreach f in export import {
	foreach v in `f'_GVC_PEj0_ln_tfp_1_loggr chg_`f'GVC_share {
	gen gf`v'=`v'*d_gfc
    gen cv`v'=`v'*d_covid	
	}
	foreach p in Frontier MS Mid_prod Laggard {
	gen gflag_ctup_`f'GVC_`p'=lag_ctup_`f'GVC_`p'*d_gfc
	gen cvlag_ctup_`f'GVC_`p'=lag_ctup_`f'GVC_`p'*d_covid
	}	
}

label var PEj0_ln_tfp_1_loggr_Frontier "TFP growth national frontier"
label var PEj0_ln_tfp_1_loggr_Mid_prod "TFP growth mid-productive firms"
label var PEj0_ln_tfp_1_loggr_Laggard "TFP growth laggard firms"
label var lag_ctup_importGVC_Frontier "Lagged labor productivity gap GVC (import) to national frontier"
label var lag_ctup_exportGVC_Frontier "Lagged labor productivity gap GVC (export) to national frontier"
label var lag_ctup_importGVC_Mid_prod "Lagged labor productivity gap GVC (import) to middle"
label var lag_ctup_exportGVC_Mid_prod "Lagged labor productivity gap GVC (export) to middle"
label var lag_ctup_importGVC_Laggard "Lagged labor productivity gap GVC (import) to laggards"
label var lag_ctup_exportGVC_Laggard "Lagged labor productivity gap GVC (export) to laggards"
label var import_GVC_PEj0_ln_tfp_1_loggr "TFP growth GVC (import) frontier"
label var export_GVC_PEj0_ln_tfp_1_loggr "TFP growth GVC (export) frontier"
label var import_HHI"HHI import"
label var export_HHI "HHI export"
label var lag_ctup_Front_Mid_prod "Lagged labor productivity gap national frontier to middle"
label var lag_ctup_Front_Laggard "Lagged labor productivity gap national frontier to laggards"
label var PEj0_ln_tfp_1_loggr_MS "TFP growth"
label var lag_ctup_importGVC_MS "Lagged labor productivity gap with GVC (import)"
label var lag_ctup_exportGVC_MS "Lagged labor productivity gap with GVC (export)"
label var chg_importGVC_share "GVC (import) participation growth"
label var chg_exportGVC_share "GVC (export) participation growth"
label var gfimport_GVC_PEj0_ln_tfp_1_loggr "TFP growth GVC (import) frontier × 2008-2010 dummy"
label var gfexport_GVC_PEj0_ln_tfp_1_loggr "TFP growth GVC (export) frontier × 2008-2010 dummy"
label var cvimport_GVC_PEj0_ln_tfp_1_loggr "TFP growth GVC (import) frontier × 2020 dummy"
label var cvexport_GVC_PEj0_ln_tfp_1_loggr "TFP growth GVC (export) frontier × 2020 dummy"
label var gfchg_importGVC_share "GVC (import) participation growth × 2008-2010 dummy"
label var gfchg_exportGVC_share "GVC (export) participation growth × 2008-2010 dummy"
label var gflag_ctup_importGVC_Frontier "Lagged labor productivity gap GVC (import) to national frontier × 2008-2010 dummy"
label var cvlag_ctup_importGVC_Frontier "Lagged labor productivity gap GVC (import) to national frontier × 2020 dummy"
label var gflag_ctup_exportGVC_Frontier "Lagged labor productivity gap GVC (export) to national frontier × 2008-2010 dummy"
label var cvlag_ctup_exportGVC_Frontier "Lagged labor productivity gap GVC (export) to national frontier × 2020 dummy"
label var gflag_ctup_importGVC_MS "Lagged labor productivity gap with GVC (import) × 2008-2010 dummy"
label var cvlag_ctup_importGVC_MS "Lagged labor productivity gap with GVC (import) × 2020 dummy"
label var gflag_ctup_exportGVC_MS "Lagged labor productivity gap with GVC (export) × 2008-2010 dummy"
label var cvlag_ctup_exportGVC_MS "Lagged labor productivity gap with GVC (export) × 2020 dummy"
label var gfPEj0_ln_tfp_1_loggr_Frontier "TFP growth national frontier × 2008-2010 dummy"
label var cvPEj0_ln_tfp_1_loggr_Frontier "TFP growth national frontier × 2020 dummy"
label var gfPEj0_ln_tfp_1_loggr_Mid_prod "TFP growth mid-productive firms × 2008-2010 dummy"
label var cvPEj0_ln_tfp_1_loggr_Mid_prod "TFP growth mid-productive firms × 2020 dummy"
label var gfPEj0_ln_tfp_1_loggr_Laggard "TFP growth laggard firms × 2008-2010 dummy"
label var cvPEj0_ln_tfp_1_loggr_Laggard "TFP growth laggard firms × 2020 dummy"
label var gflag_ctup_Front_Mid_prod "Lagged labor productivity gap national frontier to middle × 2008-2010 dummy"
label var cvlag_ctup_Front_Mid_prod "Lagged labor productivity gap national frontier to middle × 2020 dummy"
label var gflag_ctup_Front_Laggard "Lagged labor productivity gap national frontier to laggards × 2008-2010 dummy"
label var cvlag_ctup_Front_Laggard "Lagged labor productivity gap national frontier to laggards × 2020 dummy"
label var gflag_ctup_importGVC_Mid_prod "Lagged labor productivity gap GVC (import) to middle × 2008-2010 dummy"
label var gflag_ctup_exportGVC_Mid_prod "Lagged labor productivity gap GVC (export) to middle × 2008-2010 dummy"
label var cvlag_ctup_importGVC_Mid_prod "Lagged labor productivity gap GVC (import) to middle × 2020 dummy"
label var cvlag_ctup_exportGVC_Mid_prod "Lagged labor productivity gap GVC (export) to middle × 2020 dummy"
label var gflag_ctup_importGVC_Laggard "Lagged labor productivity gap GVC (import) to laggards × 2008-2010 dummy"
label var gflag_ctup_exportGVC_Laggard "Lagged labor productivity gap GVC (export) to laggards × 2008-2010 dummy"
label var cvlag_ctup_importGVC_Laggard "Lagged labor productivity gap GVC (import) to laggards × 2020 dummy"
label var cvlag_ctup_exportGVC_Laggard "Lagged labor productivity gap GVC (export) to laggards × 2020 dummy"
label var d_gfc "2008-2010 dummy"
label var d_covid "2020 dummy" 

********************************
*****   BASE REGRESSIONS   *****
********************************

* Macro-sector
reghdfe PEj0_ln_tfp_1_loggr_MS import_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_MS chg_importGVC_share d_*, absorb(id) vce(cluster id)
outreg2 using "Regs_new\MSFront_base.doc", replace ctitle(Macro-Sector, Import) addtext() dec(4) label adjr2 

reghdfe PEj0_ln_tfp_1_loggr_MS export_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_MS chg_exportGVC_share d_*, absorb(id) vce(cluster id)
outreg2 using "Regs_new\MSFront_base.doc", append ctitle(Macro-Sector, Export) addtext() dec(4) label adjr2 

reghdfe PEj0_ln_tfp_1_loggr_MS import_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_MS chg_importGVC_share export_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_MS chg_exportGVC_share d_*, absorb(id) vce(cluster id)
/*outreg2 using "Regs_new\MacSec_base.doc", append ctitle(Import and Export) addtext() dec(4) label adjr2 sortvar(import_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_MS chg_importGVC_share export_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_MS chg_exportGVC_share d_gfc d_covid)*/

* Frontier
reghdfe PEj0_ln_tfp_1_loggr_Frontier import_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Frontier chg_importGVC_share d_*, absorb(id) vce(cluster id)
outreg2 using "Regs_new\MSFront_base.doc", append ctitle(Frontier, Import) addtext() dec(4) label adjr2

reghdfe PEj0_ln_tfp_1_loggr_Frontier export_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_Frontier chg_exportGVC_share d_*, absorb(id) vce(cluster id)
outreg2 using "Regs_new\MSFront_base.doc", append ctitle(Frontier, Export) addtext() dec(4) label  adjr2

/*reghdfe PEj0_ln_tfp_1_loggr_Frontier import_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Frontier chg_importGVC_share export_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_Frontier chg_exportGVC_share d_*, absorb(id) vce(cluster id)
outreg2 using "Regs_new\Frontier_base.doc", append ctitle(Import and Export) addtext() dec(4) label adjr2 sortvar(import_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Frontier chg_importGVC_share export_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_Frontier chg_exportGVC_share d_gfc d_covid)*/


* Mid-productive
reghdfe PEj0_ln_tfp_1_loggr_Mid_prod import_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Mid_prod PEj0_ln_tfp_1_loggr_Frontier lag_ctup_Front_Mid_prod chg_importGVC_share d_*, absorb(id) vce(cluster id)
outreg2 using "Regs_new\MidLag_base.doc", replace ctitle(Middle, Import) addtext() dec(4) label adjr2 sortvar(import_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Mid_prod lag_ctup_importGVC_Laggard chg_importGVC_share export_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_Mid_prod lag_ctup_exportGVC_Laggard chg_exportGVC_share PEj0_ln_tfp_1_loggr_Frontier lag_ctup_Front_Mid_prod lag_ctup_Front_Laggard d_gfc d_covid)

reghdfe PEj0_ln_tfp_1_loggr_Mid_prod export_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_Mid_prod PEj0_ln_tfp_1_loggr_Frontier lag_ctup_Front_Mid_prod chg_exportGVC_share d_*, absorb(id) vce(cluster id)
outreg2 using "Regs_new\MidLag_base.doc", append ctitle(Middle, Export) addtext() dec(4) label adjr2 sortvar(import_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Mid_prod lag_ctup_importGVC_Laggard chg_importGVC_share export_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_Mid_prod lag_ctup_exportGVC_Laggard chg_exportGVC_share PEj0_ln_tfp_1_loggr_Frontier lag_ctup_Front_Mid_prod lag_ctup_Front_Laggard d_gfc d_covid)

reghdfe PEj0_ln_tfp_1_loggr_Mid_prod import_GVC_PEj0_ln_tfp_1_loggr export_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Mid_prod lag_ctup_exportGVC_Mid_prod PEj0_ln_tfp_1_loggr_Frontier lag_ctup_Front_Mid_prod chg_importGVC_share chg_exportGVC_share d_*, absorb(id) vce(cluster id)
outreg2 using "Regs_new\MidLag_base.doc", append ctitle(Middle, Import and Export) addtext() dec(4) label adjr2 sortvar(import_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Mid_prod lag_ctup_importGVC_Laggard chg_importGVC_share export_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_Mid_prod lag_ctup_exportGVC_Laggard chg_exportGVC_share PEj0_ln_tfp_1_loggr_Frontier lag_ctup_Front_Mid_prod lag_ctup_Front_Laggard d_gfc d_covid)

* Laggards
reghdfe PEj0_ln_tfp_1_loggr_Laggard import_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Laggard PEj0_ln_tfp_1_loggr_Frontier lag_ctup_Front_Laggard chg_importGVC_share d_*, absorb(id) vce(cluster id)
outreg2 using "Regs_new\MidLag_base.doc", append ctitle(Laggards, Import) addtext() dec(4) label adjr2 sortvar(import_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Mid_prod lag_ctup_importGVC_Laggard chg_importGVC_share export_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_Mid_prod lag_ctup_exportGVC_Laggard chg_exportGVC_share PEj0_ln_tfp_1_loggr_Frontier lag_ctup_Front_Mid_prod lag_ctup_Front_Laggard d_gfc d_covid)

reghdfe PEj0_ln_tfp_1_loggr_Laggard export_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_Laggard PEj0_ln_tfp_1_loggr_Frontier lag_ctup_Front_Laggard chg_exportGVC_share d_*, absorb(id) vce(cluster id)
outreg2 using "Regs_new\MidLag_base.doc", append ctitle(Laggards, Export) addtext() dec(4) label adjr2 sortvar(import_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Mid_prod lag_ctup_importGVC_Laggard chg_importGVC_share export_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_Mid_prod lag_ctup_exportGVC_Laggard chg_exportGVC_share PEj0_ln_tfp_1_loggr_Frontier lag_ctup_Front_Mid_prod lag_ctup_Front_Laggard d_gfc d_covid)

reghdfe PEj0_ln_tfp_1_loggr_Laggard import_GVC_PEj0_ln_tfp_1_loggr export_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Laggard lag_ctup_exportGVC_Laggard PEj0_ln_tfp_1_loggr_Frontier lag_ctup_Front_Laggard chg_importGVC_share chg_exportGVC_share d_*, absorb(id) vce(cluster id)
outreg2 using "Regs_new\MidLag_base.doc", append ctitle(Laggards, Import and Export) addtext() dec(4) label adjr2 sortvar(import_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Mid_prod lag_ctup_importGVC_Laggard chg_importGVC_share export_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_Mid_prod lag_ctup_exportGVC_Laggard chg_exportGVC_share PEj0_ln_tfp_1_loggr_Frontier lag_ctup_Front_Mid_prod lag_ctup_Front_Laggard d_gfc d_covid)


********************************
*****   TIME INTERACTION   *****
*****     REGRESSIONS      *****
******************************** 

* Macro-sector
reghdfe PEj0_ln_tfp_1_loggr_MS import_GVC_PEj0_ln_tfp_1_loggr gfimport_GVC_PEj0_ln_tfp_1_loggr cvimport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_MS chg_importGVC_share d_*, absorb(id) vce(cluster id) resid
outreg2 using "Regs_new\MSFront_time.doc", replace ctitle(Macro-Sector, Import) addtext() dec(4) label adjr2 sortvar(import_GVC_PEj0_ln_tfp_1_loggr gfimport_GVC_PEj0_ln_tfp_1_loggr cvimport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_MS chg_importGVC_share export_GVC_PEj0_ln_tfp_1_loggr gfexport_GVC_PEj0_ln_tfp_1_loggr cvexport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_MS chg_exportGVC_share d_gfc d_covid)

{
preserve
sort id year
keep if year==2019 | year==2020

predict pred, xbd // Prediction
predict err, res // Epsilon
gen actual=PEj0_ln_tfp_1_loggr_MS // Actual
gen actual_2=pred+err
gen lag_pred=l.pred // Prediction t-1
gen lag_err=l.err // Epsilon t-1
gen lag_actual=l.PEj0_ln_tfp_1_loggr_MS  // Actual t-1
gen lag_actual_2=l.actual_2  // Actual t-1
gen cng_pred= pred-lag_pred // Delta Prediction
gen cng_err= err-lag_err // Delta Epsilon
gen cng_actual=actual-lag_actual  // Delta Actual
gen cng_actual_2=actual_2-lag_actual_2

gen coef_TFP_GVC=_b[import_GVC_PEj0_ln_tfp_1_loggr]
gen coefcng_TFP_GVC=_b[cvimport_GVC_PEj0_ln_tfp_1_loggr]
gen coef_gap_GVC=_b[lag_ctup_importGVC_MS]
gen coef_part_GVC=_b[chg_importGVC_share]

gen TFP_GVC=import_GVC_PEj0_ln_tfp_1_loggr
gen lag_TFP_GVC=l.import_GVC_PEj0_ln_tfp_1_loggr
gen cng_TFP_GVC=TFP_GVC-lag_TFP_GVC

gen gap_GVC=lag_ctup_importGVC_MS
gen lag_gap_GVC=l.lag_ctup_importGVC_MS
gen cng_gap_GVC=gap_GVC-lag_gap_GVC

gen part_GVC=chg_importGVC_share
gen lag_part_GVC=l.chg_importGVC_share
gen cng_part_GVC=part_GVC-lag_part_GVC

gen coef_cov=_b[d_covid]
gen cng_cov=1

gen t1_TFP_GVC=coefcng_TFP_GVC*lag_TFP_GVC
gen t2_TFP_GVC=coef_TFP_GVC*cng_TFP_GVC
gen t3_TFP_GVC=coefcng_TFP_GVC*cng_TFP_GVC

gen t2_gap_GVC=coef_gap_GVC*cng_gap_GVC
gen t2_part_GVC=coef_part_GVC*cng_part_GVC
gen t2_cov=coef_cov*cng_cov

gen constr_chg=t1_TFP_GVC+t2_TFP_GVC+t3_TFP_GVC+t2_gap_GVC+t2_part_GVC+t2_cov+cng_err

keep if year==2020
drop if constr_chg==.

browse cng_actual cng_actual_2 constr_chg

collapse (mean) cng_pred cng_actual cng_actual_2 constr_chg t1_* t2_* t3_* cng_err [aweight=lag_FV18_rva_tot_MS] 

rename * *MS_imp
gen a="a"
reshape long cng_pred cng_actual cng_actual_2 constr_chg t1_TFP_GVC t2_TFP_GVC t2_gap_GVC t2_part_GVC t2_cov t3_TFP_GVC cng_err, i(a) j(group) s
drop a

save "Shift_share/MS_imp.dta", replace

restore
}

reghdfe PEj0_ln_tfp_1_loggr_MS export_GVC_PEj0_ln_tfp_1_loggr gfexport_GVC_PEj0_ln_tfp_1_loggr cvexport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_MS chg_exportGVC_share d_*, absorb(id) vce(cluster id) resid
outreg2 using "Regs_new\MSFront_time.doc", append ctitle(Macro-Sector, Export) addtext() dec(4) label adjr2 sortvar(import_GVC_PEj0_ln_tfp_1_loggr gfimport_GVC_PEj0_ln_tfp_1_loggr cvimport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_MS chg_importGVC_share export_GVC_PEj0_ln_tfp_1_loggr gfexport_GVC_PEj0_ln_tfp_1_loggr cvexport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_MS chg_exportGVC_share d_gfc d_covid)

{
preserve
sort id year
keep if year==2019 | year==2020

predict pred, xbd // Prediction
predict err, res // Epsilon
gen actual=PEj0_ln_tfp_1_loggr_MS // Actual
gen actual_2=pred+err
gen lag_pred=l.pred // Prediction t-1
gen lag_err=l.err // Epsilon t-1
gen lag_actual=l.PEj0_ln_tfp_1_loggr_MS  // Actual t-1
gen lag_actual_2=l.actual_2  // Actual t-1
gen cng_pred= pred-lag_pred // Delta Prediction
gen cng_err= err-lag_err // Delta Epsilon
gen cng_actual=actual-lag_actual  // Delta Actual
gen cng_actual_2=actual_2-lag_actual_2

gen coef_TFP_GVC=_b[export_GVC_PEj0_ln_tfp_1_loggr]
gen coefcng_TFP_GVC=_b[cvexport_GVC_PEj0_ln_tfp_1_loggr]
gen coef_gap_GVC=_b[lag_ctup_exportGVC_MS]
gen coef_part_GVC=_b[chg_exportGVC_share]

gen TFP_GVC=export_GVC_PEj0_ln_tfp_1_loggr
gen lag_TFP_GVC=l.export_GVC_PEj0_ln_tfp_1_loggr
gen cng_TFP_GVC=TFP_GVC-lag_TFP_GVC

gen gap_GVC=lag_ctup_exportGVC_MS
gen lag_gap_GVC=l.lag_ctup_exportGVC_MS
gen cng_gap_GVC=gap_GVC-lag_gap_GVC

gen part_GVC=chg_exportGVC_share
gen lag_part_GVC=l.chg_exportGVC_share
gen cng_part_GVC=part_GVC-lag_part_GVC

gen coef_cov=_b[d_covid]
gen cng_cov=1

gen t1_TFP_GVC=coefcng_TFP_GVC*lag_TFP_GVC
gen t2_TFP_GVC=coef_TFP_GVC*cng_TFP_GVC
gen t3_TFP_GVC=coefcng_TFP_GVC*cng_TFP_GVC

gen t2_gap_GVC=coef_gap_GVC*cng_gap_GVC
gen t2_part_GVC=coef_part_GVC*cng_part_GVC
gen t2_cov=coef_cov*cng_cov

gen constr_chg=t1_TFP_GVC+t2_TFP_GVC+t3_TFP_GVC+t2_gap_GVC+t2_part_GVC+t2_cov+cng_err

keep if year==2020
drop if constr_chg==.

browse cng_actual cng_actual_2 constr_chg

collapse (mean) cng_pred cng_actual cng_actual_2 constr_chg t1_* t2_* t3_* cng_err [aweight=lag_FV18_rva_tot_MS] 

rename * *MS_exp
gen a="a"
reshape long cng_pred cng_actual cng_actual_2 constr_chg t1_TFP_GVC t2_TFP_GVC t2_gap_GVC t2_part_GVC t2_cov t3_TFP_GVC cng_err, i(a) j(group) s
drop a

save "Shift_share/MS_exp.dta", replace

restore
}

/*
reghdfe PEj0_ln_tfp_1_loggr_MS import_GVC_PEj0_ln_tfp_1_loggr gfimport_GVC_PEj0_ln_tfp_1_loggr cvimport_GVC_PEj0_ln_tfp_1_loggr export_GVC_PEj0_ln_tfp_1_loggr gfexport_GVC_PEj0_ln_tfp_1_loggr cvexport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_MS lag_ctup_exportGVC_MS chg_importGVC_share chg_exportGVC_share d_*, absorb(id) vce(cluster id)
outreg2 using "Regs_new\MacSec_time.doc", append ctitle(Import and Export) addtext() dec(4) label adjr2 sortvar(import_GVC_PEj0_ln_tfp_1_loggr gfimport_GVC_PEj0_ln_tfp_1_loggr cvimport_GVC_PEj0_ln_tfp_1_loggr export_GVC_PEj0_ln_tfp_1_loggr gfexport_GVC_PEj0_ln_tfp_1_loggr cvexport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_MS lag_ctup_exportGVC_MS chg_importGVC_share chg_exportGVC_share d_gfc d_covid)
*/

* Frontier
reghdfe PEj0_ln_tfp_1_loggr_Frontier import_GVC_PEj0_ln_tfp_1_loggr gfimport_GVC_PEj0_ln_tfp_1_loggr cvimport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Frontier chg_importGVC_share d_*, absorb(id) vce(cluster id) resid
outreg2 using "Regs_new\MSFront_time.doc", append ctitle(Frontier, Import) addtext() dec(4) label adjr2 sortvar(import_GVC_PEj0_ln_tfp_1_loggr gfimport_GVC_PEj0_ln_tfp_1_loggr cvimport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Frontier chg_importGVC_share export_GVC_PEj0_ln_tfp_1_loggr gfexport_GVC_PEj0_ln_tfp_1_loggr cvexport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_Frontier  chg_exportGVC_share d_gfc d_covid)

{
preserve
sort id year
keep if year==2019 | year==2020

predict pred, xbd // Prediction
predict err, res // Epsilon
gen actual=PEj0_ln_tfp_1_loggr_Frontier // Actual
gen actual_2=pred+err
gen lag_pred=l.pred // Prediction t-1
gen lag_err=l.err // Epsilon t-1
gen lag_actual=l.PEj0_ln_tfp_1_loggr_Frontier  // Actual t-1
gen lag_actual_2=l.actual_2  // Actual t-1
gen cng_pred= pred-lag_pred // Delta Prediction
gen cng_err= err-lag_err // Delta Epsilon
gen cng_actual=actual-lag_actual  // Delta Actual
gen cng_actual_2=actual_2-lag_actual_2

gen coef_TFP_GVC=_b[import_GVC_PEj0_ln_tfp_1_loggr]
gen coefcng_TFP_GVC=_b[cvimport_GVC_PEj0_ln_tfp_1_loggr]
gen coef_gap_GVC=_b[lag_ctup_importGVC_Frontier]
gen coef_part_GVC=_b[chg_importGVC_share]

gen TFP_GVC=import_GVC_PEj0_ln_tfp_1_loggr
gen lag_TFP_GVC=l.import_GVC_PEj0_ln_tfp_1_loggr
gen cng_TFP_GVC=TFP_GVC-lag_TFP_GVC

gen gap_GVC=lag_ctup_importGVC_Frontier
gen lag_gap_GVC=l.lag_ctup_importGVC_Frontier
gen cng_gap_GVC=gap_GVC-lag_gap_GVC

gen part_GVC=chg_importGVC_share
gen lag_part_GVC=l.chg_importGVC_share
gen cng_part_GVC=part_GVC-lag_part_GVC

gen coef_cov=_b[d_covid]
gen cng_cov=1

gen t1_TFP_GVC=coefcng_TFP_GVC*lag_TFP_GVC
gen t2_TFP_GVC=coef_TFP_GVC*cng_TFP_GVC
gen t3_TFP_GVC=coefcng_TFP_GVC*cng_TFP_GVC

gen t2_gap_GVC=coef_gap_GVC*cng_gap_GVC
gen t2_part_GVC=coef_part_GVC*cng_part_GVC
gen t2_cov=coef_cov*cng_cov

gen constr_chg=t1_TFP_GVC+t2_TFP_GVC+t3_TFP_GVC+t2_gap_GVC+t2_part_GVC+t2_cov+cng_err

keep if year==2020
drop if constr_chg==.

browse cng_actual cng_actual_2 constr_chg

collapse (mean) cng_pred cng_actual cng_actual_2 constr_chg t1_* t2_* t3_* cng_err [aweight=lag_FV18_rva_tot_Frontier] 

rename * *Frontier_imp
gen a="a"
reshape long cng_pred cng_actual cng_actual_2 constr_chg t1_TFP_GVC t2_TFP_GVC t2_gap_GVC t2_part_GVC t2_cov t3_TFP_GVC cng_err, i(a) j(group) s
drop a

save "Shift_share/Frontier_imp.dta", replace

restore
}

reghdfe PEj0_ln_tfp_1_loggr_Frontier export_GVC_PEj0_ln_tfp_1_loggr gfexport_GVC_PEj0_ln_tfp_1_loggr cvexport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_Frontier chg_exportGVC_share d_*, absorb(id) vce(cluster id) resid
outreg2 using "Regs_new\MSFront_time.doc", append ctitle(Frontier, Export) addtext() dec(4) label adjr2 sortvar(import_GVC_PEj0_ln_tfp_1_loggr gfimport_GVC_PEj0_ln_tfp_1_loggr cvimport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Frontier chg_importGVC_share export_GVC_PEj0_ln_tfp_1_loggr gfexport_GVC_PEj0_ln_tfp_1_loggr cvexport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_Frontier  chg_exportGVC_share d_gfc d_covid)

{
preserve
sort id year
keep if year==2019 | year==2020

predict pred, xbd // Prediction
predict err, res // Epsilon
gen actual=PEj0_ln_tfp_1_loggr_Frontier // Actual
gen actual_2=pred+err
gen lag_pred=l.pred // Prediction t-1
gen lag_err=l.err // Epsilon t-1
gen lag_actual=l.PEj0_ln_tfp_1_loggr_Frontier  // Actual t-1
gen lag_actual_2=l.actual_2  // Actual t-1
gen cng_pred= pred-lag_pred // Delta Prediction
gen cng_err= err-lag_err // Delta Epsilon
gen cng_actual=actual-lag_actual  // Delta Actual
gen cng_actual_2=actual_2-lag_actual_2

gen coef_TFP_GVC=_b[export_GVC_PEj0_ln_tfp_1_loggr]
gen coefcng_TFP_GVC=_b[cvexport_GVC_PEj0_ln_tfp_1_loggr]
gen coef_gap_GVC=_b[lag_ctup_exportGVC_Frontier]
gen coef_part_GVC=_b[chg_exportGVC_share]

gen TFP_GVC=export_GVC_PEj0_ln_tfp_1_loggr
gen lag_TFP_GVC=l.export_GVC_PEj0_ln_tfp_1_loggr
gen cng_TFP_GVC=TFP_GVC-lag_TFP_GVC

gen gap_GVC=lag_ctup_exportGVC_Frontier
gen lag_gap_GVC=l.lag_ctup_exportGVC_Frontier
gen cng_gap_GVC=gap_GVC-lag_gap_GVC

gen part_GVC=chg_exportGVC_share
gen lag_part_GVC=l.chg_exportGVC_share
gen cng_part_GVC=part_GVC-lag_part_GVC

gen coef_cov=_b[d_covid]
gen cng_cov=1

gen t1_TFP_GVC=coefcng_TFP_GVC*lag_TFP_GVC
gen t2_TFP_GVC=coef_TFP_GVC*cng_TFP_GVC
gen t3_TFP_GVC=coefcng_TFP_GVC*cng_TFP_GVC

gen t2_gap_GVC=coef_gap_GVC*cng_gap_GVC
gen t2_part_GVC=coef_part_GVC*cng_part_GVC
gen t2_cov=coef_cov*cng_cov

gen constr_chg=t1_TFP_GVC+t2_TFP_GVC+t3_TFP_GVC+t2_gap_GVC+t2_part_GVC+t2_cov+cng_err

keep if year==2020
drop if constr_chg==.

browse cng_actual cng_actual_2 constr_chg

collapse (mean) cng_pred cng_actual cng_actual_2 constr_chg t1_* t2_* t3_* cng_err [aweight=lag_FV18_rva_tot_Frontier] 

rename * *Frontier_exp
gen a="a"
reshape long cng_pred cng_actual cng_actual_2 constr_chg t1_TFP_GVC t2_TFP_GVC t2_gap_GVC t2_part_GVC t2_cov t3_TFP_GVC cng_err, i(a) j(group) s
drop a

save "Shift_share/Frontier_exp.dta", replace

restore
}

* Mid-productive
reghdfe PEj0_ln_tfp_1_loggr_Mid_prod import_GVC_PEj0_ln_tfp_1_loggr gfimport_GVC_PEj0_ln_tfp_1_loggr cvimport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Mid_prod PEj0_ln_tfp_1_loggr_Frontier gfPEj0_ln_tfp_1_loggr_Frontier cvPEj0_ln_tfp_1_loggr_Frontier lag_ctup_Front_Mid_prod chg_importGVC_share d_*, absorb(id) vce(cluster id) resid
outreg2 using "Regs_new\MidLag_time.doc", replace ctitle(Middle, Import) addtext() dec(4) label adjr2 sortvar(import_GVC_PEj0_ln_tfp_1_loggr gfimport_GVC_PEj0_ln_tfp_1_loggr cvimport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Mid_prod lag_ctup_importGVC_Laggard chg_importGVC_share export_GVC_PEj0_ln_tfp_1_loggr gfexport_GVC_PEj0_ln_tfp_1_loggr cvexport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_Mid_prod lag_ctup_exportGVC_Laggard chg_exportGVC_share PEj0_ln_tfp_1_loggr_Frontier gfPEj0_ln_tfp_1_loggr_Frontier cvPEj0_ln_tfp_1_loggr_Frontier lag_ctup_Front_Mid_prod lag_ctup_Front_Laggard d_gfc d_covid)

{
preserve
sort id year
keep if year==2019 | year==2020

predict pred, xbd // Prediction
predict err, res // Epsilon
gen actual=PEj0_ln_tfp_1_loggr_Mid_prod // Actual
gen actual_2=pred+err
gen lag_pred=l.pred // Prediction t-1
gen lag_err=l.err // Epsilon t-1
gen lag_actual=l.PEj0_ln_tfp_1_loggr_Mid_prod  // Actual t-1
gen lag_actual_2=l.actual_2  // Actual t-1
gen cng_pred= pred-lag_pred // Delta Prediction
gen cng_err= err-lag_err // Delta Epsilon
gen cng_actual=actual-lag_actual  // Delta Actual
gen cng_actual_2=actual_2-lag_actual_2

gen coef_TFP_GVC=_b[import_GVC_PEj0_ln_tfp_1_loggr]
gen coefcng_TFP_GVC=_b[cvimport_GVC_PEj0_ln_tfp_1_loggr]
gen coef_TFP_Front=_b[PEj0_ln_tfp_1_loggr_Frontier]
gen coefcng_TFP_Front=_b[cvPEj0_ln_tfp_1_loggr_Frontier]
gen coef_gap_GVC=_b[lag_ctup_importGVC_Mid_prod]
gen coef_gap_Front=_b[lag_ctup_Front_Mid_prod]
gen coef_part_GVC=_b[chg_importGVC_share]

gen TFP_GVC=import_GVC_PEj0_ln_tfp_1_loggr
gen lag_TFP_GVC=l.import_GVC_PEj0_ln_tfp_1_loggr
gen cng_TFP_GVC=TFP_GVC-lag_TFP_GVC

gen TFP_Front=PEj0_ln_tfp_1_loggr_Frontier
gen lag_TFP_Front=l.PEj0_ln_tfp_1_loggr_Frontier
gen cng_TFP_Front=TFP_Front-lag_TFP_Front

gen gap_GVC=lag_ctup_importGVC_Mid_prod
gen lag_gap_GVC=l.lag_ctup_importGVC_Mid_prod
gen cng_gap_GVC=gap_GVC-lag_gap_GVC

gen gap_Front=lag_ctup_Front_Mid_prod
gen lag_gap_Front=l.lag_ctup_Front_Mid_prod
gen cng_gap_Front=gap_Front-lag_gap_Front

gen part_GVC=chg_importGVC_share
gen lag_part_GVC=l.chg_importGVC_share
gen cng_part_GVC=part_GVC-lag_part_GVC

gen coef_cov=_b[d_covid]
gen cng_cov=1

gen t1_TFP_GVC=coefcng_TFP_GVC*lag_TFP_GVC
gen t2_TFP_GVC=coef_TFP_GVC*cng_TFP_GVC
gen t3_TFP_GVC=coefcng_TFP_GVC*cng_TFP_GVC

gen t1_TFP_Front=coefcng_TFP_Front*lag_TFP_Front
gen t2_TFP_Front=coef_TFP_Front*cng_TFP_Front
gen t3_TFP_Front=coefcng_TFP_Front*cng_TFP_Front

gen t2_gap_GVC=coef_gap_GVC*cng_gap_GVC
gen t2_gap_Front=coef_gap_Front*cng_gap_Front
gen t2_part_GVC=coef_part_GVC*cng_part_GVC
gen t2_cov=coef_cov*cng_cov

gen constr_chg=t1_TFP_GVC+t2_TFP_GVC+t3_TFP_GVC+t1_TFP_Front+t2_TFP_Front+t3_TFP_Front+t2_gap_GVC+t2_gap_Front+t2_part_GVC+t2_cov+cng_err

keep if year==2020
drop if constr_chg==.

browse cng_actual cng_actual_2 constr_chg

collapse (mean) cng_pred cng_actual cng_actual_2 constr_chg t1_* t2_* t3_* cng_err [aweight=lag_FV18_rva_tot_Mid_prod] 

rename * *Mid_prod_imp
gen a="a"
reshape long cng_pred cng_actual cng_actual_2 constr_chg t1_TFP_GVC t1_TFP_Front t2_TFP_GVC t2_TFP_Front t2_gap_GVC t2_gap_Front t2_part_GVC t2_cov t3_TFP_GVC t3_TFP_Front cng_err, i(a) j(group) s
drop a

save "Shift_share/Mid_prod_imp.dta", replace

restore
}

reghdfe PEj0_ln_tfp_1_loggr_Mid_prod export_GVC_PEj0_ln_tfp_1_loggr gfexport_GVC_PEj0_ln_tfp_1_loggr cvexport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_Mid_prod PEj0_ln_tfp_1_loggr_Frontier gfPEj0_ln_tfp_1_loggr_Frontier cvPEj0_ln_tfp_1_loggr_Frontier lag_ctup_Front_Mid_prod chg_exportGVC_share d_*, absorb(id) vce(cluster id) resid
outreg2 using "Regs_new\MidLag_time.doc", append ctitle(Middle, Export) addtext() dec(4) label adjr2 sortvar(import_GVC_PEj0_ln_tfp_1_loggr gfimport_GVC_PEj0_ln_tfp_1_loggr cvimport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Mid_prod lag_ctup_importGVC_Laggard chg_importGVC_share export_GVC_PEj0_ln_tfp_1_loggr gfexport_GVC_PEj0_ln_tfp_1_loggr cvexport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_Mid_prod lag_ctup_exportGVC_Laggard chg_exportGVC_share PEj0_ln_tfp_1_loggr_Frontier gfPEj0_ln_tfp_1_loggr_Frontier cvPEj0_ln_tfp_1_loggr_Frontier lag_ctup_Front_Mid_prod lag_ctup_Front_Laggard d_gfc d_covid)

{
preserve
sort id year
keep if year==2019 | year==2020

predict pred, xbd // Prediction
predict err, res // Epsilon
gen actual=PEj0_ln_tfp_1_loggr_Mid_prod // Actual
gen actual_2=pred+err
gen lag_pred=l.pred // Prediction t-1
gen lag_err=l.err // Epsilon t-1
gen lag_actual=l.PEj0_ln_tfp_1_loggr_Mid_prod  // Actual t-1
gen lag_actual_2=l.actual_2  // Actual t-1
gen cng_pred= pred-lag_pred // Delta Prediction
gen cng_err= err-lag_err // Delta Epsilon
gen cng_actual=actual-lag_actual  // Delta Actual
gen cng_actual_2=actual_2-lag_actual_2

gen coef_TFP_GVC=_b[export_GVC_PEj0_ln_tfp_1_loggr]
gen coefcng_TFP_GVC=_b[cvexport_GVC_PEj0_ln_tfp_1_loggr]
gen coef_TFP_Front=_b[PEj0_ln_tfp_1_loggr_Frontier]
gen coefcng_TFP_Front=_b[cvPEj0_ln_tfp_1_loggr_Frontier]
gen coef_gap_GVC=_b[lag_ctup_exportGVC_Mid_prod]
gen coef_gap_Front=_b[lag_ctup_Front_Mid_prod]
gen coef_part_GVC=_b[chg_exportGVC_share]

gen TFP_GVC=export_GVC_PEj0_ln_tfp_1_loggr
gen lag_TFP_GVC=l.export_GVC_PEj0_ln_tfp_1_loggr
gen cng_TFP_GVC=TFP_GVC-lag_TFP_GVC

gen TFP_Front=PEj0_ln_tfp_1_loggr_Frontier
gen lag_TFP_Front=l.PEj0_ln_tfp_1_loggr_Frontier
gen cng_TFP_Front=TFP_Front-lag_TFP_Front

gen gap_GVC=lag_ctup_exportGVC_Mid_prod
gen lag_gap_GVC=l.lag_ctup_exportGVC_Mid_prod
gen cng_gap_GVC=gap_GVC-lag_gap_GVC

gen gap_Front=lag_ctup_Front_Mid_prod
gen lag_gap_Front=l.lag_ctup_Front_Mid_prod
gen cng_gap_Front=gap_Front-lag_gap_Front

gen part_GVC=chg_exportGVC_share
gen lag_part_GVC=l.chg_exportGVC_share
gen cng_part_GVC=part_GVC-lag_part_GVC

gen coef_cov=_b[d_covid]
gen cng_cov=1

gen t1_TFP_GVC=coefcng_TFP_GVC*lag_TFP_GVC
gen t2_TFP_GVC=coef_TFP_GVC*cng_TFP_GVC
gen t3_TFP_GVC=coefcng_TFP_GVC*cng_TFP_GVC

gen t1_TFP_Front=coefcng_TFP_Front*lag_TFP_Front
gen t2_TFP_Front=coef_TFP_Front*cng_TFP_Front
gen t3_TFP_Front=coefcng_TFP_Front*cng_TFP_Front

gen t2_gap_GVC=coef_gap_GVC*cng_gap_GVC
gen t2_gap_Front=coef_gap_Front*cng_gap_Front
gen t2_part_GVC=coef_part_GVC*cng_part_GVC
gen t2_cov=coef_cov*cng_cov

gen constr_chg=t1_TFP_GVC+t2_TFP_GVC+t3_TFP_GVC+t1_TFP_Front+t2_TFP_Front+t3_TFP_Front+t2_gap_GVC+t2_gap_Front+t2_part_GVC+t2_cov+cng_err

keep if year==2020
drop if constr_chg==.

browse cng_actual cng_actual_2 constr_chg

collapse (mean) cng_pred cng_actual cng_actual_2 constr_chg t1_* t2_* t3_* cng_err [aweight=lag_FV18_rva_tot_Mid_prod] 

rename * *Mid_prod_exp
gen a="a"
reshape long cng_pred cng_actual cng_actual_2 constr_chg t1_TFP_GVC t1_TFP_Front t2_TFP_GVC t2_TFP_Front t2_gap_GVC t2_gap_Front t2_part_GVC t2_cov t3_TFP_GVC t3_TFP_Front cng_err, i(a) j(group) s
drop a

save "Shift_share/Mid_prod_exp.dta", replace

restore
}

* Laggards
reghdfe PEj0_ln_tfp_1_loggr_Laggard import_GVC_PEj0_ln_tfp_1_loggr gfimport_GVC_PEj0_ln_tfp_1_loggr cvimport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Laggard PEj0_ln_tfp_1_loggr_Frontier gfPEj0_ln_tfp_1_loggr_Frontier cvPEj0_ln_tfp_1_loggr_Frontier lag_ctup_Front_Laggard chg_importGVC_share d_*, absorb(id) vce(cluster id) resid
outreg2 using "Regs_new\MidLag_time.doc", append ctitle(Laggards, Import) addtext() dec(4) label adjr2 sortvar(import_GVC_PEj0_ln_tfp_1_loggr gfimport_GVC_PEj0_ln_tfp_1_loggr cvimport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Mid_prod lag_ctup_importGVC_Laggard chg_importGVC_share export_GVC_PEj0_ln_tfp_1_loggr gfexport_GVC_PEj0_ln_tfp_1_loggr cvexport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_Mid_prod lag_ctup_exportGVC_Laggard chg_exportGVC_share PEj0_ln_tfp_1_loggr_Frontier gfPEj0_ln_tfp_1_loggr_Frontier cvPEj0_ln_tfp_1_loggr_Frontier lag_ctup_Front_Mid_prod lag_ctup_Front_Laggard d_gfc d_covid)

{
preserve
sort id year
keep if year==2019 | year==2020

predict pred, xbd // Prediction
predict err, res // Epsilon
gen actual=PEj0_ln_tfp_1_loggr_Laggard // Actual
gen actual_2=pred+err
gen lag_pred=l.pred // Prediction t-1
gen lag_err=l.err // Epsilon t-1
gen lag_actual=l.PEj0_ln_tfp_1_loggr_Laggard  // Actual t-1
gen lag_actual_2=l.actual_2  // Actual t-1
gen cng_pred= pred-lag_pred // Delta Prediction
gen cng_err= err-lag_err // Delta Epsilon
gen cng_actual=actual-lag_actual  // Delta Actual
gen cng_actual_2=actual_2-lag_actual_2

gen coef_TFP_GVC=_b[import_GVC_PEj0_ln_tfp_1_loggr]
gen coefcng_TFP_GVC=_b[cvimport_GVC_PEj0_ln_tfp_1_loggr]
gen coef_TFP_Front=_b[PEj0_ln_tfp_1_loggr_Frontier]
gen coefcng_TFP_Front=_b[cvPEj0_ln_tfp_1_loggr_Frontier]
gen coef_gap_GVC=_b[lag_ctup_importGVC_Laggard]
gen coef_gap_Front=_b[lag_ctup_Front_Laggard]
gen coef_part_GVC=_b[chg_importGVC_share]

gen TFP_GVC=import_GVC_PEj0_ln_tfp_1_loggr
gen lag_TFP_GVC=l.import_GVC_PEj0_ln_tfp_1_loggr
gen cng_TFP_GVC=TFP_GVC-lag_TFP_GVC

gen TFP_Front=PEj0_ln_tfp_1_loggr_Frontier
gen lag_TFP_Front=l.PEj0_ln_tfp_1_loggr_Frontier
gen cng_TFP_Front=TFP_Front-lag_TFP_Front

gen gap_GVC=lag_ctup_importGVC_Laggard
gen lag_gap_GVC=l.lag_ctup_importGVC_Laggard
gen cng_gap_GVC=gap_GVC-lag_gap_GVC

gen gap_Front=lag_ctup_Front_Laggard
gen lag_gap_Front=l.lag_ctup_Front_Laggard
gen cng_gap_Front=gap_Front-lag_gap_Front

gen part_GVC=chg_importGVC_share
gen lag_part_GVC=l.chg_importGVC_share
gen cng_part_GVC=part_GVC-lag_part_GVC

gen coef_cov=_b[d_covid]
gen cng_cov=1

gen t1_TFP_GVC=coefcng_TFP_GVC*lag_TFP_GVC
gen t2_TFP_GVC=coef_TFP_GVC*cng_TFP_GVC
gen t3_TFP_GVC=coefcng_TFP_GVC*cng_TFP_GVC

gen t1_TFP_Front=coefcng_TFP_Front*lag_TFP_Front
gen t2_TFP_Front=coef_TFP_Front*cng_TFP_Front
gen t3_TFP_Front=coefcng_TFP_Front*cng_TFP_Front

gen t2_gap_GVC=coef_gap_GVC*cng_gap_GVC
gen t2_gap_Front=coef_gap_Front*cng_gap_Front
gen t2_part_GVC=coef_part_GVC*cng_part_GVC
gen t2_cov=coef_cov*cng_cov

gen constr_chg=t1_TFP_GVC+t2_TFP_GVC+t3_TFP_GVC+t1_TFP_Front+t2_TFP_Front+t3_TFP_Front+t2_gap_GVC+t2_gap_Front+t2_part_GVC+t2_cov+cng_err

keep if year==2020
drop if constr_chg==.

browse cng_actual cng_actual_2 constr_chg

collapse (mean) cng_pred cng_actual cng_actual_2 constr_chg t1_* t2_* t3_* cng_err [aweight=lag_FV18_rva_tot_Laggard] 

rename * *Laggard_imp
gen a="a"
reshape long cng_pred cng_actual cng_actual_2 constr_chg t1_TFP_GVC t1_TFP_Front t2_TFP_GVC t2_TFP_Front t2_gap_GVC t2_gap_Front t2_part_GVC t2_cov t3_TFP_GVC t3_TFP_Front cng_err, i(a) j(group) s
drop a

save "Shift_share/Laggard_imp.dta", replace

restore
}

reghdfe PEj0_ln_tfp_1_loggr_Laggard export_GVC_PEj0_ln_tfp_1_loggr gfexport_GVC_PEj0_ln_tfp_1_loggr cvexport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_Laggard PEj0_ln_tfp_1_loggr_Frontier gfPEj0_ln_tfp_1_loggr_Frontier cvPEj0_ln_tfp_1_loggr_Frontier lag_ctup_Front_Laggard chg_exportGVC_share d_*, absorb(id) vce(cluster id) resid
outreg2 using "Regs_new\MidLag_time.doc", append ctitle(Laggards, Import) addtext() dec(4) label adjr2 sortvar(import_GVC_PEj0_ln_tfp_1_loggr gfimport_GVC_PEj0_ln_tfp_1_loggr cvimport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Mid_prod lag_ctup_importGVC_Laggard chg_importGVC_share export_GVC_PEj0_ln_tfp_1_loggr gfexport_GVC_PEj0_ln_tfp_1_loggr cvexport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_Mid_prod lag_ctup_exportGVC_Laggard chg_exportGVC_share PEj0_ln_tfp_1_loggr_Frontier gfPEj0_ln_tfp_1_loggr_Frontier cvPEj0_ln_tfp_1_loggr_Frontier lag_ctup_Front_Mid_prod lag_ctup_Front_Laggard d_gfc d_covid)

{
preserve
sort id year
keep if year==2019 | year==2020

predict pred, xbd // Prediction
predict err, res // Epsilon
gen actual=PEj0_ln_tfp_1_loggr_Laggard // Actual
gen actual_2=pred+err
gen lag_pred=l.pred // Prediction t-1
gen lag_err=l.err // Epsilon t-1
gen lag_actual=l.PEj0_ln_tfp_1_loggr_Laggard  // Actual t-1
gen lag_actual_2=l.actual_2  // Actual t-1
gen cng_pred= pred-lag_pred // Delta Prediction
gen cng_err= err-lag_err // Delta Epsilon
gen cng_actual=actual-lag_actual  // Delta Actual
gen cng_actual_2=actual_2-lag_actual_2

gen coef_TFP_GVC=_b[export_GVC_PEj0_ln_tfp_1_loggr]
gen coefcng_TFP_GVC=_b[cvexport_GVC_PEj0_ln_tfp_1_loggr]
gen coef_TFP_Front=_b[PEj0_ln_tfp_1_loggr_Frontier]
gen coefcng_TFP_Front=_b[cvPEj0_ln_tfp_1_loggr_Frontier]
gen coef_gap_GVC=_b[lag_ctup_exportGVC_Laggard]
gen coef_gap_Front=_b[lag_ctup_Front_Laggard]
gen coef_part_GVC=_b[chg_exportGVC_share]

gen TFP_GVC=export_GVC_PEj0_ln_tfp_1_loggr
gen lag_TFP_GVC=l.export_GVC_PEj0_ln_tfp_1_loggr
gen cng_TFP_GVC=TFP_GVC-lag_TFP_GVC

gen TFP_Front=PEj0_ln_tfp_1_loggr_Frontier
gen lag_TFP_Front=l.PEj0_ln_tfp_1_loggr_Frontier
gen cng_TFP_Front=TFP_Front-lag_TFP_Front

gen gap_GVC=lag_ctup_exportGVC_Laggard
gen lag_gap_GVC=l.lag_ctup_exportGVC_Laggard
gen cng_gap_GVC=gap_GVC-lag_gap_GVC

gen gap_Front=lag_ctup_Front_Laggard
gen lag_gap_Front=l.lag_ctup_Front_Laggard
gen cng_gap_Front=gap_Front-lag_gap_Front

gen part_GVC=chg_exportGVC_share
gen lag_part_GVC=l.chg_exportGVC_share
gen cng_part_GVC=part_GVC-lag_part_GVC

gen coef_cov=_b[d_covid]
gen cng_cov=1

gen t1_TFP_GVC=coefcng_TFP_GVC*lag_TFP_GVC
gen t2_TFP_GVC=coef_TFP_GVC*cng_TFP_GVC
gen t3_TFP_GVC=coefcng_TFP_GVC*cng_TFP_GVC

gen t1_TFP_Front=coefcng_TFP_Front*lag_TFP_Front
gen t2_TFP_Front=coef_TFP_Front*cng_TFP_Front
gen t3_TFP_Front=coefcng_TFP_Front*cng_TFP_Front

gen t2_gap_GVC=coef_gap_GVC*cng_gap_GVC
gen t2_gap_Front=coef_gap_Front*cng_gap_Front
gen t2_part_GVC=coef_part_GVC*cng_part_GVC
gen t2_cov=coef_cov*cng_cov

gen constr_chg=t1_TFP_GVC+t2_TFP_GVC+t3_TFP_GVC+t1_TFP_Front+t2_TFP_Front+t3_TFP_Front+t2_gap_GVC+t2_gap_Front+t2_part_GVC+t2_cov+cng_err

keep if year==2020
drop if constr_chg==.

browse cng_actual cng_actual_2 constr_chg

collapse (mean) cng_pred cng_actual cng_actual_2 constr_chg t1_* t2_* t3_* cng_err [aweight=lag_FV18_rva_tot_Laggard] 

rename * *Laggard_exp
gen a="a"
reshape long cng_pred cng_actual cng_actual_2 constr_chg t1_TFP_GVC t1_TFP_Front t2_TFP_GVC t2_TFP_Front t2_gap_GVC t2_gap_Front t2_part_GVC t2_cov t3_TFP_GVC t3_TFP_Front cng_err, i(a) j(group) s
drop a

save "Shift_share/Laggard_exp.dta", replace

restore
}

{
preserve

clear
use "Shift_share/MS_imp.dta"
append using "Shift_share/MS_exp.dta"
append using "Shift_share/Frontier_imp.dta"
append using "Shift_share/Frontier_exp.dta"
append using "Shift_share/Mid_prod_imp.dta"
append using "Shift_share/Mid_prod_exp.dta"
append using "Shift_share/Laggard_imp.dta"
append using "Shift_share/Laggard_exp.dta"

*export excel using "C:\Users\Marco\Desktop\CompNet 2023\GVC Analysis\Shift_share\Total_shift_share.xlsx", sheet(Sheet1, replace) firstrow(variables)

restore
}

********************************
****  HHI/TIME INTERACTION   ***
*****     REGRESSIONS      *****
******************************** 	  

foreach f in export import {
bys year: egen med_`f'_HHI=pctile(`f'_HHI), p(75)
gen abv_med_`f'_HHI=(`f'_HHI>med_`f'_HHI)

gen abv_`f'_GVC_TFP=`f'_GVC_PEj0_ln_tfp_1_loggr*abv_med_`f'_HHI
gen gfabv_`f'_GVC_TFP=gf`f'_GVC_PEj0_ln_tfp_1_loggr*abv_med_`f'_HHI
gen cvabv_`f'_GVC_TFP=cv`f'_GVC_PEj0_ln_tfp_1_loggr*abv_med_`f'_HHI
}

foreach f in export import {
gen abv_`f'_Front_TFP=PEj0_ln_tfp_1_loggr_Frontier*abv_med_`f'_HHI
gen gfabv_`f'_Front_TFP=gfPEj0_ln_tfp_1_loggr_Frontier*abv_med_`f'_HHI
gen cvabv_`f'_Front_TFP=cvPEj0_ln_tfp_1_loggr_Frontier*abv_med_`f'_HHI
}

reghdfe PEj0_ln_tfp_1_loggr_MS import_GVC_PEj0_ln_tfp_1_loggr gfimport_GVC_PEj0_ln_tfp_1_loggr cvimport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_MS chg_importGVC_share d_* if abv_med_import_HHI==1, absorb(id) vce(cluster id)
outreg2 using "Regs_new\MacSec_HHI.doc", replace ctitle(High HHI, Import) addtext() dec(4) label adjr2 sortvar(import_GVC_PEj0_ln_tfp_1_loggr gfimport_GVC_PEj0_ln_tfp_1_loggr cvimport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_MS chg_importGVC_share export_GVC_PEj0_ln_tfp_1_loggr gfexport_GVC_PEj0_ln_tfp_1_loggr cvexport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_MS chg_exportGVC_share d_gfc d_covid)

reghdfe PEj0_ln_tfp_1_loggr_MS export_GVC_PEj0_ln_tfp_1_loggr gfexport_GVC_PEj0_ln_tfp_1_loggr cvexport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_MS chg_exportGVC_share d_* if abv_med_export_HHI==1, absorb(id) vce(cluster id)
outreg2 using "Regs_new\MacSec_HHI.doc", append ctitle(High HHI, Export) addtext() dec(4) label adjr2 sortvar(import_GVC_PEj0_ln_tfp_1_loggr gfimport_GVC_PEj0_ln_tfp_1_loggr cvimport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_MS chg_importGVC_share export_GVC_PEj0_ln_tfp_1_loggr gfexport_GVC_PEj0_ln_tfp_1_loggr cvexport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_MS chg_exportGVC_share d_gfc d_covid)

reghdfe PEj0_ln_tfp_1_loggr_MS import_GVC_PEj0_ln_tfp_1_loggr gfimport_GVC_PEj0_ln_tfp_1_loggr cvimport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_MS chg_importGVC_share d_* if abv_med_import_HHI==0, absorb(id) vce(cluster id)
outreg2 using "Regs_new\MacSec_HHI.doc", append ctitle(Low HHI, Import) addtext() dec(4) label adjr2 sortvar(import_GVC_PEj0_ln_tfp_1_loggr gfimport_GVC_PEj0_ln_tfp_1_loggr cvimport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_MS chg_importGVC_share export_GVC_PEj0_ln_tfp_1_loggr gfexport_GVC_PEj0_ln_tfp_1_loggr cvexport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_MS chg_exportGVC_share d_gfc d_covid)

reghdfe PEj0_ln_tfp_1_loggr_MS export_GVC_PEj0_ln_tfp_1_loggr gfexport_GVC_PEj0_ln_tfp_1_loggr cvexport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_MS chg_exportGVC_share d_* if abv_med_export_HHI==0, absorb(id) vce(cluster id)
outreg2 using "Regs_new\MacSec_HHI.doc", append ctitle(Low HHI, Export) addtext() dec(4) label adjr2 sortvar(import_GVC_PEj0_ln_tfp_1_loggr gfimport_GVC_PEj0_ln_tfp_1_loggr cvimport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_MS chg_importGVC_share export_GVC_PEj0_ln_tfp_1_loggr gfexport_GVC_PEj0_ln_tfp_1_loggr cvexport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_MS chg_exportGVC_share d_gfc d_covid)



reghdfe PEj0_ln_tfp_1_loggr_Frontier import_GVC_PEj0_ln_tfp_1_loggr gfimport_GVC_PEj0_ln_tfp_1_loggr cvimport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Frontier chg_importGVC_share d_* if abv_med_import_HHI==1, absorb(id) vce(cluster id)
outreg2 using "Regs_new\Frontier_HHI.doc", replace ctitle(High HHI, Import) addtext() dec(4) label adjr2 sortvar(import_GVC_PEj0_ln_tfp_1_loggr gfimport_GVC_PEj0_ln_tfp_1_loggr cvimport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Frontier chg_importGVC_share export_GVC_PEj0_ln_tfp_1_loggr gfexport_GVC_PEj0_ln_tfp_1_loggr cvexport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_Frontier chg_exportGVC_share d_gfc d_covid)

reghdfe PEj0_ln_tfp_1_loggr_Frontier export_GVC_PEj0_ln_tfp_1_loggr gfexport_GVC_PEj0_ln_tfp_1_loggr cvexport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_Frontier chg_exportGVC_share d_* if abv_med_export_HHI==1, absorb(id) vce(cluster id)
outreg2 using "Regs_new\Frontier_HHI.doc", append ctitle(High HHI, Export) addtext() dec(4) label adjr2 sortvar(import_GVC_PEj0_ln_tfp_1_loggr gfimport_GVC_PEj0_ln_tfp_1_loggr cvimport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Frontier chg_importGVC_share export_GVC_PEj0_ln_tfp_1_loggr gfexport_GVC_PEj0_ln_tfp_1_loggr cvexport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_Frontier chg_exportGVC_share d_gfc d_covid)

reghdfe PEj0_ln_tfp_1_loggr_Frontier import_GVC_PEj0_ln_tfp_1_loggr gfimport_GVC_PEj0_ln_tfp_1_loggr cvimport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Frontier chg_importGVC_share d_* if abv_med_import_HHI==0, absorb(id) vce(cluster id)
outreg2 using "Regs_new\Frontier_HHI.doc", append ctitle(Low HHI, Import) addtext() dec(4) label adjr2 sortvar(import_GVC_PEj0_ln_tfp_1_loggr gfimport_GVC_PEj0_ln_tfp_1_loggr cvimport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Frontier chg_importGVC_share export_GVC_PEj0_ln_tfp_1_loggr gfexport_GVC_PEj0_ln_tfp_1_loggr cvexport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_Frontier chg_exportGVC_share d_gfc d_covid)

reghdfe PEj0_ln_tfp_1_loggr_Frontier export_GVC_PEj0_ln_tfp_1_loggr gfexport_GVC_PEj0_ln_tfp_1_loggr cvexport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_Frontier chg_exportGVC_share d_* if abv_med_export_HHI==0, absorb(id) vce(cluster id)
outreg2 using "Regs_new\Frontier_HHI.doc", append ctitle(Low HHI, Export) addtext() dec(4) label adjr2 sortvar(import_GVC_PEj0_ln_tfp_1_loggr gfimport_GVC_PEj0_ln_tfp_1_loggr cvimport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_importGVC_Frontier chg_importGVC_share export_GVC_PEj0_ln_tfp_1_loggr gfexport_GVC_PEj0_ln_tfp_1_loggr cvexport_GVC_PEj0_ln_tfp_1_loggr lag_ctup_exportGVC_Frontier chg_exportGVC_share d_gfc d_covid)


gen time="Normal"
replace time="GFC" if year>=2008 & year<=2010
replace time="COVID-19" if year==2020

preserve
foreach pct in MS Frontier Laggard Mid_prod {
	bys year: egen sum_lrva_`pct'=sum(lag_FV18_rva_tot_`pct')
	gen sh_lrva_`pct'=lag_FV18_rva_tot_`pct'/sum_lrva_`pct'
	replace PEj0_ln_tfp_1_loggr_`pct'=PEj0_ln_tfp_1_loggr_`pct'*sh_lrva_`pct'
}

replace import_GVC_PEj0_ln_tfp_1_loggr=import_GVC_PEj0_ln_tfp_1_loggr*sh_lrva_MS


collapse (sum) PEj0_ln_tfp_1_loggr_Frontier PEj0_ln_tfp_1_loggr_Laggard PEj0_ln_tfp_1_loggr_Mid_prod import_GVC_PEj0_ln_tfp_1_loggr, by(year time)
drop if year==2005
collapse (mean) PEj0_ln_tfp_1_loggr_Frontier PEj0_ln_tfp_1_loggr_Laggard PEj0_ln_tfp_1_loggr_Mid_prod import_GVC_PEj0_ln_tfp_1_loggr, by(time)


restore



collapse (mean) PEj0_ln_tfp_1_loggr_MS PEj0_ln_tfp_1_loggr_Frontier import_GVC_PEj0_ln_tfp_1_loggr export_GVC_PEj0_ln_tfp_1_loggr, by(macro_sector time)
graph bar PEj0_ln_tfp_1_loggr_MS PEj0_ln_tfp_1_loggr_Frontier import_GVC_PEj0_ln_tfp_1_loggr export_GVC_PEj0_ln_tfp_1_loggr, over(time) by(macro_sector)
export excel using "TFP_Means_MacSec.xlsx", firstrow(variables) nolabel replace
collapse (mean) PEj0_ln_tfp_1_loggr_MS PEj0_ln_tfp_1_loggr_Frontier import_GVC_PEj0_ln_tfp_1_loggr export_GVC_PEj0_ln_tfp_1_loggr, by(time)
export excel using "TFP_Means.xlsx", firstrow(variables) nolabel replace
gsort -PEj0_ln_tfp_1_loggr_MS
graph bar PEj0_ln_tfp_1_loggr_MS PEj0_ln_tfp_1_loggr_Frontier import_GVC_PEj0_ln_tfp_1_loggr export_GVC_PEj0_ln_tfp_1_loggr, over(time) graphregion(color(white)) legend(label(1 Macro-sector) label(2 Frontier) label(3 Import GVC) label(4 Export GVC)) bar(1, color(edkblue)) bar(2, color(cranberry)) bar(3, color(dkgreen)) bar(4, color(gold))



* Firms with lower HHI have a larger covid shock and the coefficient on GVC transmission is strongly increasing during covid
* Firms with higher HHI have a large coefficient on the lagged catching up term, hinting that less sophisticated country-macro-sectors are still integrating

/*
egen cntr=group(country)
egen ind=group(macro_sector)

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
*/