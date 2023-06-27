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

keep country year mac_sector FV08_nrev_mn FV08_nrev_sw CV05_hhi_rev_pop_M_tot // Keep variables of interest

keep if year >= 2015 & year <= 2020
replace CV05_hhi_rev_pop_M_tot=CV05_hhi_rev_pop_M_tot*100 // HHI measures should be multiplied by 100
sort country year mac_sector

preserve
keep if country=="Denmark"

gen FV08_nrev_tot=FV08_nrev_mn*FV08_nrev_sw // Here we retrieve total nominal revenues for each macro-sector
bys country year: egen FV08_nrev_sum=sum(FV08_nrev_tot) // Here we compute country-level revenues for DK
gen FV08_nrev_sqsh=(FV08_nrev_tot/FV08_nrev_sum)^2 // Compute squared revenue shares for each macro-sector within the total economy

replace CV05_hhi_rev_pop_M_tot=CV05_hhi_rev_pop_M_tot*FV08_nrev_sqsh // This is the contribution of each macro-sector to the HHI for
// the total economy
keep country year mac_sector CV05_hhi_rev_pop_M_tot FV08_nrev_tot

keep if mac_sector==7  // We need to subtract macro-sector 7's contribution to the overall DK HHI (sse line 20)
rename CV05_hhi_rev_pop_M_tot HHI_macsec7
rename FV08_nrev_tot FV08_nrev_tot_macsec7
merge 1:1 country year using "$sub_dr\\DK_countrylev.dta"
// We can now remove macro-sector 7's contributions from both overall HHI and revenues for DK (see line 20)
gen HHI=HHI_countrylev-HHI_macsec7
gen FV08_nrev_tot=FV08_nrev_tot_countrylev-FV08_nrev_tot_macsec7
keep country year HHI FV08_nrev_tot
save "$sub_dr\\DK_inclmacsec4.dta", replace
restore

drop if mac_sector==7

preserve

rename CV05_hhi_rev_pop_M_tot HHI
tostring mac_sector, replace force

* Aggregate macrosectors into countries according to Bighelli et al. (2020)
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


* Concentration over time

* Taking variables for top 10 revenue firms' share (from Joint Distribution data)
use "$data_dr\jd_inp_country_20e_weighted.dta", clear
keep if by_var=="FD04_t10_rev_2D"

gen FV17_rrev_tot=FV17_rrev_mn*FV17_rrev_sw // Revert total revenues
bys country year: egen FV17_rrev_sum=sum(FV17_rrev_tot) // Compute total revenues at the country level
gen FV17_rrev_share=FV17_rrev_tot/FV17_rrev_sum // This delivers the revenue share for firms both in the top 10 and not in the top 10
keep if by_var_value==1 // We only keep the top 10 firms' revenue share
keep country year FV17_rrev_share
rename FV17_rrev_share top10_share

sort country year 

save "$sub_dr\Top10_cntr.dta", replace


use "$data_dr\unconditional_country_20e_weighted.dta", clear
keep country year CE45_markup_1_mn CE33_markdown_l_1_mn CV04_hhi_rev_pop_C_tot
rename CV04_hhi_rev_pop_C_tot HHI

merge 1:1 country year using "$sub_dr\Top10_cntr.dta" // Join markup, markdown, and HHI measures with top 10 firm's revenue shares
drop _merge

// Build and index for each among markup, markdown, HHI measures, and top 10 firm's revenue shares with base year = 2010
foreach v in CE45_markup_1_mn CE33_markdown_l_1_mn top10_share HHI {
	gen l_`v'=`v' if year==2010
	bys country: egen base_`v'=mean(l_`v')
	gen ind_`v'=(`v'/base_`v')*100
	drop l_`v' base_`v'
}

// Graph indexes for markup, markdown, HHI measures, and top 10 firm's revenue shares for 2018 and 2020 and then gather the charts

preserve
keep if year==2020 

graph bar ind_CE45_markup_1_mn ind_CE33_markdown_l_1_mn ind_top10_share ind_HHI, over(country, label(labsize(vsmall) angle(45))) graphregion(color(white)) ytitle("") ylabel(0(50)350, labsize(vsmall)) legend(size(vsmall)) title("2020 given 2010=100") legend(label(1 "Markup") label(2 "Markdown") label(3 "Top 10 firms' share on revenues") label(4 "HHI")) name(g_2020)
restore

preserve
keep if year==2018

graph bar ind_CE45_markup_1_mn ind_CE33_markdown_l_1_mn ind_top10_share ind_HHI, over(country, label(labsize(vsmall) angle(45))) graphregion(color(white)) ytitle("") ylabel(0(50)350, labsize(vsmall)) legend(size(vsmall)) title("2018 given 2010=100") legend(label(1 "Markup") label(2 "Markdown") label(3 "Top 10 firms' share on revenues") label(4 "HHI")) name(g_2018) 
restore

grc1leg g_2018 g_2020, graphregion(color(white)) title("Evolution of market power") note("Note: Data source is the CompNet 9th Vintage. Revenue-based HHI not adjusted for relative size of the" "country.")
graph export "$sub_dr\Markt_power.emf", replace
