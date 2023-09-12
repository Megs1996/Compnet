clear all
cap restore
cap log close
set more off

*** This code prepares data from TFP distributions in CompNet for computations in Section 2

global main_dr "C:\Users\Marco\Desktop\CompNet 2023" // Set the main directory here
global data_dr "9th Vintage" // Set the input data directory here
global sub_dr "GVC Analysis" // Set the sub-directory here

cd "$main_dr"

use "$data_dr\jd_inp_prod_industry2d_20e_weighted.dta", clear
keep country year by_var* industry2d PEj0_ln_tfp_1_mn PEj0_ln_tfp_1_sw PEj1_ln_tfp_2_mn PEj1_ln_tfp_2_sw PV05_lnsr_cs_mn PV05_lnsr_cs_sw PV03_lnlprod_va_mn PV03_lnlprod_va_sw LV21_l_mn LV21_l_sw FV18_rva_mn FV18_rva_sw

gen LV21_l_tot=LV21_l_mn*LV21_l_sw
drop LV21_l_mn LV21_l_sw

gen FV18_rva_tot=FV18_rva_mn*FV18_rva_sw
drop FV18_rva_mn FV18_rva_sw

foreach prod_v in PEj0_ln_tfp_1 PEj1_ln_tfp_2 PV05_lnsr_cs {
preserve
keep country year by_var* industry2d `prod_v'_mn `prod_v'_sw PV03_lnlprod_va_mn PV03_lnlprod_va_sw LV21_l_tot FV18_rva_tot
keep if by_var=="`prod_v'"
sort year country industry2d
egen id=group(country industry2d by_var_value)
xtset id year
gen `prod_v'_loggr= (log(`prod_v'_mn/l.`prod_v'_mn))*100
gen lag_`prod_v'_sw=l.`prod_v'_sw
*gen PEi9_ln_tfp_0_pctgr= ((PEi9_ln_tfp_0_mn/l.PEi9_ln_tfp_0_mn)-1)*100
gen lag_PV03_lnlprod_va_sw=l.PV03_lnlprod_va_sw

tostring industry2d, replace force
replace industry2d="1" if industry2d=="10" | industry2d=="11"| industry2d=="12"| industry2d=="13"| industry2d=="14"| industry2d=="15" | industry2d=="16" | industry2d=="17" | industry2d=="18" | industry2d=="20" | industry2d=="21" | industry2d=="22" | industry2d=="23" | industry2d=="24" | industry2d=="25" | industry2d=="26" | industry2d=="27" | industry2d=="28" | industry2d=="29" | industry2d=="30" | industry2d=="31" | industry2d=="32" | industry2d=="33" 
replace industry2d="2" if industry2d=="41" | industry2d=="42" | industry2d=="43" 
replace industry2d="3" if industry2d=="45" | industry2d=="46" | industry2d=="47"
replace industry2d="4" if industry2d=="49" | industry2d=="50" | industry2d=="51" | industry2d=="52" | industry2d=="53" 
replace industry2d="5" if industry2d=="55" | industry2d=="56" | industry2d=="57"
replace industry2d="6" if industry2d=="58" | industry2d=="59" | industry2d=="60" | industry2d=="61" | industry2d=="62" | industry2d=="63"
replace industry2d="7" if industry2d=="68"
replace industry2d="8" if industry2d=="69" | industry2d=="70" | industry2d=="71" | industry2d=="72" | industry2d=="73" | industry2d=="74" | industry2d=="75" 
replace industry2d="9" if industry2d=="77" | industry2d=="78" | industry2d=="79" | industry2d=="80" | industry2d=="81" | industry2d=="82"

keep country year by_var by_var_value industry2d PV03_lnlprod_va_mn `prod_v'_loggr lag_`prod_v'_sw lag_PV03_lnlprod_va_sw LV21_l_tot FV18_rva_tot
replace lag_`prod_v'_sw=. if `prod_v'_loggr==.
replace lag_PV03_lnlprod_va_sw=. if PV03_lnlprod_va_mn==.
bys country year industry2d by_var_value: egen tot=sum(lag_`prod_v'_sw)
bys country year industry2d by_var_value: egen tot_lprod=sum(lag_PV03_lnlprod_va_sw)
gen share= lag_`prod_v'_sw/tot
gen share_lprod= lag_PV03_lnlprod_va_sw/tot_lprod
gen wg_`prod_v'_loggr= `prod_v'_loggr*share
gen wg_PV03_lnlprod_va_mn= PV03_lnlprod_va_mn*share_lprod
collapse (sum) wg_`prod_v'_loggr wg_PV03_lnlprod_va_mn LV21_l_tot FV18_rva_tot, by(country year industry2d by_var_value)
order year country industry2d by_var_value
sort year country industry2d by_var_value
drop if wg_`prod_v'_loggr==0
rename industry2d macro_sector

gen percentile=""
replace percentile= "Laggard" if by_var_value==20 
replace percentile= "Mid_prod" if by_var_value==40 | by_var_value==60 | by_var_value==80
replace percentile= "Frontier" if by_var_value==100

save "$sub_dr\TFP\Lab_`prod_v'.dta", replace

egen id=group(country macro_sector by_var_value)
xtset id year

gen lag_LV21_l_tot=l.LV21_l_tot

collapse (mean) wg_`prod_v'_loggr wg_PV03_lnlprod_va_mn [aweight = lag_LV21_l_tot], by(country year macro_sector percentile)
order year country macro_sector percentile

rename wg_* *_

reshape wide `prod_v'_loggr_ PV03_lnlprod_va_mn_, i(country year macro_sector) j(percentile) s
save "$sub_dr\TFP\TFP_`prod_v'.dta", replace

keep country year macro_sector `prod_v'_loggr_Frontier PV03_lnlprod_va_mn_Frontier
rename `prod_v'_loggr_Frontier Prt_`prod_v'_loggr_Frontier
rename PV03_lnlprod_va_mn_Frontier Prt_PV03_lnlprod_va_mn_Frontier
rename country country_partner
rename macro_sector macro_sector_partner
save "$sub_dr\TFP\Prt_TFP_`prod_v'.dta", replace

use "$sub_dr\TFP\Lab_`prod_v'.dta", clear
keep country year macro_sector percentile LV21_l_tot FV18_rva_tot

collapse (sum) LV21_l_tot FV18_rva_tot, by(country year macro_sector percentile)
order year country macro_sector percentile
rename LV21_l_tot LV21_l_tot_
rename FV18_rva_tot FV18_rva_tot_
reshape wide LV21_l_tot FV18_rva_tot, i(country year macro_sector) j(percentile) s

save "$sub_dr\TFP\Lab_hor_`prod_v'.dta", replace

restore
}
