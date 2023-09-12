***********************************************************************************
* Topic 4: Energy use - Productivity Report -  *
***********************************************************************************
*** 
// In this do-file you can find the codes to create some descriptives, including:
*1. Energy intensity over time (median)
*2. Energy prices over time (all energy sources, pre- and post-tax)
// For the code to create energy mix over time, please refer to R-script "Topic4_ProdReport_Descriptives"

*** Clarifying notes
*1. Dataset(s) used: unconditional_mac_sector_20e_weighted sample, unconditional_industry2d_20e_weighted sample, 8th vintage (to include DE)
	*gdp + energy price deflators from CompNet and Eurostat respectively (from 'Deflators.dta')
*2. Definition of energy intensity: energy cost over total cost, deflated by energy price deflators and gdp deflators respectively
*3. For totals, using _sw*_mn instead of _N*_mn (ie. total energy use = FV03_n_ener_mn*FV03_n_ener_sw)
*4. This Stata code was created using a Macbook, so some editing needs to be done in the 'cd' commands if using a PC

********************************************
*** 1. Median energy intensity over time ***
********************************************

clear all
clear
eststo clear
set more off

*Set directory and open relevant data
//Mac
cd "/Users/lauralehtonen/Desktop/CompNet/Compnet Data/9th vintage/Data files"
use "unconditional_industry2d_20e_weighted.dta", clear

merge m:1 country year using "Deflators_9th" //note: we only have certain countries + for each year we have the country average deflator. 
										//therefore, every industry in a country in a given year will have the same deflator
drop _merge

*A) Calculate energy intensity
//Nominal energy inputs: FV03_n_ener_mn ; Nominal revenue: FV08_nrev_mn
//Total cost: capital cost + nominal intermediate inputs + nominal labor cost + nominal energy inputs
//capcost + nm + nlc + n_ener: FV00_capcost_ ; FV06_nm_ ; FV05_nlc_ ; FV03_n_ener_
	
	*Total cost:
	gen totcost = (FV00_capcost_mn*FV00_capcost_sw) + (FV06_nm_mn*FV06_nm_sw) + (FV05_nlc_mn*FV05_nlc_sw) + (FV03_n_ener_mn*FV03_n_ener_sw)
	label variable totcost "Total cost"
	
	*Industry energy intensity
	gen indener_intensity_1 = (FV03_n_ener_mn*FV03_n_ener_sw) / (totcost)
	gen indener_intensity = indener_intensity_1*p_gp_e 			//multiply energy intensity with p_g/p_e	
	label variable indener_intensity "Industry energy intensity"
	count if indener_intensity==0
	
	drop if indener_intensity_1==.
	drop if indener_intensity_1==0
		
	drop if country=="Malta" | country=="Croatia"
	
	tab country year
	
*B) Create median by country
egen indener_intensity_p50 = median(indener_intensity), by(country year)
egen indener_intensity_mn = mean(indener_intensity), by(country year)

*C) Graph median by country
drop if year<2007

*Median
twoway (line indener_intensity_p50 year if country=="Denmark", ///
		legend(label(1 "Denmark") size(vsmall) rows(2))) ///
		(line indener_intensity_p50 year if country=="Finland", ///
		legend(label(2 "Finland"))) ///
		(line indener_intensity_p50 year if country=="Germany", ///
		legend(label(3 "Germany"))) ///
		(line indener_intensity_p50 year if country=="Lithuania", ///
		legend(label(4 "Lithuania"))) ///
		(line indener_intensity_p50 year if country=="Poland", ///
		legend(label(5 "Poland"))) ///
		(line indener_intensity_p50 year if country=="Portugal", ///
		legend(label(6 "Portugal"))) ///
		(line indener_intensity_p50 year if country=="Slovakia", ///
		legend(label(7 "Slovakia"))) ///
		(line indener_intensity_p50 year if country=="Slovenia", ///
		legend(label(8 "Slovenia")) ///
		ytitle(Energy intensity (p50), size(small)) ylabel(, labsize(small)) ///
		xtitle("") xlabel(2007(2)2021, labsize(small)) ///
		scheme(s2color) ///
		graphregion(color(white) fcolor(white)) plotregion(color(white)) fcolor(white))
		graph export energy_intensity.pdf


*Median
twoway (line indener_intensity_p50 year if country=="Denmark", lcolor(edkblue) ///
		legend(label(1 "Denmark") size(vsmall) rows(2))) ///
		(line indener_intensity_p50 year if country=="Finland", lcolor(cranberry) ///
		legend(label(2 "Finland"))) ///
		(line indener_intensity_p50 year if country=="Germany", lcolor(dkgreen) ///
		legend(label(3 "Germany"))) ///
		(line indener_intensity_p50 year if country=="Lithuania", lcolor(gold) ///
		legend(label(4 "Lithuania"))) ///
		(line indener_intensity_p50 year if country=="Poland", lcolor(dkorange) ///
		legend(label(5 "Poland"))) ///
		(line indener_intensity_p50 year if country=="Portugal", lcolor(gs10) ///
		legend(label(6 "Portugal"))) ///
		(line indener_intensity_p50 year if country=="Slovakia", lcolor(maroon) ///
		legend(label(7 "Slovakia"))) ///
		(line indener_intensity_p50 year if country=="Slovenia", lcolor(black) ///
		legend(label(8 "Slovenia")) ///
		ytitle(Energy intensity (p50), size(small)) ylabel(, labsize(small)) ///
		xtitle("") xlabel(2007(2)2021, labsize(small)) ///
		graphregion(color(white) fcolor(white)) plotregion(color(white) fcolor(white)) ///
		note("Source: CompNet 9th Vintage, unconditional_industry2d_20e_weighted.dta" ///
		"Note: Energy intensity is defined as nominal energy costs over nominal total costs." , size(vsmall)))

*Mean		
twoway (line indener_intensity_mn year if country=="Denmark", lcolor(edkblue) ///
		legend(label(1 "Denmark") size(vsmall) rows(2))) ///
		(line indener_intensity_mn year if country=="Finland", lcolor(cranberry) ///
		legend(label(2 "Finland"))) ///
		(line indener_intensity_mn year if country=="Germany", lcolor(dkgreen) ///
		legend(label(3 "Germany"))) ///
		(line indener_intensity_mn year if country=="Lithuania", lcolor(gold) ///
		legend(label(4 "Lithuania"))) ///
		(line indener_intensity_mn year if country=="Poland", lcolor(dkorange) ///
		legend(label(5 "Poland"))) ///
		(line indener_intensity_mn year if country=="Portugal", lcolor(gs10) ///
		legend(label(6 "Portugal"))) ///
		(line indener_intensity_mn year if country=="Slovakia", lcolor(maroon) ///
		legend(label(7 "Slovakia"))) ///
		(line indener_intensity_mn year if country=="Slovenia", lcolor(black) ///
		legend(label(8 "Slovenia")) ///
		ytitle(Energy indener_intensity_mn (p50), size(small)) ylabel(, labsize(small)) ///
		xtitle("") xlabel(2007(2)2021, labsize(small)) ///
		graphregion(color(white) fcolor(white)) plotregion(color(white) fcolor(white)) ///
		note("Source: CompNet 9th Vintage, unconditional_industry2d_20e_weighted.dta" ///
		"Note: Energy intensity is defined as nominal energy costs over nominal total costs." , size(vsmall)))		

		
		  
**
	
*********************************************	
*** 2. Evolution of average energy prices ***
*********************************************

*Housekeeping
clear all
clear
eststo clear
set more off

*Set directory and open relevant data
//Mac
global compnet_data "/Users/lauralehtonen/Desktop/CompNet/Compnet Data/9th vintage/Data files"
global cd "/Users/lauralehtonen/Desktop/CompNet/Compnet Data/Energy research"
cd "$cd"
global outdir "${cd}/Descriptives"

use "Energy_price_mix_TJ_IEA_Eurostat.dta", clear
//export excel using "Energy_price_mix_TJ_IEA_Eurostat", firstrow(variables) nolabel replace


drop if year==2021 

* 1. By country, averaging over industries

//OLD
twoway (line ELECTR_Price_afterTax year if country=="Denmark", lcolor(edkblue) ///
		legend(label(1 "Denmark") size(vsmall) cols(2))) ///
		(line ELECTR_Price_afterTax year if country=="Finland", lcolor(cranberry) ///
		legend(label(2 "Finland"))) ///
		(line ELECTR_Price_afterTax year if country=="Germany", lcolor(dkgreen) ///
		legend(label(3 "Germany"))) ///
		(line ELECTR_Price_afterTax year if country=="Lithuania", lcolor(gold) ///
		legend(label(4 "Lithuania"))) ///
		(line ELECTR_Price_afterTax year if country=="Poland", lcolor(dkorange) ///
		legend(label(5 "Poland"))) ///
		(line ELECTR_Price_afterTax year if country=="Portugal", lcolor(gs10) ///
		legend(label(6 "Portugal"))) ///
		(line ELECTR_Price_afterTax year if country=="Slovakia", lcolor(maroon) ///
		legend(label(7 "Slovakia"))) ///
		(line ELECTR_Price_afterTax year if country=="Slovenia", lcolor(black) ///
		legend(label(8 "Slovenia")) ///
		ytitle(Price (EUR/TJ), size(small)) ylabel(, labsize(small)) ///
		title("Electricity", size(medium) color(black)) ///
		xtitle("") xlabel(, labsize(small)) ///
		graphregion(color(white) fcolor(white)) plotregion(color(white) fcolor(white)) ///
		note("Source: International Energy Agency", size(vsmall)))
		graph export electricity_price_at.png, as(png) replace

//NEW	
* Electricity
twoway (line ELECTR_Price_afterTax year if country=="Denmark", ///
		legend(label(1 "Denmark") size(vsmall) cols(2))) ///
		(line ELECTR_Price_afterTax year if country=="Finland", lpattern(dash) lwidth(medthick) ///
		legend(label(2 "Finland"))) ///
		(line ELECTR_Price_afterTax year if country=="Germany", lpattern(dot) lwidth(medthick) ///
		legend(label(3 "Germany"))) ///
		(line ELECTR_Price_afterTax year if country=="Lithuania", lpattern(dash_dot) lwidth(medthick) ///
		legend(label(4 "Lithuania"))) ///
		(line ELECTR_Price_afterTax year if country=="Poland", lpattern(shortdash)  lwidth(medthick) ///
		legend(label(5 "Poland"))) ///
		(line ELECTR_Price_afterTax year if country=="Portugal", lpattern(shortdash_dot) lwidth(medthick) ///
		legend(label(6 "Portugal"))) ///
		(line ELECTR_Price_afterTax year if country=="Slovakia", lpattern(longdash) lwidth(medthick) ///
		legend(label(7 "Slovakia"))) ///
		(line ELECTR_Price_afterTax year if country=="Slovenia", lpattern(longdash_dot) lwidth(medthick) ///
		legend(label(8 "Slovenia")) ///
		ytitle(Price (EUR/TJ), size(small)) ylabel(, labsize(small)) ///
		title("Electricity", size(medium) color(black)) ///
		xtitle("") xlabel(, labsize(small)) ///
		legend(off) ///
		scheme(s2color) ///
		graphregion(color(white) fcolor(white)) plotregion(color(white) fcolor(white)))
		saving(electricity_price_at, replace)
		
twoway (line DIESEL_Price_afterTax year if country=="Denmark", ///
		legend(label(1 "Denmark") size(vsmall) cols(2))) ///
		(line DIESEL_Price_afterTax year if country=="Finland", lpattern(dash) lwidth(medthick) ///
		legend(label(2 "Finland"))) ///
		(line DIESEL_Price_afterTax year if country=="Germany", lpattern(dot) lwidth(medthick) ///
		legend(label(3 "Germany"))) ///
		(line DIESEL_Price_afterTax year if country=="Lithuania", lpattern(dash_dot) lwidth(medthick) ///
		legend(label(4 "Lithuania"))) ///
		(line DIESEL_Price_afterTax year if country=="Poland", lpattern(shortdash)  lwidth(medthick) ///
		legend(label(5 "Poland"))) ///
		(line DIESEL_Price_afterTax year if country=="Portugal", lpattern(shortdash_dot) lwidth(medthick) ///
		legend(label(6 "Portugal"))) ///
		(line DIESEL_Price_afterTax year if country=="Slovakia", lpattern(longdash) lwidth(medthick) ///
		legend(label(7 "Slovakia"))) ///
		(line DIESEL_Price_afterTax year if country=="Slovenia", lpattern(longdash_dot) lwidth(medthick) ///
		legend(label(8 "Slovenia")) ///
		ytitle(Price (EUR/TJ), size(small)) ylabel(, labsize(small)) ///
		title("Diesel", size(medium) color(black)) ///
		xtitle("") xlabel(, labsize(small)) ///
		legend(off) ///
		scheme(s2color) ///
		graphregion(color(white) fcolor(white)) plotregion(color(white) fcolor(white)))
		saving(diesel_price_at, replace)	

twoway (line NATGAS_Price_afterTax year if country=="Denmark", ///
		legend(label(1 "Denmark") size(vsmall) cols(2))) ///
		(line NATGAS_Price_afterTax year if country=="Finland", lpattern(dash) lwidth(medthick) ///
		legend(label(2 "Finland"))) ///
		(line NATGAS_Price_afterTax year if country=="Germany", lpattern(dot) lwidth(medthick) ///
		legend(label(3 "Germany"))) ///
		(line NATGAS_Price_afterTax year if country=="Lithuania", lpattern(dash_dot) lwidth(medthick) ///
		legend(label(4 "Lithuania"))) ///
		(line NATGAS_Price_afterTax year if country=="Poland", lpattern(shortdash)  lwidth(medthick) ///
		legend(label(5 "Poland"))) ///
		(line NATGAS_Price_afterTax year if country=="Portugal", lpattern(shortdash_dot) lwidth(medthick) ///
		legend(label(6 "Portugal"))) ///
		(line NATGAS_Price_afterTax year if country=="Slovakia", lpattern(longdash) lwidth(medthick) ///
		legend(label(7 "Slovakia"))) ///
		(line NATGAS_Price_afterTax year if country=="Slovenia", lpattern(longdash_dot) lwidth(medthick) ///
		legend(label(8 "Slovenia")) ///
		ytitle(Price (EUR/TJ), size(small)) ylabel(, labsize(small)) ///
		title("Natural gas", size(medium) color(black)) ///
		xtitle("") xlabel(, labsize(small)) ///
		legend(off) ///
		scheme(s2color) ///
		graphregion(color(white) fcolor(white)) plotregion(color(white) fcolor(white)))
		saving(natgas_price_at, replace)			

	*Combine graphs
cd "/Users/lauralehtonen/Desktop"	

	graph combine electricity_price_at.gph diesel_price_at.gph natgas_price_at.gph, ycommon ///
	graphregion(color(white)) plotregion(color(white))
	graph export energy_prices_at.pdf, as(pdf) replace	
	
	*Add legend - copy paste to pictrure
	twoway (line NATGAS_Price_afterTax year if country=="Denmark", ///
		legend(label(1 "Denmark") size(vsmall) cols(2))) ///
		(line NATGAS_Price_afterTax year if country=="Finland", lpattern(dash) lwidth(medthick) ///
		legend(label(2 "Finland"))) ///
		(line NATGAS_Price_afterTax year if country=="Germany", lpattern(dot) lwidth(medthick) ///
		legend(label(3 "Germany"))) ///
		(line NATGAS_Price_afterTax year if country=="Lithuania", lpattern(dash_dot) lwidth(medthick) ///
		legend(label(4 "Lithuania"))) ///
		(line NATGAS_Price_afterTax year if country=="Poland", lpattern(shortdash)  lwidth(medthick) ///
		legend(label(5 "Poland"))) ///
		(line NATGAS_Price_afterTax year if country=="Portugal", lpattern(shortdash_dot) lwidth(medthick) ///
		legend(label(6 "Portugal"))) ///
		(line NATGAS_Price_afterTax year if country=="Slovakia", lpattern(longdash) lwidth(medthick) ///
		legend(label(7 "Slovakia"))) ///
		(line NATGAS_Price_afterTax year if country=="Slovenia", lpattern(longdash_dot) lwidth(medthick) ///
		legend(label(8 "Slovenia")) ///
		ytitle(Price (EUR/TJ), size(small)) ylabel(, labsize(small)) ///
		title("Natural gas", size(medium) color(black)) ///
		xtitle("") xlabel(, labsize(small)) ///
		scheme(s2color) ///
		graphregion(color(white) fcolor(white)) plotregion(color(white) fcolor(white)))

	
*** Appendix *** 
** Energy prices pre and post-tax for each energy source
*Housekeeping
clear all
clear
eststo clear
set more off

*Set directory and open relevant data
//Mac
global compnet_data "/Users/lauralehtonen/Desktop/CompNet/Compnet Data/9th vintage/Data files"
global cd "/Users/lauralehtonen/Desktop/CompNet/Compnet Data/Energy research"

cd "$cd"
global outdir "${cd}/Descriptives"

use "Energy_price_mix_TJ_IEA_Eurostat.dta", clear


* 2. By country, averaging over industries
** A) Pre & After tax
twoway (line COAL_COKE_CRUDE_Price_afterTax year if country=="Denmark", ///
		legend(label(1 "Denmark") size(vsmall) cols(2))) ///
		(line COAL_COKE_CRUDE_Price_afterTax year if country=="Finland", lpattern(dash) lwidth(medthick) ///
		legend(label(2 "Finland"))) ///
		(line COAL_COKE_CRUDE_Price_afterTax year if country=="Germany", lpattern(dot) lwidth(medthick) ///
		legend(label(3 "Germany"))) ///
		(line COAL_COKE_CRUDE_Price_afterTax year if country=="Lithuania", lpattern(dash_dot) lwidth(medthick) ///
		legend(label(4 "Lithuania"))) ///
		(line COAL_COKE_CRUDE_Price_afterTax year if country=="Poland", lpattern(shortdash)  lwidth(medthick) ///
		legend(label(5 "Poland"))) ///
		(line COAL_COKE_CRUDE_Price_afterTax year if country=="Portugal", lpattern(shortdash_dot) lwidth(medthick) ///
		legend(label(6 "Portugal"))) ///
		(line COAL_COKE_CRUDE_Price_afterTax year if country=="Slovakia", lpattern(longdash) lwidth(medthick) ///
		legend(label(7 "Slovakia"))) ///
		(line COAL_COKE_CRUDE_Price_afterTax year if country=="Slovenia", lpattern(longdash_dot) lwidth(medthick) ///
		legend(label(8 "Slovenia")) ///
		ytitle(Price (EUR/TJ), size(small)) ylabel(, labsize(small)) ///
		title("Coal products - post-tax", size(medium) color(black)) ///
		xtitle("") xlabel(, labsize(small)) ///
		legend(off) ///
		scheme(s2color) ///
		graphregion(color(white) fcolor(white)) plotregion(color(white) fcolor(white)))
		///
		graph export coal_price_at.png, as(png) replace
		
twoway (line COAL_COKE_CRUDE_Price_preTax year if country=="Denmark", ///
		legend(label(1 "Denmark") size(vsmall) cols(2))) ///
		(line COAL_COKE_CRUDE_Price_preTax year if country=="Finland", lpattern(dash) lwidth(medthick) ///
		legend(label(2 "Finland"))) ///
		(line COAL_COKE_CRUDE_Price_preTax year if country=="Germany", lpattern(dot) lwidth(medthick) ///
		legend(label(3 "Germany"))) ///
		(line COAL_COKE_CRUDE_Price_preTax year if country=="Lithuania", lpattern(dash_dot) lwidth(medthick) ///
		legend(label(4 "Lithuania"))) ///
		(line COAL_COKE_CRUDE_Price_preTax year if country=="Poland", lpattern(shortdash)  lwidth(medthick) ///
		legend(label(5 "Poland"))) ///
		(line COAL_COKE_CRUDE_Price_preTax year if country=="Portugal", lpattern(shortdash_dot) lwidth(medthick) ///
		legend(label(6 "Portugal"))) ///
		(line COAL_COKE_CRUDE_Price_preTax year if country=="Slovakia", lpattern(longdash) lwidth(medthick) ///
		legend(label(7 "Slovakia"))) ///
		(line COAL_COKE_CRUDE_Price_preTax year if country=="Slovenia", lpattern(longdash_dot) lwidth(medthick) ///
		legend(label(8 "Slovenia")) ///
		ytitle(Price (EUR/TJ), size(small)) ylabel(, labsize(small)) ///
		title("Coal products - pre-tax", size(medium) color(black)) ///
		xtitle("") xlabel(, labsize(small)) ///
		scheme(s2color) ///
		graphregion(color(white) fcolor(white)) plotregion(color(white) fcolor(white)) ///
		legend(off))
		///
		graph export coal_price_pt.png, as(png) replace		
		
twoway (line DIESEL_Price_afterTax year if country=="Denmark", ///
		legend(label(1 "Denmark") size(vsmall) cols(2))) ///
		(line DIESEL_Price_afterTax year if country=="Finland", lpattern(dash) lwidth(medthick) ///
		legend(label(2 "Finland"))) ///
		(line DIESEL_Price_afterTax year if country=="Germany", lpattern(dot) lwidth(medthick) ///
		legend(label(3 "Germany"))) ///
		(line DIESEL_Price_afterTax year if country=="Lithuania", lpattern(dash_dot) lwidth(medthick) ///
		legend(label(4 "Lithuania"))) ///
		(line DIESEL_Price_afterTax year if country=="Poland", lpattern(shortdash)  lwidth(medthick) ///
		legend(label(5 "Poland"))) ///
		(line DIESEL_Price_afterTax year if country=="Portugal", lpattern(shortdash_dot) lwidth(medthick) ///
		legend(label(6 "Portugal"))) ///
		(line DIESEL_Price_afterTax year if country=="Slovakia", lpattern(longdash) lwidth(medthick) ///
		legend(label(7 "Slovakia"))) ///
		(line DIESEL_Price_afterTax year if country=="Slovenia", lpattern(longdash_dot) lwidth(medthick) ///
		legend(label(8 "Slovenia")) ///
		ytitle(Price (EUR/TJ), size(small)) ylabel(, labsize(small)) ///
		title("Diesel - post-tax", size(medium) color(black)) ///
		xtitle("") xlabel(, labsize(small)) ///
		legend(off) ///
		scheme(s2color) ///
		graphregion(color(white) fcolor(white)) plotregion(color(white) fcolor(white)))
		///
		graph export diesel_price_at.png, as(png) replace		
		
twoway (line DIESEL_Price_preTax year if country=="Denmark", ///
		legend(label(1 "Denmark") size(vsmall) cols(2))) ///
		(line DIESEL_Price_preTax year if country=="Finland", lpattern(dash) lwidth(medthick) ///
		legend(label(2 "Finland"))) ///
		(line DIESEL_Price_preTax year if country=="Germany", lpattern(dot) lwidth(medthick) ///
		legend(label(3 "Germany"))) ///
		(line DIESEL_Price_preTax year if country=="Lithuania", lpattern(dash_dot) lwidth(medthick) ///
		legend(label(4 "Lithuania"))) ///
		(line DIESEL_Price_preTax year if country=="Poland", lpattern(shortdash)  lwidth(medthick) ///
		legend(label(5 "Poland"))) ///
		(line DIESEL_Price_preTax year if country=="Portugal", lpattern(shortdash_dot) lwidth(medthick) ///
		legend(label(6 "Portugal"))) ///
		(line DIESEL_Price_preTax year if country=="Slovakia", lpattern(longdash) lwidth(medthick) ///
		legend(label(7 "Slovakia"))) ///
		(line DIESEL_Price_preTax year if country=="Slovenia", lpattern(longdash_dot) lwidth(medthick) ///
		legend(label(8 "Slovenia")) ///
		ytitle(Price (EUR/TJ), size(small)) ylabel(, labsize(small)) ///
		title("Diesel - pre-tax", size(medium) color(black)) ///
		xtitle("") xlabel(, labsize(small)) ///
		legend(off) ///
		scheme(s2color) ///
		graphregion(color(white) fcolor(white)) plotregion(color(white) fcolor(white)))
		///
		graph export diesel_price_pt.png, as(png) replace				
		
twoway (line ELECTR_Price_afterTax year if country=="Denmark", ///
		legend(label(1 "Denmark") size(vsmall) cols(2))) ///
		(line ELECTR_Price_afterTax year if country=="Finland", lpattern(dash) lwidth(medthick) ///
		legend(label(2 "Finland"))) ///
		(line ELECTR_Price_afterTax year if country=="Germany", lpattern(dot) lwidth(medthick) ///
		legend(label(3 "Germany"))) ///
		(line ELECTR_Price_afterTax year if country=="Lithuania", lpattern(dash_dot) lwidth(medthick) ///
		legend(label(4 "Lithuania"))) ///
		(line ELECTR_Price_afterTax year if country=="Poland", lpattern(shortdash)  lwidth(medthick) ///
		legend(label(5 "Poland"))) ///
		(line ELECTR_Price_afterTax year if country=="Portugal", lpattern(shortdash_dot) lwidth(medthick) ///
		legend(label(6 "Portugal"))) ///
		(line ELECTR_Price_afterTax year if country=="Slovakia", lpattern(longdash) lwidth(medthick) ///
		legend(label(7 "Slovakia"))) ///
		(line ELECTR_Price_afterTax year if country=="Slovenia", lpattern(longdash_dot) lwidth(medthick) ///
		legend(label(8 "Slovenia")) ///
		ytitle(Price (EUR/TJ), size(small)) ylabel(, labsize(small)) ///
		title("Electricity - post-tax", size(medium) color(black)) ///
		xtitle("") xlabel(, labsize(small)) ///
		scheme(s2color) ///
		graphregion(color(white) fcolor(white)) plotregion(color(white) fcolor(white)) ///
		legend(off)) 
		///
		graph export electricity_price_at.png, as(png) replace
		
twoway (line ELECTR_Price_preTax year if country=="Denmark", ///
		legend(label(1 "Denmark") size(vsmall) cols(2))) ///
		(line ELECTR_Price_preTax year if country=="Finland", lpattern(dash) lwidth(medthick) ///
		legend(label(2 "Finland"))) ///
		(line ELECTR_Price_preTax year if country=="Germany", lpattern(dot) lwidth(medthick) ///
		legend(label(3 "Germany"))) ///
		(line ELECTR_Price_preTax year if country=="Lithuania", lpattern(dash_dot) lwidth(medthick) ///
		legend(label(4 "Lithuania"))) ///
		(line ELECTR_Price_preTax year if country=="Poland", lpattern(shortdash)  lwidth(medthick) ///
		legend(label(5 "Poland"))) ///
		(line ELECTR_Price_preTax year if country=="Portugal", lpattern(shortdash_dot) lwidth(medthick) ///
		legend(label(6 "Portugal"))) ///
		(line ELECTR_Price_preTax year if country=="Slovakia", lpattern(longdash) lwidth(medthick) ///
		legend(label(7 "Slovakia"))) ///
		(line ELECTR_Price_preTax year if country=="Slovenia", lpattern(longdash_dot) lwidth(medthick) ///
		legend(label(8 "Slovenia")) ///
		ytitle(Price (EUR/TJ), size(small)) ylabel(, labsize(small)) ///
		title("Electricity - pre-tax", size(medium) color(black)) ///
		xtitle("") xlabel(, labsize(small)) ///
		legend(off) ///
		scheme(s2color) ///
		graphregion(color(white) fcolor(white)) plotregion(color(white) fcolor(white)))
		///
		graph export electricity_price_pt.png, as(png) replace		
		
twoway (line FUEL_OIL_Price_afterTax year if country=="Denmark", ///
		legend(label(1 "Denmark") size(vsmall) cols(2))) ///
		(line FUEL_OIL_Price_afterTax year if country=="Finland", lpattern(dash) lwidth(medthick) ///
		legend(label(2 "Finland"))) ///
		(line FUEL_OIL_Price_afterTax year if country=="Germany", lpattern(dot) lwidth(medthick) ///
		legend(label(3 "Germany"))) ///
		(line FUEL_OIL_Price_afterTax year if country=="Lithuania", lpattern(dash_dot) lwidth(medthick) ///
		legend(label(4 "Lithuania"))) ///
		(line FUEL_OIL_Price_afterTax year if country=="Poland", lpattern(shortdash)  lwidth(medthick) ///
		legend(label(5 "Poland"))) ///
		(line FUEL_OIL_Price_afterTax year if country=="Portugal", lpattern(shortdash_dot) lwidth(medthick) ///
		legend(label(6 "Portugal"))) ///
		(line FUEL_OIL_Price_afterTax year if country=="Slovakia", lpattern(longdash) lwidth(medthick) ///
		legend(label(7 "Slovakia"))) ///
		(line FUEL_OIL_Price_afterTax year if country=="Slovenia", lpattern(longdash_dot) lwidth(medthick) ///
		legend(label(8 "Slovenia")) ///
		legend(off) ///
		ytitle(Price (EUR/TJ), size(small)) ylabel(, labsize(small)) ///
		title("Fuel oil - post-tax", size(medium) color(black)) ///
		xtitle("") xlabel(, labsize(small)) ///
		scheme(s2color) ///
		graphregion(color(white) fcolor(white)) plotregion(color(white) fcolor(white)))
		///
		graph export fuel_oil_price_at.png, as(png) replace	 
					
twoway (line FUEL_OIL_Price_preTax year if country=="Denmark", ///
		legend(label(1 "Denmark") size(vsmall) cols(2))) ///
		(line FUEL_OIL_Price_preTax year if country=="Finland", lpattern(dash) lwidth(medthick) ///
		legend(label(2 "Finland"))) ///
		(line FUEL_OIL_Price_preTax year if country=="Germany", lpattern(dot) lwidth(medthick) ///
		legend(label(3 "Germany"))) ///
		(line FUEL_OIL_Price_preTax year if country=="Lithuania", lpattern(dash_dot) lwidth(medthick) ///
		legend(label(4 "Lithuania"))) ///
		(line FUEL_OIL_Price_preTax year if country=="Poland", lpattern(shortdash)  lwidth(medthick) ///
		legend(label(5 "Poland"))) ///
		(line FUEL_OIL_Price_preTax year if country=="Portugal", lpattern(shortdash_dot) lwidth(medthick) ///
		legend(label(6 "Portugal"))) ///
		(line FUEL_OIL_Price_preTax year if country=="Slovakia", lpattern(longdash) lwidth(medthick) ///
		legend(label(7 "Slovakia"))) ///
		(line FUEL_OIL_Price_preTax year if country=="Slovenia", lpattern(longdash_dot) lwidth(medthick) ///
		legend(label(8 "Slovenia")) ///
		ytitle(Price (EUR/TJ), size(small)) ylabel(, labsize(small)) ///
		title("Fuel oil - pre-tax", size(medium) color(black)) ///
		xtitle("") xlabel(, labsize(small)) ///
		scheme(s2color) ///
		graphregion(color(white) fcolor(white)) plotregion(color(white) fcolor(white)) ///
		legend(off)) 
		///
		graph export fuel_oil_price_pt.png, as(png) replace	
		
twoway (line GASOLINE_Price_afterTax year if country=="Denmark", ///
		legend(label(1 "Denmark") size(vsmall) cols(2))) ///
		(line GASOLINE_Price_afterTax year if country=="Finland", lpattern(dash) lwidth(medthick) ///
		legend(label(2 "Finland"))) ///
		(line GASOLINE_Price_afterTax year if country=="Germany", lpattern(dot) lwidth(medthick) ///
		legend(label(3 "Germany"))) ///
		(line GASOLINE_Price_afterTax year if country=="Lithuania", lpattern(dash_dot) lwidth(medthick) ///
		legend(label(4 "Lithuania"))) ///
		(line GASOLINE_Price_afterTax year if country=="Poland", lpattern(shortdash)  lwidth(medthick) ///
		legend(label(5 "Poland"))) ///
		(line GASOLINE_Price_afterTax year if country=="Portugal", lpattern(shortdash_dot) lwidth(medthick) ///
		legend(label(6 "Portugal"))) ///
		(line GASOLINE_Price_afterTax year if country=="Slovakia", lpattern(longdash) lwidth(medthick) ///
		legend(label(7 "Slovakia"))) ///
		(line GASOLINE_Price_afterTax year if country=="Slovenia", lpattern(longdash_dot) lwidth(medthick) ///
		legend(label(8 "Slovenia")) ///
		legend(off) ///
		ytitle(Price (EUR/TJ), size(small)) ylabel(, labsize(small)) ///
		title("Gasoline - post-tax", size(medium) color(black)) ///
		xtitle("") xlabel(, labsize(small)) ///
		scheme(s2color) ///
		graphregion(color(white) fcolor(white)) plotregion(color(white) fcolor(white)))
		///
		graph export gasoline_price_at.png, as(png) replace	 

twoway (line GASOLINE_Price_preTax year if country=="Denmark", ///
		legend(label(1 "Denmark") size(vsmall) cols(2))) ///
		(line GASOLINE_Price_preTax year if country=="Finland", lpattern(dash) lwidth(medthick) ///
		legend(label(2 "Finland"))) ///
		(line GASOLINE_Price_preTax year if country=="Germany", lpattern(dot) lwidth(medthick) ///
		legend(label(3 "Germany"))) ///
		(line GASOLINE_Price_preTax year if country=="Lithuania", lpattern(dash_dot) lwidth(medthick) ///
		legend(label(4 "Lithuania"))) ///
		(line GASOLINE_Price_preTax year if country=="Poland", lpattern(shortdash)  lwidth(medthick) ///
		legend(label(5 "Poland"))) ///
		(line GASOLINE_Price_preTax year if country=="Portugal", lpattern(shortdash_dot) lwidth(medthick) ///
		legend(label(6 "Portugal"))) ///
		(line GASOLINE_Price_preTax year if country=="Slovakia", lpattern(longdash) lwidth(medthick) ///
		legend(label(7 "Slovakia"))) ///
		(line GASOLINE_Price_preTax year if country=="Slovenia", lpattern(longdash_dot) lwidth(medthick) ///
		legend(label(8 "Slovenia")) ///
		legend(off) ///
		ytitle(Price (EUR/TJ), size(small)) ylabel(, labsize(small)) ///
		title("Gasoline - pre-tax", size(medium) color(black)) ///
		xtitle("") xlabel(, labsize(small)) ///
		scheme(s2color) ///
		graphregion(color(white) fcolor(white)) plotregion(color(white) fcolor(white)))
		///
		graph export gasoline_price_pt.png, as(png) replace					

twoway (line OTHPETRO_Price_afterTax year if country=="Denmark", ///
		legend(label(1 "Denmark") size(vsmall) cols(2))) ///
		(line OTHPETRO_Price_afterTax year if country=="Finland", lpattern(dash) lwidth(medthick) ///
		legend(label(2 "Finland"))) ///
		(line OTHPETRO_Price_afterTax year if country=="Germany", lpattern(dot) lwidth(medthick) ///
		legend(label(3 "Germany"))) ///
		(line OTHPETRO_Price_afterTax year if country=="Lithuania", lpattern(dash_dot) lwidth(medthick) ///
		legend(label(4 "Lithuania"))) ///
		(line OTHPETRO_Price_afterTax year if country=="Poland", lpattern(shortdash)  lwidth(medthick) ///
		legend(label(5 "Poland"))) ///
		(line OTHPETRO_Price_afterTax year if country=="Portugal", lpattern(shortdash_dot) lwidth(medthick) ///
		legend(label(6 "Portugal"))) ///
		(line OTHPETRO_Price_afterTax year if country=="Slovakia", lpattern(longdash) lwidth(medthick) ///
		legend(label(7 "Slovakia"))) ///
		(line OTHPETRO_Price_afterTax year if country=="Slovenia", lpattern(longdash_dot) lwidth(medthick) ///
		legend(label(8 "Slovenia")) ///
		legend(off) ///
		ytitle(Price (EUR/TJ), size(small)) ylabel(, labsize(small)) ///
		title("Other petroleum products - post-tax", size(medium) color(black)) ///
		xtitle("") xlabel(, labsize(small)) ///
		scheme(s2color) ///
		graphregion(color(white) fcolor(white)) plotregion(color(white) fcolor(white)))
		///
		graph export othpetro_price_at.png, as(png) replace	 

twoway (line OTHPETRO_Price_preTax year if country=="Denmark", ///
		legend(label(1 "Denmark") size(vsmall) cols(2))) ///
		(line OTHPETRO_Price_preTax year if country=="Finland", lpattern(dash) lwidth(medthick) ///
		legend(label(2 "Finland"))) ///
		(line OTHPETRO_Price_preTax year if country=="Germany", lpattern(dot) lwidth(medthick) ///
		legend(label(3 "Germany"))) ///
		(line OTHPETRO_Price_preTax year if country=="Lithuania", lpattern(dash_dot) lwidth(medthick) ///
		legend(label(4 "Lithuania"))) ///
		(line OTHPETRO_Price_preTax year if country=="Poland", lpattern(shortdash)  lwidth(medthick) ///
		legend(label(5 "Poland"))) ///
		(line OTHPETRO_Price_preTax year if country=="Portugal", lpattern(shortdash_dot) lwidth(medthick) ///
		legend(label(6 "Portugal"))) ///
		(line OTHPETRO_Price_preTax year if country=="Slovakia", lpattern(longdash) lwidth(medthick) ///
		legend(label(7 "Slovakia"))) ///
		(line OTHPETRO_Price_preTax year if country=="Slovenia", lpattern(longdash_dot) lwidth(medthick) ///
		legend(label(8 "Slovenia")) ///
		legend(off) ///
		ytitle(Price (EUR/TJ), size(small)) ylabel(, labsize(small)) ///
		title("Other petroleum products - pre-tax", size(medium) color(black)) ///
		xtitle("") xlabel(, labsize(small)) ///
		scheme(s2color) ///
		graphregion(color(white) fcolor(white)) plotregion(color(white) fcolor(white)))
		///
		graph export othpetro_price_pt.png, as(png) replace			

twoway (line NATGAS_Price_afterTax year if country=="Denmark", ///
		legend(label(1 "Denmark") size(vsmall) cols(2))) ///
		(line NATGAS_Price_afterTax year if country=="Finland", lpattern(dash) lwidth(medthick) ///
		legend(label(2 "Finland"))) ///
		(line NATGAS_Price_afterTax year if country=="Germany", lpattern(dot) lwidth(medthick) ///
		legend(label(3 "Germany"))) ///
		(line NATGAS_Price_afterTax year if country=="Lithuania", lpattern(dash_dot) lwidth(medthick) ///
		legend(label(4 "Lithuania"))) ///
		(line NATGAS_Price_afterTax year if country=="Poland", lpattern(shortdash)  lwidth(medthick) ///
		legend(label(5 "Poland"))) ///
		(line NATGAS_Price_afterTax year if country=="Portugal", lpattern(shortdash_dot) lwidth(medthick) ///
		legend(label(6 "Portugal"))) ///
		(line NATGAS_Price_afterTax year if country=="Slovakia", lpattern(longdash) lwidth(medthick) ///
		legend(label(7 "Slovakia"))) ///
		(line NATGAS_Price_afterTax year if country=="Slovenia", lpattern(longdash_dot) lwidth(medthick) ///
		legend(label(8 "Slovenia")) ///
		legend(off) ///
		ytitle(Price (EUR/TJ), size(small)) ylabel(, labsize(small)) ///
		title("Natural gas - post-tax", size(medium) color(black)) ///
		xtitle("") xlabel(, labsize(small)) ///
		scheme(s2color) ///
		graphregion(color(white) fcolor(white)) plotregion(color(white) fcolor(white))) 
		///
		saving (natgas_price_at, replace)	
		
twoway (line NATGAS_Price_preTax year if country=="Denmark", ///
		legend(label(1 "Denmark") size(vsmall) cols(2))) ///
		(line NATGAS_Price_preTax year if country=="Finland", lpattern(dash) lwidth(medthick) ///
		legend(label(2 "Finland"))) ///
		(line NATGAS_Price_preTax year if country=="Germany", lpattern(dot) lwidth(medthick) ///
		legend(label(3 "Germany"))) ///
		(line NATGAS_Price_preTax year if country=="Lithuania", lpattern(dash_dot) lwidth(medthick) ///
		legend(label(4 "Lithuania"))) ///
		(line NATGAS_Price_preTax year if country=="Poland", lpattern(shortdash)  lwidth(medthick) ///
		legend(label(5 "Poland"))) ///
		(line NATGAS_Price_preTax year if country=="Portugal", lpattern(shortdash_dot) lwidth(medthick) ///
		legend(label(6 "Portugal"))) ///
		(line NATGAS_Price_preTax year if country=="Slovakia", lpattern(longdash) lwidth(medthick) ///
		legend(label(7 "Slovakia"))) ///
		(line NATGAS_Price_preTax year if country=="Slovenia", lpattern(longdash_dot) lwidth(medthick) ///
		legend(label(8 "Slovenia")) ///
		legend(off) ///
		ytitle(Price (EUR/TJ), size(small)) ylabel(, labsize(small)) ///
		title("Natural gas - pre-tax", size(medium) color(black)) ///
		xtitle("") xlabel(, labsize(small)) ///
		scheme(s2color) ///
		graphregion(color(white) fcolor(white)) plotregion(color(white) fcolor(white)))
		///
		saving (natgas_price_pt, replace)	
		
		legend(col(2)))
		///
		legend(off)) 
		///
		note("Source: International Energy Agency", size(vsmall)))
		graph export natgas_price_pt.png, as(png) replace			

		
**Combine graphs
cd "/Users/lauralehtonen/Desktop"
	*Combine graphs 1
	graph combine coal_price_pt.gph coal_price_at.gph diesel_price_pt.gph diesel_price_at.gph ///
	electricity_price_pt.gph electricity_price_at.gph  fuel_oil_price_pt.gph fuel_oil_price_at.gph ///
	gasoline_price_pt.gph gasoline_price_at.gph, ycommon ///
	graphregion(color(white)) plotregion(color(white))
	*Combine graphs 2
	graph combine gasoline_price_pt.gph gasoline_price_at.gph ///
	othpetro_price_pt.gph othpetro_price_at.gph ///
	natgas_price_pt.gph natgas_price_at.gph ///
	electricity_price_pt.gph electricity_price_at.gph gasoline_price_pt.gph gasoline_price_at.gph, ycommon ///
	graphregion(color(white)) plotregion(color(white)) 
	*Combine graphs all
	graph combine coal_price_pt.gph coal_price_at.gph diesel_price_pt.gph diesel_price_at.gph ///
	electricity_price_pt.gph electricity_price_at.gph fuel_oil_price_pt.gph fuel_oil_price_at.gph ///
	gasoline_price_pt.gph gasoline_price_at.gph ///
	othpetro_price_pt.gph othpetro_price_at.gph natgas_price_pt.gph natgas_price_at.gph, ycommon ///
	graphregion(color(white)) plotregion(color(white)) 
	///
	note("Source: International Energy Agency Note: Dashed line indicates pre-tax prices, while solid line indicates after tax prices", size(vsmall)) 
	///
	graph export energy_prices_pt_at, as(png) replace	
	
	*Add legend - copy paste to pictrure
	twoway line DIESEL_Price_afterTax year, ///
	yscale(off) ///
	graphregion(color(white)) plotregion(color(white)) ///
	legend(label(1 "Denmark") label(2 "Finland") label(3 "Germany") label(4 "Lithuania") ///
	label(5 "Poland") label(6 "Portugal") label(7 "Slovakia") label(8 "Slovenia") size(vsmall) col(4))
	gr_edit .plotregion1.draw_view.setstyle, style(no)
	
	twoway line DIESEL_Price_afterTax year, ///
	yscale(off) ///
	note("Source: International Energy Agency", size(vsmall)) ///
	graphregion(color(white)) plotregion(color(white)) ///
	legend(label(1 "Denmark") label(2 "Finland") label(3 "Germany") label(4 "Lithuania") ///
	label(5 "Poland") label(6 "Portugal") label(7 "Slovakia") label(8 "Slovenia") size(vsmall) col(4))
	gr_edit .plotregion1.draw_view.setstyle, style(no)


	*Combine graphs
	graph combine electricity_price_at.gph diesel_price_at.gph, ycommon ///
	legend(label(1 "Denmark") label(2 "Finland") label(3 "Germany") label(4 "Lithuania") ///
	label(5 "Poland") label(6 "Portugal") label(7 "Slovakia") label(8 "Slovenia") size(vsmall) rows(2))
	note(Source: International Energy Agency, size(vsmall) ///
	Note: Dashed line indicates pre-tax prices, while solid line indicates after tax prices) ///
	graphregion(color(white)) plotregion(color(white))
	graph export energy_prices_at.png, as(png) replace		




	