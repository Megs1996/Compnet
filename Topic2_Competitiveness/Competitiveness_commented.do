clear all
cap restore
cap log close
set more off

// In the current do file, HHIs are plotted adjusting by the relative size of the country
// like in Bighelli et al. (2022). This adjustment would need a balanced panel, which is not
// the case in the following lines, most notably because of German data only until 2018. We are
// working at an amended version of the computations taking this into account. Such version will
// be available in the code package for the final Report.

global main_dr "C:\Users\Marco\Desktop\CompNet 2023" // Set the main directory here
global data_dr "9th Vintage" // Set the input data directory here
global sub_dr "Competitiveness" // Set the sub-directory here

cd "$main_dr"

capture noisily mkdir "Competitiveness"

// Issue: in the macrosectoral dataset, DK has missing revenues for mac_sector 4
// which prevents to aggregate it at the country level. Possible solutions are:
// 1) Simply use the macrosectoral dataset -> problem is that this would distort 
// the comparison against other countries by lowering concentration for DK;
// 2) Consider the country dataset instead for the national level -> problem is 
// that this would include mac_sector 7 for some countries and not for others, or
// only for some years for the same country like MT;
// 3) Use the macrosectoral dataset dropping mac_sector 7 for all countries and 
// use the concentration measure from the country dataset for DK -> problem is that
// in this way concentration for DK would be the only one including mac_sector 7;
// 4) Use the macrosectoral dataset and dropping from the comparison mac_sector 4
// and 7 -> mac_sector 4 leads concentration in many countries;
// 5) Combine the macrosectoral and country datasets in this way: drop only mac_sector
// 7 and aggregate to country level for all countries but for DK, for which we take
// the country-level concentration measure and subtract the one for mac_sector 7
// -> This delivers an homogeneous group of macro sectors to implement the comparison.

use "$data_dr\\unconditional_country_20e_weighted.dta", clear
keep if country=="Denmark"
keep if year >= 2015 & year <= 2020
sort country year

keep country year CV04_hhi_rev_pop_C_tot FV08_nrev_mn FV08_nrev_sw // Keep variables of interest
replace CV04_hhi_rev_pop_C_tot=CV04_hhi_rev_pop_C_tot*100 // HHI measures should be multiplied by 100
gen FV08_nrev_tot=FV08_nrev_mn*FV08_nrev_sw // Here we retrieve total nominal revenues
rename CV04_hhi_rev_pop_C_tot HHI_countrylev
rename FV08_nrev_tot FV08_nrev_tot_countrylev
keep country year HHI_countrylev FV08_nrev_tot_countrylev

save "$sub_dr\\DK_countrylev.dta", replace

* HHIs by macrosectors
use "$data_dr\\unconditional_mac_sector_20e_weighted.dta", clear

keep country year mac_sector FV08_nrev_mn FV08_nrev_sw CV05_hhi_rev_pop_M_tot // Keep only variables of interest

keep if year >= 2015 & year <= 2020
replace CV05_hhi_rev_pop_M_tot=CV05_hhi_rev_pop_M_tot*100 // HHI measures should be multiplied by 100
sort country year mac_sector

preserve
keep if country=="Denmark" // Here we build seperate concentration measures for DK (see line 14)

gen FV08_nrev_tot=FV08_nrev_mn*FV08_nrev_sw // Here we retrieve total nominal revenues for each macro-sector
bys country year: egen FV08_nrev_sum=sum(FV08_nrev_tot) // Here we compute country-level revenues for DK
gen FV08_nrev_sqsh=(FV08_nrev_tot/FV08_nrev_sum)^2 // Compute squared revenue shares for each macro-sector within the total economy

replace CV05_hhi_rev_pop_M_tot=CV05_hhi_rev_pop_M_tot*FV08_nrev_sqsh // This is the contribution of each macro-sector to the HHI for
// the total economy
keep country year mac_sector CV05_hhi_rev_pop_M_tot FV08_nrev_tot

keep if mac_sector==7 // We need to subtract macro-sector 7's contribution to the overall DK HHI (sse line 14)
rename CV05_hhi_rev_pop_M_tot HHI_macsec7
rename FV08_nrev_tot FV08_nrev_tot_macsec7
merge 1:1 country year using "$sub_dr\\DK_countrylev.dta"
// We can now remove macro-sector 7's contributions from both overall HHI and revenues for DK (see line 14)
gen HHI=HHI_countrylev-HHI_macsec7
gen FV08_nrev_tot=FV08_nrev_tot_countrylev-FV08_nrev_tot_macsec7
keep country year HHI FV08_nrev_tot
save "$sub_dr\\DK_inclmacsec4.dta", replace
restore

drop if mac_sector==7

preserve

rename CV05_hhi_rev_pop_M_tot HHI
tostring mac_sector, replace force

gen FV08_nrev_tot=FV08_nrev_mn*FV08_nrev_sw // Here we retrieve total nominal revenues for each country-level macro-sector
bys mac_sector year: egen FV08_nrev_sum=sum(FV08_nrev_tot) // Here we compute total EU-level revenues for the macro-sector
gen FV08_nrev_sqsh=(FV08_nrev_tot/FV08_nrev_sum)^2 // Compute squared revenue shares for each country macro-sector within the total EU macro-sector
replace HHI=HHI*FV08_nrev_sqsh // This is the contribution of each country's macro-sector to the HHI for the total EU macro-sector
// That is, the HHI has been adjusted for the size of the country within the macro-sector

levelsof country, local(cntrs)

// Charting macro-sector HHIs using bars (hence taking averages over an unbalanced panel)

local n 1
foreach c in `cntrs' {
graph bar HHI if country=="`c'", over(mac_sector) title("`c'") graphregion(color(white)) legend(label(1 "")) ytitle("", size(small)) ylabel(#2,labsize(vsmall)) name("graph_pld_`n'")
local n=`n'+1
}

// Charting macro-sector HHIs separately for the COVID-19 year (2020)

gen cov=0
replace cov=1 if year==2020
collapse (mean) HHI, by(country mac_sector cov)
reshape wide HHI, i(country mac_sector) j(cov)

local n 1
foreach c in `cntrs' {
graph bar HHI0 HHI1 if country=="`c'", over(mac_sector) title("`c'") graphregion(color(white)) legend(label(1 "2015-2019") label(2 "2020") size(vsmall)) ytitle("", size(small)) ylabel(#2,labsize(vsmall)) name("graph_sep_`n'")
local n=`n'+1
}

restore

// Combining macro-sectors charts for every country

graph combine graph_pld_1 graph_pld_2 graph_pld_3 graph_pld_4 graph_pld_5 graph_pld_6 graph_pld_7 graph_pld_8 graph_pld_9 graph_pld_10 graph_pld_11 graph_pld_12 graph_pld_13 graph_pld_14 graph_pld_15 graph_pld_16 graph_pld_17 graph_pld_18 graph_pld_19 graph_pld_20 graph_pld_21, title("Size-adjusted concentration by country and macro-sector") subtitle("Revenue-based HHI, 2015-2020") graphregion(color(white)) note("Note: 1 = ''Manufacturing'', 2 = ''Construction'', 3 = ''Wholesale and retail trade; repair of motor vehicles and motorcycles'', 4 = ''Transportation" "and storage'', 5 = ''Accommodation and food service activities'', 6 = ''Information and communication'', 8 = ''Professional scientific and technical" "activities'', 9 = ''Administrative and support service activities''. Figures are averages over the period 2015-2020. Data for LV, DE, and NL" "respectively until 2017, 2018, and 2019.", size(vsmall))
graph export "$sub_dr\\Conc_ms_pld.emf", replace   

grc1leg graph_sep_1 graph_sep_2 graph_sep_3 graph_sep_4 graph_sep_5 graph_sep_6 graph_sep_7 graph_sep_8 graph_sep_9 graph_sep_10 graph_sep_11 graph_sep_12 graph_sep_13 graph_sep_14 graph_sep_15 graph_sep_16 graph_sep_17 graph_sep_18 graph_sep_19 graph_sep_20 graph_sep_21, title("Size-adjusted concentration by country and macro-sector") subtitle("Revenue-based HHI, pre vs post COVID-19") graphregion(color(white)) note("Note: 1 = ''Manufacturing'', 2 = ''Construction'', 3 = ''Wholesale and retail trade; repair of motor vehicles and motorcycles'', 4 = ''Transportation" "and storage'', 5 = ''Accommodation and food service activities'', 6 = ''Information and communication'', 8 = ''Professional scientific and technical" "activities'', 9 = ''Administrative and support service activities''. For 2015-2019, figures are averages over those years. Data for LV, DE, and NL" "respectively until 2017, 2018, and 2019.", size(vsmall))
graph export "$sub_dr\\Conc_ms_sep.emf", replace  

* Aggregate HHIs over mac_sectors by countries

gen FV08_nrev_tot=FV08_nrev_mn*FV08_nrev_sw // Here we retrieve total nominal revenues for each macro-sector

bys country year: egen FV08_nrev_sum=sum(FV08_nrev_tot) // Here we compute country-level revenues for each country
gen FV08_nrev_sqsh=(FV08_nrev_tot/FV08_nrev_sum)^2 // Compute squared revenue shares for each macro-sector within the total economy

replace CV05_hhi_rev_pop_M_tot=CV05_hhi_rev_pop_M_tot*FV08_nrev_sqsh // This is the contribution of each macro-sector to the HHI for 
// the total country economy
collapse (sum) CV05_hhi_rev_pop_M_tot FV08_nrev_tot, by(country year) // Here we compute the country-level HHI by aggregating macro-sectoral contributions
// The purpose is to have an homogeneous coverage of macro-sectors across countries

drop if country=="Denmark" // The process above was already implemented for DK (see line 14)

rename CV05_hhi_rev_pop_M_tot HHI
append using "$sub_dr\\DK_inclmacsec4.dta"
sort country year

// Chart HHIs at the country level

graph bar HHI, over(country, label(labsize(small) angle(45))) title("") graphregion(color(white)) ytitle("") name("graph_pld_cntr") title("Concentration by country") subtitle("Revenue-based HHI, 2015-2020") note("Note: Figures are obtained by aggregating within countries the following macro-sectors like in Bighelli et al. (2022): 1 =" " ''Manufacturing'', 2 = ''Construction'', 3 = ''Wholesale and retail trade; repair of motor vehicles and motorcycles'', 4 = ''Transportation" "and storage'', 5 = ''Accommodation and food service activities'', 6 = ''Information and communication'', 8 = ''Professional scientific" "and technical activities'', 9 = ''Administrative and support service activities''. Figures are averages over the period 2015-2020. Data" "for LV, DE, and NL respectively until 2017, 2018, and 2019.", size(vsmall))
graph export "$sub_dr\\Conc_cn_pld.emf", replace  

preserve 

// Chart HHIs at the country level and separately for the COVID-19 year (2020)

gen cov=0
replace cov=1 if year==2020
collapse (mean) HHI, by(country cov)
reshape wide HHI, i(country) j(cov)

graph bar HHI0 HHI1, over(country, label(labsize(small) angle(45))) graphregion(color(white)) legend(label(1 "2015-2019") label(2 "2020") size(vsmall)) ytitle("") name("graph_sep_cntr") title("Concentration by country") subtitle("Revenue-based HHI, pre vs post COVID-19") note("Note: Figures are obtained by aggregating within countries the following macro-sectors like in Bighelli et al. (2022): 1 =" " ''Manufacturing'', 2 = ''Construction'', 3 = ''Wholesale and retail trade; repair of motor vehicles and motorcycles'', 4 = ''Transportation" "and storage'', 5 = ''Accommodation and food service activities'', 6 = ''Information and communication'', 8 = ''Professional scientific" "and technical activities'', 9 = ''Administrative and support service activities''. For 2015-2019, figures are averages over those years." "Data for LV, DE, and NL respectively until 2017, 2018, and 2019.", size(vsmall))
graph export "$sub_dr\\Conc_cn_sep.emf", replace  

restore

// Repeat the process, but separately for larger and smaller countries

bys year: egen FV08_nrev_sum=sum(FV08_nrev_tot)
gen FV08_nrev_sqsh=(FV08_nrev_tot/FV08_nrev_sum)^2
replace HHI=HHI*FV08_nrev_sqsh

preserve
keep if country=="France" | country=="Germany" | country=="Italy" | country=="Spain" | country=="Netherlands" | country=="Switzerland"
graph bar HHI, over(country, label(labsize(small) angle(45))) title("") graphregion(color(white)) ytitle("HHI, revenues") title("Big 5 + CH") name("graph_pld_big5") 

gen cov=0
replace cov=1 if year==2020
collapse (mean) HHI, by(country cov)
reshape wide HHI, i(country) j(cov)

graph bar HHI0 HHI1, over(country, label(labsize(small) angle(45))) graphregion(color(white)) legend(label(1 "2015-2019") label(2 "2020") size(vsmall)) ytitle("") title("Big 5 + CH") name("graph_sep_big5")
restore

preserve
drop if country=="France" | country=="Germany" | country=="Italy" | country=="Spain" | country=="Netherlands" | country=="Switzerland"
graph bar HHI, over(country, label(labsize(small) angle(45))) title("") graphregion(color(white)) ytitle("") title("Smaller economies") name("graph_pld_others")

gen cov=0
replace cov=1 if year==2020
collapse (mean) HHI, by(country cov)
reshape wide HHI, i(country) j(cov)

graph bar HHI0 HHI1, over(country, label(labsize(small) angle(45))) graphregion(color(white)) legend(label(1 "2015-2019") label(2 "2020") size(vsmall)) ytitle("HHI, revenues") title("Smaller economies") name("graph_sep_others")
restore 

graph combine graph_pld_big5 graph_pld_others, title("Size-adjusted concentration by country") subtitle("Revenue-based HHI, 2015-2020") graphregion(color(white)) note("Note: Figures are obtained by aggregating within countries the following macro-sectors and adjusting to relative sizes like in Bighelli et al. (2022):" "1 = ''Manufacturing'', 2 = ''Construction'', 3 = ''Wholesale and retail trade; repair of motor vehicles and motorcycles'', 4 = ''Transportation and" "storage'', 5 = ''Accommodation and food service activities'', 6 = ''Information and communication'', 8 = ''Professional scientific and technical" "activities'', 9 = ''Administrative and support service activities''. Figures are averages over the period 2015-2020. Data for LV, DE, and NL" "respectively until 2017, 2018, and 2019.", size(vsmall))
graph export "$sub_dr\\Conc_cn_pld_sizeadj.emf", replace  

grc1leg graph_sep_big5 graph_sep_others, title("Size-adjusted concentration by country") subtitle("Revenue-based HHI, pre vs post COVID-19") graphregion(color(white)) note("Note: Figures are obtained by aggregating within countries the following macro-sectors and adjusting to relative sizes like in Bighelli et al. (2022):" "1 = ''Manufacturing'', 2 = ''Construction'', 3 = ''Wholesale and retail trade; repair of motor vehicles and motorcycles'', 4 = ''Transportation and" "storage'', 5 = ''Accommodation and food service activities'', 6 = ''Information and communication'', 8 = ''Professional scientific and technical" "activities'', 9 = ''Administrative and support service activities''. For 2015-2019, figures are averages over those years. Data for LV, DE, and NL" "respectively until 2017, 2018, and 2019.", size(vsmall))
graph export "$sub_dr\\Conc_cn_sep_sizeadj.emf", replace 

save "$sub_dr\\HHIs_cntr.dta", replace

collapse (sum) HHI, by(year)

tsset year
twoway tsline HHI, graphregion(color(white))

// Repeat the process, but aggreagatin HHIs by technology classes* rather than macro-sectors
* https://ec.europa.eu/eurostat/cache/metadata/en/htec_esms.htm#meta_update1648477710296

use "$data_dr\\unconditional_techknol_20e_weighted.dta", clear
*drop if country=="Latvia" | country=="Netherlands"
keep if year >= 2015 & year <= 2020
keep country year techknol CV02_hhi_rev_pop_T_tot FV08_nrev_mn FV08_nrev_sw
sort country year techknol

replace CV02_hhi_rev_pop_T_tot=CV02_hhi_rev_pop_T_tot*100 // HHI measures should be multiplied by 100
rename CV02_hhi_rev_pop_T_tot HHI

levelsof country, local(cntrs)

drop if techknol=="."

gen FV08_nrev_tot=FV08_nrev_mn*FV08_nrev_sw // Here we retrieve total nominal revenues for each country-level technology class
bys techknol year: egen FV08_nrev_sum=sum(FV08_nrev_tot) // Here we compute total EU-level revenues for the technology class
gen FV08_nrev_sqsh=(FV08_nrev_tot/FV08_nrev_sum)^2 // Compute squared revenue shares for each country technology class within the total EU technology class
replace HHI=HHI*FV08_nrev_sqsh // This is the contribution of each country's technology class to the HHI for the total EU technology class 
// That is, the HHI has been adjusted for the size of the country within the technology class

// Charting HHIs by technology classes using bars (hence taking averages over an unbalanced panel)

local n 1
foreach c in `cntrs' {
graph bar HHI if country=="`c'", over(techknol) title("`c'") graphregion(color(white)) legend(label(1 "")) ytitle("", size(small)) ylabel(#2,labsize(vsmall)) name("graph_tpld_`n'")
local n=`n'+1
}

// Charting HHIs by technology classes separately for the COVID-19 year (2020)

gen cov=0
replace cov=1 if year==2020
collapse (mean) HHI, by(country techknol cov)
reshape wide HHI, i(country techknol) j(cov)

local n 1
foreach c in `cntrs' {
graph bar HHI0 HHI1 if country=="`c'", over(techknol) title("`c'") graphregion(color(white)) legend(label(1 "2015-2019") label(2 "2020") size(vsmall)) ytitle("", size(vsmall)) ylabel(#2,labsize(small)) name("graph_tsep_`n'")
local n=`n'+1
}

graph combine graph_tpld_1 graph_tpld_2 graph_tpld_3 graph_tpld_4 graph_tpld_5 graph_tpld_6 graph_tpld_7 graph_tpld_8 graph_tpld_9 graph_tpld_10 graph_tpld_11 graph_tpld_12 graph_tpld_13 graph_tpld_14 graph_tpld_15 graph_tpld_16 graph_tpld_17 graph_tpld_18 graph_tpld_19 graph_tpld_20 graph_tpld_21, title("Size-adjusted concentration by country and technology") subtitle("Revenue-based HHI, 2015-2020") graphregion(color(white)) note("Note: Figures are averages over the period 2015-2020. Data for LV, DE, and NL respectively until 2017, 2018, and 2019.", size(vsmall))
graph export "$sub_dr\\Conc_tc_pld.emf", replace   

grc1leg graph_tsep_1 graph_tsep_2 graph_tsep_3 graph_tsep_4 graph_tsep_5 graph_tsep_6 graph_tsep_7 graph_tsep_8 graph_tsep_9 graph_tsep_10 graph_tsep_11 graph_tsep_12 graph_tsep_13 graph_tsep_14 graph_tsep_15 graph_tsep_16 graph_tsep_17 graph_tsep_18 graph_tsep_19 graph_tsep_20 graph_tsep_21, title("Size-adjusted concentration by country and technology") subtitle("Revenue-based HHI, pre vs post COVID-19") graphregion(color(white)) note("Note: For 2015-2019, figures are averages over those years. Data for LV, DE, and NL respectively until 2017, 2018, and 2019.", size(vsmall))
graph export "$sub_dr\\Conc_tc_sep.emf", replace 


// Here we trace trends for value-added labor productivity, real revenues, and real revenues's dispersion separately for exporters vs non-exporters

use "$data_dr\\jd_inp_trad_country_20e_weighted.dta", clear // We use Joint Distributions that condition the usual variables' distributions on
// being exporter or not
keep if by_var=="TD15_exp_adj"
drop if country=="Malta" | country=="Sweden" // These countries only have values for exporters, so we drop them
keep if year>=2010 & year<=2020

keep country year by_var by_var_value PV03_lnlprod_va_mn FV17_rrev_mn FV17_rrev_p75 FV17_rrev_p25 // Keep only variables of interest

gen FV17_rrev_disp=FV17_rrev_p75-FV17_rrev_p25 // This is revenues's dispersion = interquartile difference

keep country year by_var by_var_value PV03_lnlprod_va_mn FV17_rrev_mn FV17_rrev_disp

reshape wide PV03_lnlprod_va_mn FV17_rrev_mn FV17_rrev_disp, i(country year) j(by_var_value) // Reshape the dataset to have separate variables for
// exporters and non-exporters

save "$sub_dr\\inp_trad.dta", replace

levelsof country, local(cntrs)

// For each country, plot trends for value-added labor productivity, real revenues, and real revenues's dispersion separately by export status

foreach v in PV03_lnlprod_va_mn FV17_rrev_mn FV17_rrev_disp {
local n_`v'=1	
foreach c in `cntrs' {
twoway (line `v'1 year if country=="`c'") (line `v'0 year if country=="`c'"), title("`c'") legend(label(1 "Exporters") label(2 "Non-exporters") size(small)) xlabel(2010(2)2020) graphregion(color(white)) ylabel(#2, labsize(tiny)) xtitle("") name("`v'_`n_`v''")
local n_`v'=`n_`v''+1
}
}

// Gather the charts across countries 

grc1leg PV03_lnlprod_va_mn_1 PV03_lnlprod_va_mn_2 PV03_lnlprod_va_mn_3 PV03_lnlprod_va_mn_4 PV03_lnlprod_va_mn_5 PV03_lnlprod_va_mn_6 PV03_lnlprod_va_mn_7 PV03_lnlprod_va_mn_8 PV03_lnlprod_va_mn_9 PV03_lnlprod_va_mn_10 PV03_lnlprod_va_mn_11 PV03_lnlprod_va_mn_12 PV03_lnlprod_va_mn_13, title("Labor productivity by export status") graphregion(color(white)) note("Note: Data source is the CompNet 9th Vintage. Value-added labor productivity.", size(vsmall))
graph export "$sub_dr\\Exp_lp.emf", replace 

grc1leg FV17_rrev_mn_1 FV17_rrev_mn_2 FV17_rrev_mn_3 FV17_rrev_mn_4 FV17_rrev_mn_5 FV17_rrev_mn_6 FV17_rrev_mn_7 FV17_rrev_mn_8 FV17_rrev_mn_9 FV17_rrev_mn_10 FV17_rrev_mn_11 FV17_rrev_mn_12 FV17_rrev_mn_13, title("Mean revenues by export status") graphregion(color(white)) note("Note: Data source is the CompNet 9th Vintage. Mean real revenues.", size(vsmall))
graph export "$sub_dr\\Exp_mr.emf", replace 

grc1leg FV17_rrev_disp_1 FV17_rrev_disp_2 FV17_rrev_disp_3 FV17_rrev_disp_4 FV17_rrev_disp_5 FV17_rrev_disp_6 FV17_rrev_disp_7 FV17_rrev_disp_8 FV17_rrev_disp_9 FV17_rrev_disp_10 FV17_rrev_disp_11 FV17_rrev_disp_12 FV17_rrev_disp_13, title("Revenues dispersion by export status") graphregion(color(white)) note("Note: Data source is the CompNet 9th Vintage. Dispersion is computed as the difference between the 75th and the 25th percentile.", size(vsmall))
graph export "$sub_dr\\Exp_rd.emf", replace 

