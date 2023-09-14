 
 *** This code produces all results in Chapter 6, plus additional ones (additional
 *** regressions). For the figure on HHI trends by dimensions, see also Figure_pdf.do
 
 /*
 *************
 IMPORTANT:
 **************
 in the main text:
 macro-sector/sector: 1-digit NACE 
 industry: 2-digits NACE
 
 in the code:
 macro sector: 1-digit NACE
 sector: 2-digit NACE
 */
 
 
clear
clear matrix
clear mata
set more off
set scheme s2mono
set emptycells drop
graph set window fontface "Cambria"
 
// Globals to define the data path and the save path 
 global data_source_path = "C:\Users\Marco\Desktop\CompNet 2023\9th Vintage"
 global savepath="C:\Users\Marco\Desktop\CompNet 2023\Concentration" 

//Create folders with results
capture noisily mkdir "$savepath\\Replication results"

//Globals to define the balanced panel
global start_year 2010
global end_year 2018
global drop_country   Croatia Denmark Slovenia Latvia
global drop_mac  2 3 5
set maxvar 30000

global sector_drop "if (sector >=41&sector <48)  | (sector >=55&sector <57) "
global country_drop `"if (country == "GERMANY" & ((year <2003) | (year >2018))) | (country == "SWEDEN" & year < 2008)"'

//Other Globals - Baseline vars

//Baseline vars
//mac-sector
global mac_revHHI 				CV05_hhi_rev_pop_M_tot 
global N_revHHI				    CV05_hhi_rev_pop_M_N
global sw_revHHI				CV05_hhi_rev_pop_M_sw

global mac_ifaHHI 				CV13_hhi_ifa_pop_M_tot 
global N_ifaHHI				    CV13_hhi_ifa_pop_M_N
global sw_ifaHHI				CV13_hhi_ifa_pop_M_sw

global mac_rkHHI 				CV37_hhi_rk_pop_M_tot 
global N_rkHHI				    CV37_hhi_rk_pop_M_N
global sw_rkHHI				    CV37_hhi_rk_pop_M_sw

global mac_lHHI 				CV21_hhi_l_pop_M_tot 
global N_lHHI				    CV21_hhi_l_pop_M_N
global sw_lHHI				    CV21_hhi_l_pop_M_sw

global mac_lcHHI 				CV29_hhi_lc_pop_M_tot 
global N_lcHHI				    CV29_hhi_lc_pop_M_N
global sw_lcHHI				    CV29_hhi_lc_pop_M_sw

global mac_rva_posHHI 		    CV45_hhi_rva_pos_pop_M_tot 
global N_rva_posHHI				CV45_hhi_rva_pos_pop_M_N
global sw_rva_posHHI		    CV45_hhi_rva_pos_pop_M_sw




global labor_prod 			PV07_lprod_va_Wl_wmn
global labor_prod_unwe 		PV07_lprod_va_Wl_umn
global labor_prod_op		PV07_lprod_va_Wl_cov

global labor_rev_prod		PV06_lprod_rev_Wl_wmn
global  labor_rev_prod_unwe PV06_lprod_rev_Wl_umn
global  labor_rev_prod_op	PV06_lprod_rev_Wl_cov


//markups and markdowns
global Markup               CE46_markup_2_Wnrv_wmn   // We take revenue weights because consistent across measures; same for spec. 2 and 5
global Markdown_rk          CE56_markdown_k_5_Wnrv_wmn
global Markdown_l           CE58_markdown_l_5_Wnrv_wmn
global Markdown_rva_pos     CE62_markdown_m_5_Wnrv_wmn


global Markup_M_output		CE25_mu_m_rtl_ols_S_Wnrv_wmn			//  CE27_mu_m_rtl_wd_S_Wnrv_wmn
global Markup_VI_output		CE29_mu_vi_rtl_vi_ols_S_Wnrv_wmn		//	CE31_mu_vi_rtl_vi_wd_S_Wnrv_wmn
global Markup_M_input		CE25_mu_m_rtl_ols_S_Wnm_wmn			  //    CE27_mu_m_rtl_wd_S_Wnm_wmn
global Markup_VI_input		CE29_mu_vi_rtl_vi_ols_S_Wnvi_wmn	//		CE31_mu_vi_rtl_vi_wd_S_Wnvi_wmn
global Preferred_markup		CE25_mu_m_rtl_ols_S_Wnm_wmn			//IN THE CODE WEIGHTS ARE INPUT WEIGHTS M


global mean_loglprod 			PV03_lnlprod_va_mn
global mean_lprod				PV07_lprod_va_mn
global mean_wage					LV00_avg_wage_mn
global mean_va_rev	FR35_va_rev_mn
global exp_share			TD15_exp_adj_mn
global mean_wage_va			LR01_lc_va_mn
global mean_wage_rev  LR00_lc_rev_mn

//two-digit-sector
global sec_revHHI 				CV07_hhi_rev_pop_2D_tot

global sec_ifaHHI 				CV15_hhi_ifa_pop_2D_tot

global sec_rkHHI 				CV39_hhi_rk_pop_2D_tot

global sec_lHHI 				CV23_hhi_l_pop_2D_tot

global sec_lcHHI 				CV31_hhi_lc_pop_2D_tot

global sec_rva_posHHI 		    CV47_hhi_rva_pos_pop_2D_tot 


*global sec_HHI 					CV07_hhi_rev_sam_S_tot
global sec_agg_labor_prod 		PV07_lprod_va_Wl_wmn
global sec_mean_labor_prod 		PV07_lprod_va_Wl_umn
global sec_op_labor_prod 		PV07_lprod_va_Wl_cov
global mean_size_firm 			LV21_l_mn
global sec_jdr					LV15_jdr_pop_2D_tot
global sec_jcr 					LV05_jcr_pop_2D_tot


//aggregtion vars
global rev_unit_mn              FV08_nrev_mn
global rev_unit_sw              FV08_nrev_sw

global ifa_unit_mn              FV13_rifa_mn
global ifa_unit_sw              FV13_rifa_sw

global rk_unit_mn               FV14_rk_mn
global rk_unit_sw               FV14_rk_sw

global l_unit_mn                LV21_l_mn
global l_unit_sw                LV21_l_sw

global lc_unit_mn               FV05_nlc_mn
global lc_unit_sw               FV05_nlc_sw

global rva_pos_unit_mn          FV19_rva_pos_mn
global rva_pos_unit_sw          FV19_rva_pos_sw


global sales  				FV08_nrev_mn
global sum_weights_sales	FV08_nrev_sw
global real_sales			FV17_rrev_mn // necessary for ifa because we only have real ifa
global sum_weights_real_sales FV17_rrev_sw
global employment 			LV21_l_mn 
global sum_weights_employ	LV21_l_sw
global M 					FV06_nm_mn      //intermediates
global sum_weights_M		FV06_nm_sw
global VI 					FV12_nvi_mn     //variable input Labor + Intermediate cost
global sum_weights_VI		FV12_nvi_sw
global capital 				FV14_rk_mn
global sum_weights_cap		FV14_rk_sw
global IFA_mn				FV13_rifa_mn
global IFA_sw				FV13_rifa_sw
global va 					FV10_nva_mn
global sum_weights_va		FV10_nva_sw

// Joint Distribution vars
global size_distribution  		ct_LV21_l 
global med_prod_size_prem		PV03_lnlprod_va_p50 
global mean_prod_size_prem		PV03_lnlprod_va_mn
global mean_size_firm 			LV21_l_mn
global median_size_firm			LV21_l_p50
global mean_K_L					FR30_rk_l_mn


//two-digit-sector
global sec_HHI 					CV07_hhi_rev_sam_S_tot

global sec_rev_top10				CR02_top_rev_sam_2D_tot
global sec_ifa_top10				CR04_top_ifa_sam_2D_tot
global sec_rk_top10				    CR16_top_rk_sam_2D_tot
global sec_l_top10				    CR08_top_l_sam_2D_tot
global sec_lc_top10				    CR12_top_lc_sam_2D_tot
global sec_rva_pos_top10		    CR20_top_rva_sam_2D_tot

global sec_agg_labor_prod 		PV07_lprod_va_Wl_wmn
global sec_mean_labor_prod 		PV07_lprod_va_Wl_umn
global sec_op_labor_prod 		PV07_lprod_va_Wl_cov
global mean_size_firm 			LV21_l_mn
global median_size_firm			LV21_l_p50
global sec_p1_prod					PV07_lprod_va_p1
global sec_p5_prod					PV07_lprod_va_p5
global sec_p10_prod					PV07_lprod_va_p10
global sec_p50_prod					PV07_lprod_va_p50
global sec_p90_prod					PV07_lprod_va_p90
global sec_p95_prod					PV07_lprod_va_p95
global sec_p99_prod					PV07_lprod_va_p99
global sd_prod						PV07_lprod_va_sd
global IFA_mn						FV13_rifa_mn
global IFA_sw						FV13_rifa_sw
global d_exp						TD15_exp_adj_mn
 
global mean_rd_costs 				FR23_rd_costs_mn		
global mean_rd_m					FR24_rd_m_mn
	

global log_variables			hhi_rev_sec hhi_ifa_sec hhi_rk_sec hhi_l_sec hhi_lc_sec hhi_rva_pos_sec sec_agg_labor_prod median_size_firm cap_lab sec_mrktpw_rev sec_mrktpw_l sec_mrktpw_rk sec_mrktpw_rva_pos mean_size_firm sec_agg_tfp_prod  sec_rev_top10 sec_ifa_top10 sec_rk_top10 sec_l_top10 sec_lc_top10 sec_rva_pos_top10

// robustness check
/*
global sec_agg_tfp_prod 		PE99_tfp_rcd_ols_S_Wrrv_wmn
global sec_mean_tfp_prod 		PE99_tfp_rcd_ols_S_Wrrv_umn
global sec_op_tfp_prod 			PE99_tfp_rcd_ols_S_Wrrv_cov

global lnsec_agg_tfp_prod 		PE23_lntfp_rcd_ols_S_Wrrv_wmn   //PE27_lntfp_rtl_ols_S_Wrrv_wmn
global lnsec_mean_tfp_prod 		PE23_lntfp_rcd_ols_S_Wrrv_umn    // PE27_lntfp_rtl_ols_S_Wrrv_umn
global lnsec_op_tfp_prod 		PE23_lntfp_rcd_ols_S_Wrrv_cov    // PE27_lntfp_rtl_ols_S_Wrrv_cov
*/

global sec_agg_tfp_prod 		PEb1_tfp_1_Wrrv_wmn
global sec_mean_tfp_prod 		PEb1_tfp_1_Wrrv_umn
global sec_op_tfp_prod 			PEb1_tfp_1_Wrrv_cov

global lnsec_agg_tfp_prod 		PEj0_ln_tfp_1_Wrrv_wmn   //PE27_lntfp_rtl_ols_S_Wrrv_wmn
global lnsec_mean_tfp_prod 		PEj0_ln_tfp_1_Wrrv_umn    // PE27_lntfp_rtl_ols_S_Wrrv_umn
global lnsec_op_tfp_prod 		PEj0_ln_tfp_1_Wrrv_cov    // PE27_lntfp_rtl_ols_S_Wrrv_cov



global sec_p1_tfp_prod					PE23_lntfp_rcd_ols_S_p1
global sec_p5_tfp_prod					PE23_lntfp_rcd_ols_S_p5
global sec_p10_tfp_prod					PE23_lntfp_rcd_ols_S_p10
global sec_p50_tfp_prod					PE23_lntfp_rcd_ols_S_p50
global sec_p90_tfp_prod					PE23_lntfp_rcd_ols_S_p90
global sec_p95_tfp_prod					PE23_lntfp_rcd_ols_S_p95
global sec_p99_tfp_prod					PE23_lntfp_rcd_ols_S_p99
global sd_tfp_prod						PE23_lntfp_rcd_ols_S_sd



global sec_HHI 					CV07_hhi_rev_sam_S_tot
global sec_top10				CR02_top_rev_sam_S_tot


// ssc install reghdfe
 

 
 
 


// REPLICATION RESULTS
**********************

// Table 1 
**********
{
clear
   use "$data_source_path\unconditional_mac_sector_20e_weighted.dta" 
  merge 1:1 country mac year using "$data_source_path\op_decomp_mac_sector_20e_weighted.dta"
gen start_year=$start_year
gen end_year=$end_year 

	
gen N_rev_HHI= $N_revHHI
gen sw_rev_HHI= $sw_revHHI

gen N_ifa_HHI= $N_ifaHHI
gen sw_ifa_HHI= $sw_ifaHHI

gen N_rk_HHI= $N_rkHHI
gen sw_rk_HHI= $sw_rkHHI

gen N_l_HHI= $N_lHHI
gen sw_l_HHI= $sw_lHHI

gen N_lc_HHI= $N_lcHHI
gen sw_lc_HHI= $sw_lcHHI

gen N_rva_pos_HHI= $N_rva_posHHI
gen sw_rva_pos_HHI= $sw_rva_posHHI
}

foreach x in   $drop_mac  {
drop if mac == `x' 
}
foreach x in   $drop_country  {
drop if country == "`x'" 
}
drop $country_drop


bys country : egen min_year=min(year)
bys country: egen max_year=max(year)
/*
// Table 1 - Panel A
preserve 
keep if year==min_year|year==max_year|year==start_year|year==end_year
bys year country : egen sample_num_firms=sum(N_HHI)
bys year country : egen pop_num_firms=sum(sw_HHI)
bys year : egen total_sample_num_firms=sum(N_HHI) if year==start_year|year==end_year 
bys year : egen total_pop_num_firms=sum(sw_HHI) if year==start_year|year==end_year
collapse(mean) sample_num_firms pop_num_firms total_sample_num_firms total_pop_num_firms, by(year country)
export excel using "$savepath\\Replication results\Table1-A.xls", firstrow(variables) nolabel replace
restore

preserve
// Table 1 - Panel B
keep if year==start_year|year==end_year
bys year mac  : egen sample_N=total (N_HHI)
bys year mac : egen pop_N=total(sw_HHI)
bys year: egen europe_sample=total(sample_N)
bys year: egen europe_pop=total(pop_N)
collapse(mean) sample_N pop_N, by(year mac)
export excel using "$savepath\\Replication results\Table1-B.xls", firstrow(variables) nolabel replace
restore
}
*/

// Info for Figure 1
************
{

gen hhi_rev_mac = 100*$mac_revHHI
gen hhi_ifa_mac = 100*$mac_ifaHHI
gen hhi_rk_mac = 100*$mac_rkHHI
gen hhi_l_mac = 100*$mac_lHHI
gen hhi_lc_mac = 100*$mac_lcHHI
gen hhi_rva_pos_mac = 100*$mac_rva_posHHI


gen rev_mn  = $rev_unit_mn
gen rev_sw = $rev_unit_sw

gen ifa_mn  = $ifa_unit_mn
gen ifa_sw = $ifa_unit_sw

gen rk_mn  = $rk_unit_mn
gen rk_sw = $rk_unit_sw

gen l_mn  = $l_unit_mn
gen l_sw = $l_unit_sw

gen lc_mn  = $lc_unit_mn
gen lc_sw = $lc_unit_sw

gen rva_pos_mn  = $rva_pos_unit_mn
gen rva_pos_sw = $rva_pos_unit_sw

//gen flag for manufac
gen flag_man = 1 if mac==1 
gen flag_noman=1 if mac!=1

//unit weights for HHIs
foreach m in rev ifa rk l lc rva_pos {
gen `m'_tot=`m'_mn*`m'_sw
gen `m'_tot_sq=`m'_tot^2

bys year: egen eu_`m'_sum = total(`m'_tot)
gen eu_`m'_sum_sq=eu_`m'_sum^2

//gen aggregates 
//HHI
//eu totals and manufacturing eu totals
*bys year: egen eu_sum_man = total(totrev*flag_man)
*gen eu_sum_man_sq=eu_sum_man^2
*bys year: egen eu_sum_noman=total(totrev*flag_noman)
*gen eu_sum_noman_sq=eu_sum_noman^2
by year: egen  hhi_`m'_eu = total((hhi_`m'_mac*`m'_tot_sq)/eu_`m'_sum_sq)
*by year: egen  hhi_eu_man = total((hhi_mac*totrev_sq*flag_man)/eu_sum_man_sq) 
*bys year: egen hhi_eu_noman=total((hhi_mac*totrev_sq*flag_noman)/eu_sum_noman_sq) 
}

preserve
keep if year >=  $start_year & year <=  $end_year  

foreach m in rev ifa rk l lc rva_pos {
log using "$savepath\\Replication results\\`m'_Country_Macs_availability.log", replace
	tab country year if hhi_`m'_mac!=.
	log close
}	

levelsof mac_sector, local(ms)
levelsof country, local(cn)
foreach c of local cn {
foreach s of local ms {
foreach m in rev ifa rk l lc rva_pos {
	twoway line sw_`m'_HHI year if country=="`c'" & mac_sector==`s', note("`c' `s' `m'") graphregion(color(white))
	graph export "$savepath\\Replication results\\Underlying_pop\\`c'_`s'_`m'.pdf", as(pdf) replace
}
}
}


keep year hhi_*_eu
collapse(mean) hhi_*_eu, by(year)
order year
*export excel using "$savepath\\Replication results\Info_for_figure1.xls", firstrow(variables) nolabel keepcellfmt replace	

foreach m in rev ifa rk l lc rva_pos {
gen Trend_`m' = .
reg  hhi_`m'_eu c.year
replace Trend_`m' = _b[year]  
}

keep year Trend_*

export excel using "$savepath\\Replication results\Table2_Europe.xls", firstrow(variables)  keepcellfmt replace

restore

}

// Table 2
**********

//COUNTRY LEVEL HHI DATA
//deriving country-level HHI from mac sec levels
**************************************************
foreach m in rev rk l rva_pos lc ifa {
// HHI	
bys year country: egen count_`m'_sum = total(`m'_tot)
gen count_`m'_sum_sq = count_`m'_sum^2
bys year country: egen  hhi_`m'_count = total((hhi_`m'_mac*`m'_tot_sq)/count_`m'_sum_sq)
}

{
preserve

// MARKET POWER MEASURES
gen mrktpw_rev=$Markup
gen mrktpw_rk=$Markdown_rk
gen mrktpw_l=$Markdown_l
gen mrktpw_rva_pos=$Markdown_rva_pos

keep if year >=  $start_year & year <=  $end_year  

foreach m in rev rk l rva_pos {
gen flag_`m' = 1 if mrktpw_`m' !=.
bys year country: egen count_`m'_sumf = total(`m'_tot*flag_`m') 
by year country: egen  mrktpw_`m'_count = total((mrktpw_`m' *`m'_tot *flag_`m')/count_`m'_sumf)
drop flag_`m'
}

/*
gen MU_M_input =$Markup_M_input
gen M = $M
gen sum_weights_M = $sum_weights_M
gen totM=M*sum_weights_M 

// MARKUP
gen flag = 1 if MU_M_input !=. 
bys year country: egen count_sum_M = total(totM*flag)
by year country: egen  MU_M_input_count = total((MU_M_input *totM *flag)/count_sum_M)
drop flag 
*/

keep country year hhi_*_count    mrktpw_*_count  

duplicates drop 

foreach m in rev rk l rva_pos {
foreach x in hhi_`m'_count    mrktpw_`m'_count      {
    
	replace `x' =. if `x' ==0
	
}
}

foreach m in rev rk l rva_pos {
foreach y in hhi_`m'_count    mrktpw_`m'_count      {

bys country: egen H`m'_min_year = min(year) if `y' !=. & `y' !=0 
by country: egen H`m'_max_year = max(year) if `y' !=.  & `y' !=0
by country: egen minyr_`y' = mean(H`m'_min_year) 
by country: egen maxyr_`y' = mean(H`m'_max_year) 

gen H_`y'_start = `y' if year == minyr_`y' 
gen H_`y'_end= `y' if year == maxyr_`y' 

bys country: egen mean_`y'  = mean(`y') if `y' !=.  & `y' !=0
by country: egen `y'_start  = mean(H_`y'_start) 
by country: egen `y'_end  = mean(H_`y'_end)

*gen `y'_delta  =   `y'_end   - `y'_start 
gen `y'_delta  =   ((`y'_end/`y'_start)-1)*100

drop     H`m'_min_year  H`m'_max_year  H_`y'_start  H_`y'_end

gen Trend_`y' =.
levelsof country 
foreach x in `r(levels)'  {
display "`x'"


reg  `y' c.year if country == "`x'"
replace Trend_`y' = _b[year]   if country == "`x'"


}

local tabstat_local = "  `tabstat_local'  mean_`y'  `y'_start    `y'_delta    `y'_end  maxyr_`y'   minyr_`y'   Trend_`y'"
}
}

collapse(mean)  `tabstat_local'   , by(country  )
keep mean_hhi_*_count hhi_*_count_delta Trend_hhi_*_count mean_mrktpw_*_count mrktpw_*_count_delta Trend_mrktpw_*_count country
order country
// mean_hhi_count COLUMN 1
// hhi_count_delta COLUMN 2
// Trend_hhi_count COLUMN 3 

foreach m in rev rk l rva_pos {
gen mean_`m'_mrktpw = mean_mrktpw_`m'_count  // COLUMN 4 
gen delta_`m'_mrktpw_count=mrktpw_`m'_count_delta // COLUMN 5 
gen mrktpw_`m'_trend=Trend_mrktpw_`m'_count // COLUMN 6
}
keep country mean_hhi_*_count hhi_*_count_delta Trend_hhi_*_count mean_*_mrktpw delta_*_mrktpw_count mrktpw_*_trend
//
export excel using "$savepath\\Replication results\Table2.xls ", firstrow(variables)  keepcellfmt replace
restore 
}

{
preserve

gen mrktpw_rev=$Markup
gen mrktpw_rk=$Markdown_rk
gen mrktpw_l=$Markdown_l
gen mrktpw_rva_pos=$Markdown_rva_pos

keep if year >=  $start_year & year <=  $end_year  

foreach m in rev rk l rva_pos {
gen flag_`m' = 1 if mrktpw_`m' !=.
bys year : egen eu_`m'_sumf = total(`m'_tot*flag_`m') 
by year : egen  mrktpw_`m'_eu = total((mrktpw_`m' *`m'_tot *flag_`m')/eu_`m'_sumf)
drop flag_`m'
}

collapse (mean) mrktpw_*_eu, by(year)

foreach m in rev rk l rva_pos {
gen Trend_mp_`m' = .
reg  mrktpw_`m'_eu c.year
replace Trend_mp_`m' = _b[year]  
}

export excel using "$savepath\\Replication results\Table2_mp_Europe.xls ", firstrow(variables)  keepcellfmt replace

restore
}

//Table 3 
***********************
{
	
// Columns 1-3
**************	
preserve
keep if year >=  $start_year & year <=  $end_year
  
//gen country weights
foreach m in rev rk l rva_pos lc ifa {
bys country year: egen tot_`m'_country= total(`m'_tot)
gen tot_`m'_country_sq = tot_`m'_country^2
gen country_`m'_weight = tot_`m'_country_sq /eu_`m'_sum_sq
}

keep country year  country_*_weight  eu_*sum_sq   tot_*_country_sq  hhi_*_count hhi_*_eu
duplicates drop 


//gen mean country weight and mean COUNTRY HHI
foreach m in rev rk l rva_pos lc ifa {
bys year: egen mean_country_`m'_weight = mean(country_`m'_weight)
by year: egen mean_hhi_`m'_count   = mean(hhi_`m'_count)
}

//gen number of IDs
bys country: gen n = _n
bys n: egen N_ids_h = total(n) if n == 1
bys country: egen N_ids = mean(N_ids_h)
drop n 

//decomposition
foreach m in rev rk l rva_pos lc ifa {
gen hhi_`m'_country_within =  N_ids * mean_country_`m'_weight * mean_hhi_`m'_count
bys year: egen hhi_`m'_country_between= total ((hhi_`m'_count - mean_hhi_`m'_count )*(country_`m'_weight - mean_country_`m'_weight))
}

keep year   hhi_*_eu     hhi_*_country_within   hhi_*_country_between
duplicates drop 

egen min_year = min(year)
egen max_year = max(year)


//percentage contribution within vs between
foreach m in rev rk l rva_pos lc ifa {
gen h_start_hhi_`m' = hhi_`m'_eu  if  min_year ==year
gen h_end_hhi_`m' = hhi_`m'_eu  if  max_year ==year

egen start_hhi_`m' = mean(h_start_hhi_`m')
egen end_hhi_`m' = mean(h_end_hhi_`m')


gen h_start_hhi_`m'_within = hhi_`m'_country_within  if  min_year ==year
gen h_end_hhi_`m'_within = hhi_`m'_country_within  if  max_year ==year

egen start_hhi_`m'_within = mean(h_start_hhi_`m'_within)
egen end_hhi_`m'_within = mean(h_end_hhi_`m'_within)


gen h_start_hhi_`m'_between = hhi_`m'_country_between  if  min_year ==year
gen h_end_hhi_`m'_between = hhi_`m'_country_between  if  max_year ==year

egen start_hhi_`m'_between = mean(h_start_hhi_`m'_between)
egen end_hhi_`m'_between = mean(h_end_hhi_`m'_between)


gen perc_change_hhi_`m' =   (100 - (end_hhi_`m'*100/start_hhi_`m')) * (-1)
gen perc_change_hhi_`m'_within = ((start_hhi_`m'_within - end_hhi_`m'_within  )*100 / (start_hhi_`m' - end_hhi_`m')) * perc_change_hhi_`m' / 100 
gen perc_change_hhi_`m'_between = ((start_hhi_`m'_between - end_hhi_`m'_between  )*100 / (start_hhi_`m' - end_hhi_`m')) * perc_change_hhi_`m' / 100 
}

collapse(mean)  hhi_*_eu    hhi_*_country_within   hhi_*_country_between   perc_change_hhi_rev perc_change_hhi_rk perc_change_hhi_l perc_change_hhi_rva_pos perc_change_hhi_lc perc_change_hhi_ifa  perc_change_hhi_*_within  perc_change_hhi_*_between   , by(year  )
order year

// hhi_eu : column 1
// hhi_country_within  column 2
// hhi_country_between  column 3
// perc_change_hhi : last row column 1
// perc_change_hhi_within : last row column 2
// perc_change_hhi_between : last row column 3
export excel using "$savepath\\Replication results\Table3_col1_3.xls ", firstrow(variables)  keepcellfmt replace
restore 


// Columns 4-6
************** 
preserve	
keep if year >=  $start_year & year <=  $end_year
// gen mac_sec weights

foreach m in rev rk l rva_pos lc ifa {
bys mac_sector year: egen tot_`m'_mac= total(`m'_tot)
gen tot_`m'_mac_sq = tot_`m'_mac^2
gen mac_`m'_weight = tot_`m'_mac_sq /eu_`m'_sum_sq
bys year mac_sector: egen  hhi_`m'_mac_all = total((hhi_`m'_mac*`m'_tot_sq)/tot_`m'_mac_sq)
}

keep mac_sector year mac_*_weight eu_*_sum_sq tot_*_mac_sq  hhi_*_mac_all hhi_*_eu
duplicates drop

//gen mean mac weight and mean macro sector HHI
foreach m in rev rk l rva_pos lc ifa {
bys year: egen mean_mac_`m'_weight = mean(mac_`m'_weight)
by year: egen mean_hhi_`m'_mac   = mean(hhi_`m'_mac_all)
}

 
//gen number of IDs
bys mac_sector: gen n = _n
bys n: egen N_ids_h = total(n) if n == 1
bys mac_sector: egen N_ids = mean(N_ids_h)
drop n 

//decomposition
foreach m in rev rk l rva_pos lc ifa {
gen hhi_`m'_mac_within =  N_ids * mean_mac_`m'_weight * mean_hhi_`m'_mac
bys year: egen hhi_`m'_mac_between= total ((hhi_`m'_mac_all - mean_hhi_`m'_mac )*(mac_`m'_weight - mean_mac_`m'_weight))


//checking
bys year: egen check_hhi_`m'_eu_from_mac = total(hhi_`m'_mac_all*mac_`m'_weight)  
gen check_hhi_`m'_eu_decomp = hhi_`m'_mac_within + hhi_`m'_mac_between
su hhi_`m'_eu check_hhi_`m'_eu_decomp  check_hhi_`m'_eu_from_mac
}


keep year   hhi_*_eu     hhi_*_mac_within   hhi_*_mac_between
duplicates drop 

egen min_year = min(year)
egen max_year = max(year)


//percentage contribution within vs between
foreach m in rev rk l rva_pos lc ifa {
gen h_start_hhi_`m' = hhi_`m'_eu  if  min_year ==year
gen h_end_hhi_`m' = hhi_`m'_eu  if  max_year ==year

egen start_hhi_`m' = mean(h_start_hhi_`m')
egen end_hhi_`m' = mean(h_end_hhi_`m')


gen h_start_hhi_`m'_within = hhi_`m'_mac_within  if  min_year ==year
gen h_end_hhi_`m'_within = hhi_`m'_mac_within  if  max_year ==year

egen start_hhi_`m'_within = mean(h_start_hhi_`m'_within)
egen end_hhi_`m'_within = mean(h_end_hhi_`m'_within)


gen h_start_hhi_`m'_between = hhi_`m'_mac_between  if  min_year ==year
gen h_end_hhi_`m'_between = hhi_`m'_mac_between  if  max_year ==year

egen start_hhi_`m'_between = mean(h_start_hhi_`m'_between)
egen end_hhi_`m'_between = mean(h_end_hhi_`m'_between)


gen perc_change_hhi_`m' =   (100 - (end_hhi_`m'*100/start_hhi_`m')) * (-1)
gen perc_change_hhi_`m'_within = ((start_hhi_`m'_within - end_hhi_`m'_within  )*100 / (start_hhi_`m' - end_hhi_`m')) * perc_change_hhi_`m' / 100 
gen perc_change_hhi_`m'_between = ((start_hhi_`m'_between - end_hhi_`m'_between  )*100 / (start_hhi_`m' - end_hhi_`m')) * perc_change_hhi_`m' / 100 
}

collapse(mean)  hhi_*_eu    hhi_*_mac_within   hhi_*_mac_between   perc_change_hhi_rev perc_change_hhi_rk perc_change_hhi_l perc_change_hhi_rva_pos perc_change_hhi_lc perc_change_hhi_ifa   perc_change_hhi_*_within  perc_change_hhi_*_between   , by(year  )
order year

// hhi_eu 	column 1
// hhi_mac_within 	column 4
// hhi_mac_between  column 5
// perc_change_hhi_within last row column 4
// perc_change_hhi_between last row column 5

export excel using "$savepath\\Replication results\Table3_col4_6.xls", firstrow(variables)  keepcellfmt replace

restore

}

// Table 4
*************
{
foreach m in rev rk l rva_pos lc ifa {	
bys year country: egen  hhi_`m'_id=total((hhi_`m'_mac*`m'_tot_sq)/eu_`m'_sum_sq)
gen id_`m'_share=(hhi_`m'_id/hhi_`m'_eu)*100 

bys year country mac_sector: egen  hhi_`m'_id_coun_mac=total((hhi_`m'_mac*`m'_tot_sq)/eu_`m'_sum_sq)
gen id_`m'_share_coun_mac=(hhi_`m'_id_coun_mac/hhi_`m'_eu)*100 

bys year  mac_sector: egen  hhi_`m'_id_mac=total((hhi_`m'_mac*`m'_tot_sq)/eu_`m'_sum_sq)
gen id_`m'_share_mac=(hhi_`m'_id_mac/hhi_`m'_eu)*100 
}	


preserve

keep year country id_*_share
duplicates drop

foreach m in rev rk l rva_pos lc ifa {	
gen H_id_`m'_share_$start_year = id_`m'_share if year == $start_year
gen H_id_`m'_share_$end_year = id_`m'_share if year == $end_year 

bys country: egen mean_id_`m'_share  = mean(id_`m'_share)
by country: egen id_`m'_share_$start_year  = mean(H_id_`m'_share_$start_year)
by country: egen id_`m'_share_$end_year  = mean(H_id_`m'_share_$end_year)

bys year: egen test_`m'_mean = total(mean_id_`m'_share)
by year: egen test_`m'_$start_year = total(id_`m'_share_$start_year)
by year: egen test_`m'_$end_year = total(id_`m'_share_$end_year)


//ordering the contributions
egen help_`m' = group(mean_id_`m'_share country)
}

collapse(mean)   mean_id_*_share  id_*_share_$start_year  id_*_share_$end_year test_*_mean  test_*_$start_year  test_*_$end_year   , by(country  )

keep country	 id_*_share_2010 id_*_share_2018

// id_share_2009: column 1
// id_share_2016: column 2

export excel using "$savepath\\Replication results\Table4_col1_2.xls", firstrow(variables)  keepcellfmt replace	
restore

preserve 
keep if year==$start_year | year==$end_year
keep country year mac_sector hhi_*_count
collapse(mean) hhi_*_count, by(year country)
// hhi_count columns 3 and 4
export excel using "$savepath\\Replication results\Table4_col3_4.xls", firstrow(variables)  keepcellfmt replace	
restore

 preserve
 //units share europe
foreach m in rev rk l rva_pos lc ifa { 
bys year: egen Europe_`m' = total(`m'_tot)
gen Country_`m'_share =  count_`m'_sum / Europe_`m'
}

keep if year==$start_year | year==$end_year 
keep country year mac_sector Country_*_share 
collapse(mean) Country_*_share, by(year country)

foreach m in rev rk l rva_pos lc ifa { 
gen `m'_share=Country_`m'_share*100 // columns 5 and 6 
}
keep country *_share year 
drop Country_*_share
 export excel using "$savepath\\Replication results\Table4_col5_6.xls", firstrow(variables)  keepcellfmt replace	
 restore

}

// Table 5 
************
{


preserve

keep year mac_sector id_*_share_mac
duplicates drop

foreach m in rev rk l rva_pos lc ifa { 
gen H_id_`m'_share_$start_year = id_`m'_share_mac if year == $start_year
gen H_id_`m'_share_$end_year = id_`m'_share_mac if year == $end_year  

bys mac_sector: egen mean_id_`m'_share  = mean(id_`m'_share_mac)
by mac_sector: egen id_`m'_share_$start_year  = mean(H_id_`m'_share_$start_year)
by mac_sector: egen id_`m'_share_$end_year  = mean(H_id_`m'_share_$end_year)
}

collapse(mean)  id_*_share_$start_year  id_*_share_$end_year   , by(mac_sector )

export excel using "$savepath\\Replication results\Table5_col1_2.xls", firstrow(variables)  keepcellfmt replace	
// id_share_2009: column 1
// id_share_2016: column 2
	
restore	
	
preserve 
keep if year==$start_year | year==$end_year

foreach m in rev rk l rva_pos lc ifa { 
bys mac_sector year: egen `m'_tot_mac= total(`m'_tot)
gen `m'_tot_mac_sq = `m'_tot_mac^2

bys year mac_sector: egen  hhi_`m'_mac_all = total((hhi_`m'_mac*`m'_tot_sq)/`m'_tot_mac_sq)
}

keep country year mac_sector hhi_*_mac hhi_*_mac_all
collapse(mean) hhi_*_mac_all, by(year mac_sector)
// hhi_mac_all*100  columns 3 and 4
 export excel using "$savepath\\Replication results\Table5_col3_4.xls", firstrow(variables)  keepcellfmt replace	
 restore	

 preserve
 //rev share europe by macro sector
foreach m in rev rk l rva_pos lc ifa {
bys mac_sector year: egen `m'_tot_mac= total(`m'_tot)
bys year: egen Europe_`m' = total(`m'_tot)
gen mac_`m'_share =  `m'_tot_mac / Europe_`m'
}

keep if year==$start_year | year==$end_year 
keep country year mac_sector mac_*_share 
collapse(mean) mac_*_share, by(year mac_sector)

foreach m in rev rk l rva_pos lc ifa {
gen `m'_share=mac_`m'_share*100 // columns 5 and 6 
}

keep mac_sector *_share year 
drop mac_*_share
 export excel using "$savepath\\Replication results\Table5_col5_6.xls", firstrow(variables)  keepcellfmt replace	
 restore
}

/*
// Table 6
*************
// columns 1, 4, 5 have been already calculated in, respectively, table 4 column 6, table 4 column 4, table 4 column 2
{
preserve
keep if year==$end_year	
bys year : egen europe_sum=total(totrev)	
gen country_rev_share=(count_sum/europe_sum)*100  // column 1 

//hhi_count column 4
// id_share: column 5

collapse(mean) country_rev_share hhi_count id_share, by(country)	
	
/* We imported data from Eurostat. We use the Annual Enterprise Statistics for special aggregates of activities (Nace Rev. 2) [sbs_na_sca_r2]
Version of 11.11.2020
The data are downloaded in the file "turnover by nace eurostat.xls"
The sheet "Data" columns A-K includes the data as downloaded from Eurostat
Column O computes the sales of share of our narrow sample of macro sectors (which corresponds to column 2 of table 6)
Column M computes the sales of share of the entire economy (which corresponds to column 3 of table 6)	
The Sheet1 includes the same data organized for an easier import in stata. The same organized data are saved in "revenue_share_Eurostat.dta"
*/	
merge 1:1 country using	"$data_source_path\\revenue_share_Eurostat.dta"
drop _merge


// Countefactual analysis
**************************
gen compnet_revshare_2=column2^2
gen eurostat_revshare_2=column3^2
gen counterfactual_hhi=hhi_count*compnet_revshare 
gen counterfactual_hhi2=hhi_count*eurostat_revshare 
egen  tot_column6=sum(counterfactual_hhi)
egen  tot_column7=sum(counterfactual_hhi2)
gen column6=(counterfactual_hhi/tot_column6 )*100
gen column7=(counterfactual_hhi2/tot_column7)*100
gen hhi_col8=.
replace hhi_col8= hhi_count*1.5 if country!= "GERMANY"
replace hhi_col8=hhi_count if country=="GERMANY"

gen counterfactual_col8=hhi_col8*eurostat_revshare
egen tot_column8=sum(counterfactual_col8)
gen column8=(counterfactual_col8/tot_column8)*100
keep country column2 column3 hhi_count column6 column7 column8
export excel using "$savepath\\Replication results\Table6.xls", firstrow(variables)  keepcellfmt replace	
}
cap noisily restore


clear
   use "$data_source_path\unconditional_mac_sector_weighted_20e.dta" 
  merge 1:1 country mac year using "$data_source_path\op_decomp_mac_sector_weighted_20e.dta"
gen start_year=$start_year
gen end_year=$end_year 

foreach x in   $drop_mac  {
drop if mac == `x' 
}
foreach x in   $drop_country  {
drop if country == "`x'" 
}
drop $country_drop


gen lprod_wmn =  $labor_prod
gen lprod_mean =  $labor_prod_unwe
gen lprod_op=$labor_prod_op	

gen L = $employment
gen sum_weights_L = $sum_weights_employ

//gen aggregates 

//employee weights for labor
gen totL=L*sum_weights_L

// employment shares across countries
bys year country : egen totL_country=total(totL)
bys year : egen totL_eu=total(totL)
gen L_eu_share=totL_country/totL_eu
preserve
collapse(mean) L_eu_share, by(year country)
restore

// Table 7
***********
{

keep if year >=  $start_year & year <=  $end_year   
drop if country == "ROMANIA" & mac == 8 

//eu totals and manufacturing eu totals
gen flag = 1 if lprod_wmn!=. 
bys year: egen eu_sum_L = total(totL*flag)
by year: egen eu_sum_numb_firms_L = total(sum_weights_L*flag)
by year: egen  lprod_eu_weighted = total((lprod_wmn*totL *flag)/eu_sum_L)
by year: egen  lprod_eu_mean = total((lprod_mean*sum_weights_L *flag)/eu_sum_numb_firms_L)
gen lprod_eu_op = lprod_eu_weighted - lprod_eu_mean
// country decomposition of lprod_eu_op
bys year country: egen country_sum_numb_firms_L=total(sum_weights_L*flag)
bys year : egen totL_country_mean=mean(totL_country)

bys year : egen lprod_op_mean= total((lprod_op*sum_weights_L *flag)/country_sum_numb_firms_L)
bys year country : egen lprod_op_mean_country= total((lprod_op*sum_weights_L*flag)/country_sum_numb_firms_L)
bys year: egen lprod_op_weighted=total((lprod_op*totL*flag)/totL_country)
bys year country: egen lprod_op_country=total((lprod_op*totL*flag)/totL_country)
gen lprod_op_op=lprod_eu_weighted-lprod_eu_mean
preserve
collapse(mean) lprod_op_op lprod_op_weighted lprod_op_mean, by(year)
restore

drop flag

keep year  lprod_eu_weighted  lprod_eu_mean  lprod_eu_op 
duplicates drop 

tsset year
egen min_year = min(year)
egen max_year = max(year)


gen h_start_hhi = lprod_eu_weighted  if  min_year ==year
gen h_end_hhi = lprod_eu_weighted  if  max_year ==year

egen start_lprod_eu_weighted = mean(h_start_hhi)
egen end_lprod_eu_weighted = mean(h_end_hhi)
gen diff_lprod_eu_weighted =   end_lprod_eu_weighted - start_lprod_eu_weighted 

gen h_start_hhi_within = lprod_eu_mean  if  min_year ==year
gen h_end_hhi_within = lprod_eu_mean  if  max_year ==year

egen start_lprod_eu_mean = mean(h_start_hhi_within)
egen end_lprod_eu_mean = mean(h_end_hhi_within)
gen diff_lprod_eu_mean =   end_lprod_eu_mean - start_lprod_eu_mean 


gen h_start_hhi_between = lprod_eu_op  if  min_year ==year
gen h_end_hhi_between = lprod_eu_op  if  max_year ==year

egen start_lprod_eu_op = mean(h_start_hhi_between)
egen end_lprod_eu_op = mean(h_end_hhi_between)
gen diff_lprod_eu_op =   end_lprod_eu_op - start_lprod_eu_op 



gen perc_lprod_eu_weighted  =  (100- (end_lprod_eu_weighted*100/start_lprod_eu_weighted)) *-1
gen perc_lprod_eu_mean =  ((diff_lprod_eu_mean *100 ) / (diff_lprod_eu_weighted)) *  perc_lprod_eu_weighted / 100
gen perc_lprod_eu_op =  ((diff_lprod_eu_op *100 ) / (diff_lprod_eu_weighted)) *  perc_lprod_eu_weighted / 100


gen yearly_perc_lprod_eu_weighted  =  (100- (lprod_eu_weighted*100/l.lprod_eu_weighted)) *-1
gen yearly_perc_lprod_eu_mean =  (((lprod_eu_mean - l.lprod_eu_mean) *100 ) / (lprod_eu_weighted - l.lprod_eu_weighted)) *  yearly_perc_lprod_eu_weighted / 100
gen yearly_perc_lprod_eu_op =  (((lprod_eu_op - l.lprod_eu_op) *100 ) / (lprod_eu_weighted - l.lprod_eu_weighted)) *  yearly_perc_lprod_eu_weighted / 100

collapse(mean) perc_lprod_eu_weighted  perc_lprod_eu_mean  perc_lprod_eu_op  yearly_perc_lprod_eu_weighted  yearly_perc_lprod_eu_mean   yearly_perc_lprod_eu_op          , by(year  )
order year
	 export excel using "$savepath\\Replication results\Table7.xls", firstrow(variables)  keepcellfmt replace	

}
*/

// REGRESSIONS
*************

clear
   use "$data_source_path\unconditional_industry2d_20e_unweighted.dta" 
  keep country year industry2d $sec_rev_top10 $sec_ifa_top10 $sec_rk_top10 $sec_l_top10 $sec_lc_top10 $sec_rva_pos_top10
   save "$data_source_path\Top10_shares.dta", replace

   use "$data_source_path\unconditional_industry2d_20e_weighted.dta" 
  merge 1:1 country industry2d year using "$data_source_path\op_decomp_industry2d_20e_weighted.dta"	
  keep if _merge==3
  drop _merge
  merge 1:1 country industry2d year using "$data_source_path\Top10_shares.dta"

 rename industry2d sector 
  
//country
foreach x in   $drop_country  {
drop if country == "`x'" 
}

drop $sector_drop
drop $country_drop

egen dummy_country = group(country)
egen dummy_sector = group(sector)


//gen variables
gen hhi_rev_sec = 100*$sec_revHHI
gen hhi_ifa_sec = 100*$sec_ifaHHI
gen hhi_rk_sec = 100*$sec_rkHHI
gen hhi_l_sec = 100*$sec_lHHI
gen hhi_lc_sec = 100*$sec_lcHHI
gen hhi_rva_pos_sec = 100*$sec_rva_posHHI

gen lprod_AGG =  $sec_agg_labor_prod
gen lprod_MEAN =  $sec_mean_labor_prod
gen lprod_OP =  $sec_op_labor_prod
gen mean_size_firm = $mean_size_firm

gen capital  = $capital
gen sum_weights_capital = $sum_weights_cap

gen labor  = $employment
gen sum_weights_labor = $sum_weights_employ

gen sales  = $sales
gen sum_weights_sales = $sum_weights_sales

gen total_l = $sum_weights_employ*$employment
gen total_k=$sum_weights_cap*$capital
gen total_rev=$sum_weights_sales*$sales
gen total_rev_real=$sum_weights_real_sales*$real_sales

gen total_va=$sum_weights_va*$va

gen cap_lab = total_k /  total_l

gen sec_rev_top10=$sec_rev_top10 *100
gen sec_ifa_top10=$sec_ifa_top10 *100
gen sec_rk_top10=$sec_rk_top10 *100
gen sec_l_top10=$sec_l_top10 *100
gen sec_lc_top10=$sec_lc_top10 *100
gen sec_rva_pos_top10=$sec_rva_pos_top10 *100

gen sec_agg_labor_prod=$sec_agg_labor_prod
gen sec_mean_labor_prod=$sec_mean_labor_prod
gen sec_op_labor_prod=$sec_op_labor_prod
gen median_size_firm=$median_size_firm
cap gen mean_size_firm = $mean_size_firm

*gen industry_markup=$Preferred_markup

gen sec_mrktpw_rev=$Markup
gen sec_mrktpw_rk=$Markdown_rk
gen sec_mrktpw_l=$Markdown_l
gen sec_mrktpw_rva_pos=$Markdown_rva_pos

gen sec_agg_tfp_prod=$sec_agg_tfp_prod
gen sec_mean_tfp_prod=$sec_mean_tfp_prod
gen sec_op_tfp_prod=$sec_op_tfp_prod

foreach x in $log_variables {
gen ln_`x'=log(`x')
}

gen mac=0

replace mac=1 if sector>=10&sector<34


replace mac=4 if sector >=49&sector<54

replace mac=6 if sector >=58&sector <64
replace mac=7 if sector==68
replace mac=8 if sector>=69&sector<76
replace mac=9 if sector>=77&sector<83

foreach m in rev rk l rva_pos lc ifa {
	gen topc_`m'=0
	bys year: egen pct_`m'=pctile(hhi_`m'_sec), p(80)
	replace topc_`m'=1 if hhi_`m'_sec>pct_`m'
	drop pct_`m'
}


gen high_medium_tech=0
gen medium_low_tech=0
replace high_medium_tech=1 if sector==21|sector==26|sector==20|sector==27|sector==28|sector==29|sector==30
//services
replace high_medium_tech=1 if sector==50|sector==51|sector==78|sector==80
replace high_medium_tech=1 if sector>= 58 & sector <= 63
replace high_medium_tech=1 if sector>= 64 & sector <= 66
replace high_medium_tech=1 if sector>= 69 & sector <= 75
replace high_medium_tech=1 if sector>= 84 & sector <= 93



replace medium_low_tech=1 if sector==19|sector==33|sector==31|sector==32
replace medium_low_tech=1 if sector>21&sector<26
replace medium_low_tech=1 if sector>9&sector<19
//services
replace medium_low_tech=1 if sector>=45&sector<=47
replace medium_low_tech=1 if sector==49|sector==52|sector==53|sector==55|sector==56|sector==68|sector==77|sector==79|sector==81|sector==82 
replace medium_low_tech=1 if sector>=94&sector<=96
replace medium_low_tech=1 if sector>=97&sector<=99

//// statistics on high_tech and low_tech
gen employment=$employment
gen sum_weights_employ=$sum_weights_employ
gen tot_rev=sales*sum_weights_sales
gen tot_l=employment*sum_weights_employ
bys country year: egen agg_rev=total(tot_rev)
bys country year : egen agg_l=total(tot_l)

// Table 8
************
drop if sec_agg_labor_prod==.|sec_mean_labor_prod==.|sec_op_labor_prod==.|ln_sec_mrktpw_rev==.|ln_sec_mrktpw_l==.|ln_sec_mrktpw_rk==.|ln_sec_mrktpw_rva_pos==.|ln_mean_size_firm==.

egen id= group(dummy_sector dummy_country)
{
	foreach m in rev rk l rva_pos lc ifa {
foreach x in sec_agg_labor_prod sec_mean_labor_prod sec_op_labor_prod {	
reghdfe hhi_`m'_sec `x' cap_lab, vce(cluster sector) absorb(i.year i.dummy_sector#dummy_country)
outreg2 using "$savepath\\Replication results\Table8_`m'.xls",  append  ctitle(`id') adds( # of Clusters , `e(N_clust)' ) 
reghdfe hhi_`m'_sec `x' cap_lab ln_sec_mrktpw_rev ln_sec_mrktpw_l ln_sec_mrktpw_rk ln_sec_mrktpw_rva_pos, vce(cluster sector) absorb(i.year i.dummy_sector#dummy_country)
outreg2 using "$savepath\\Replication results\Table8_`m'.xls",  append  ctitle(`id') adds( # of Clusters , `e(N_clust)' ) 
reghdfe hhi_`m'_sec `x' cap_lab ln_mean_size_firm ln_sec_mrktpw_rev ln_sec_mrktpw_l ln_sec_mrktpw_rk ln_sec_mrktpw_rva_pos, vce(cluster sector) absorb(i.year i.dummy_sector#dummy_country)
outreg2 using "$savepath\\Replication results\Table8_`m'.xls",  append  ctitle(`id') adds( # of Clusters , `e(N_clust)' ) 
}

}

}

// Table TOPC
****************

{
	foreach m in rev rk l rva_pos lc ifa {
foreach x in sec_agg_labor_prod sec_mean_labor_prod sec_op_labor_prod {	 
reghdfe hhi_`m'_sec `x' cap_lab ln_mean_size_firm ln_sec_mrktpw_rev ln_sec_mrktpw_l ln_sec_mrktpw_rk ln_sec_mrktpw_rva_pos if topc_`m'==1, vce(cluster sector) absorb(i.year i.dummy_sector#dummy_country)
outreg2 using "$savepath\\Replication results\Table_topc_`m'.xls",  append  ctitle(`id') adds( # of Clusters , `e(N_clust)' ) 
}

}

}  


// Table EXP SH
****************

{
	foreach m in rev rk l rva_pos lc ifa {
foreach x in sec_agg_labor_prod sec_mean_labor_prod sec_op_labor_prod {	 
reghdfe hhi_`m'_sec `x' cap_lab ln_mean_size_firm ln_sec_mrktpw_rev ln_sec_mrktpw_l ln_sec_mrktpw_rk ln_sec_mrktpw_rva_pos TR02_exp_adj_rev_mn, vce(cluster sector) absorb(i.year i.dummy_sector#dummy_country)
outreg2 using "$savepath\\Replication results\Table_expsh_`m'.xls",  append  ctitle(`id') adds( # of Clusters , `e(N_clust)' ) 
}

}

}

// Table WAGE
****************

{
	foreach m in rev rk l rva_pos lc ifa {
foreach x in sec_agg_labor_prod sec_mean_labor_prod sec_op_labor_prod {	 
reghdfe hhi_`m'_sec `x' cap_lab ln_mean_size_firm ln_sec_mrktpw_rev ln_sec_mrktpw_l ln_sec_mrktpw_rk ln_sec_mrktpw_rva_pos LV24_rwage_mn, vce(cluster sector) absorb(i.year i.dummy_sector#dummy_country)
outreg2 using "$savepath\\Replication results\Table_wage_`m'.xls",  append  ctitle(`id') adds( # of Clusters , `e(N_clust)' ) 
}

}

}

// Table FOREIGN
****************

{
	foreach m in rev rk l rva_pos lc ifa {
foreach x in sec_agg_labor_prod sec_mean_labor_prod sec_op_labor_prod {	 
reghdfe hhi_`m'_sec `x' cap_lab ln_mean_size_firm ln_sec_mrktpw_rev ln_sec_mrktpw_l ln_sec_mrktpw_rk ln_sec_mrktpw_rva_pos OD05_foreign_own_mn, vce(cluster sector) absorb(i.year i.dummy_sector#dummy_country)
outreg2 using "$savepath\\Replication results\Table_foreign_`m'.xls",  append  ctitle(`id') adds( # of Clusters , `e(N_clust)' ) 
}

}

}

// Table ENERGY
****************

{
	foreach m in rev rk l rva_pos lc ifa {
foreach x in sec_agg_labor_prod sec_mean_labor_prod sec_op_labor_prod {	 
reghdfe hhi_`m'_sec `x' cap_lab ln_mean_size_firm ln_sec_mrktpw_rev ln_sec_mrktpw_l ln_sec_mrktpw_rk ln_sec_mrktpw_rva_pos FR40_ener_costs_mn, vce(cluster sector) absorb(i.year i.dummy_sector#dummy_country)
outreg2 using "$savepath\\Replication results\Table_energy_`m'.xls",  append  ctitle(`id') adds( # of Clusters , `e(N_clust)' ) 
}

}

}


// Table 9
************
{
levelsof country
foreach country in `r(levels)' {	
	foreach m in rev rk l rva_pos lc ifa {
foreach x in sec_agg_labor_prod sec_mean_labor_prod sec_op_labor_prod {	

reghdfe hhi_`m'_sec `x' cap_lab ln_mean_size_firm ln_sec_mrktpw_rev ln_sec_mrktpw_l ln_sec_mrktpw_rk ln_sec_mrktpw_rva_pos if country=="`country'" , vce(cluster sector) absorb(i.year i.dummy_sector)
outreg2 using "$savepath\\Replication results\Table9_`m'.xls",  append  ctitle(`country') adds( # of Clusters , `e(N_clust)' ) 
}

}
}
}


// Table 10
*************
{
levelsof mac
foreach mac in `r(levels)' {	
	foreach m in rev rk l rva_pos lc ifa {
foreach x in sec_agg_labor_prod sec_mean_labor_prod sec_op_labor_prod {		
reghdfe hhi_`m'_sec `x' cap_lab ln_mean_size_firm ln_sec_mrktpw_rev ln_sec_mrktpw_l ln_sec_mrktpw_rk ln_sec_mrktpw_rva_pos if mac==`mac' , vce(robust) absorb(year i.dummy_sector#dummy_country)
outreg2 using "$savepath\\Replication results\Table10_`m'.xls",  append  ctitle(`mac') 
}	

}
}
}	

// we estimate the coefficients of macro sector 7 (real estate) without clustering at sector level as macro sector 7 consists of only 1 sector
	foreach m in rev rk l rva_pos lc ifa {
foreach x in sec_agg_labor_prod sec_mean_labor_prod sec_op_labor_prod {	
reghdfe hhi_`m'_sec `x' cap_lab ln_mean_size_firm ln_sec_mrktpw_rev ln_sec_mrktpw_l ln_sec_mrktpw_rk ln_sec_mrktpw_rva_pos if mac== 7 , vce(robust)   absorb(i.year i.dummy_sector#dummy_country)
outreg2 using "$savepath\\Replication results\Table10_`m'.xls",  append  ctitle(7) 
}
}

// high-tech, knowledge intensive
	foreach m in rev rk l rva_pos lc ifa {
foreach x in sec_agg_labor_prod sec_mean_labor_prod sec_op_labor_prod {	
reghdfe hhi_`m'_sec `x' cap_lab ln_mean_size_firm ln_sec_mrktpw_rev ln_sec_mrktpw_l ln_sec_mrktpw_rk ln_sec_mrktpw_rva_pos if high_medium_tech==1 , vce(robust)  absorb(i.year i.dummy_sector#dummy_country)
outreg2 using "$savepath\\Replication results\Table10_`m'.xls",  append  ctitle("hightech")
}
	}

// low-tech, not knowledge intensive 
	foreach m in rev rk l rva_pos lc ifa {
foreach x in sec_agg_labor_prod sec_mean_labor_prod sec_op_labor_prod {	
reghdfe hhi_`m'_sec `x' cap_lab ln_mean_size_firm ln_sec_mrktpw_rev ln_sec_mrktpw_l ln_sec_mrktpw_rk ln_sec_mrktpw_rva_pos if medium_low_tech==1 , vce(robust)  absorb(i.year i.dummy_sector#dummy_country)
outreg2 using "$savepath\\Replication results\Table10_`m'.xls",  append  ctitle("lowtech") 
}
    }

// Table 11
************
	foreach m in rev rk l rva_pos lc ifa {
drop if sec_`m'_top10==.
	}

{
		foreach m in rev rk l rva_pos lc ifa {
foreach x in sec_agg_labor_prod sec_mean_labor_prod sec_op_labor_prod   {	
reghdfe sec_`m'_top10 `x' cap_lab, vce(cluster sector) absorb(i.year i.dummy_sector#dummy_country)
outreg2 using "$savepath\\Replication results\Table11_`m'.xls",  append  ctitle(`id') adds( # of Clusters , `e(N_clust)' ) 

reghdfe sec_`m'_top10 `x' cap_lab ln_mean_size_firm ln_sec_mrktpw_rev ln_sec_mrktpw_l ln_sec_mrktpw_rk ln_sec_mrktpw_rva_pos, vce(cluster sector) absorb(i.year i.dummy_sector#dummy_country)
outreg2 using "$savepath\\Replication results\Table11_`m'.xls",  append  ctitle(`id') adds( # of Clusters , `e(N_clust)' ) 	
	
}
}
}



