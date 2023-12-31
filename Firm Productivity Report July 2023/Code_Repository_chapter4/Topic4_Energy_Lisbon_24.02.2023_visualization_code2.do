***********************************************************************************
* Topic 4: Energy use - Visualization part 2 - CompNet Workshop Lisbon 24.02.2023 *
***********************************************************************************

// In this do-file you can find the code to create some descriptives and the analytical results for the Lisbon workshop

*** Clarifying notes
*1. Dataset(s) used: unconditional_mac_sector_20e_weighted sample, unconditional_industry2d_20e_weighted sample, 8th vintage (to include DE)
	*gdp + energy price deflators from CompNet and Eurostat respectively (from 'Deflators.dta')
*2. Definition of energy intensity: energy cost over total cost, deflated by energy price deflators and gdp deflators respectively
*3. For totals, using _sw*_mn instead of _N*_mn (ie. total energy use = FV03_n_ener_mn*FV03_n_ener_sw)
*4. This Stata code was created using a Macbook, so some editing needs to be done in the 'cd' commands if using a PC



*** 0. Creation of 'Deflators.dta' - file (optional - can use the .dta file provided directly) ***
*Housekeeping
clear all
clear
eststo clear
set more off

*Convert from excel to .dta
cd "/Users/lauralehtonen/Desktop/CompNet/Compnet Data/Energy research"
import excel using "/Users/lauralehtonen/Desktop/CompNet/Compnet Data/Energy research/Deflators_2015_index.xlsx", firstrow //firstrow to import the first row as variable names  
save Deflators.dta, replace
***



*** 1. Energy intensity by macro-sector (slide 9) ***
*Housekeeping
clear all
clear
eststo clear
set more off

*Set directory and open relevant data
//Mac
cd "/Users/lauralehtonen/Desktop/CompNet/Compnet Data/8th vintage/Data files"
use "unconditional_mac_sector_20e_weighted.dta", clear

merge m:1 country year using "Deflators_8th_vintage" //note: we only have certain countries + for each year we have the country average deflator. 
										//therefore, every industry in a country in a given year will have the same deflator
drop _merge

*A) Create industry energy intensity
//Nominal energy inputs: FV03_n_ener_mn ; Nominal revenue: FV08_nrev_mn
//Total cost: capital cost + nominal intermediate inputs + nominal labor cost + nominal energy inputs
//capcost + nm + nlc + n_ener: FV00_capcost_ ; FV06_nm_ ; FV05_nlc_ ; FV03_n_ener_

	*Total cost:
	gen totcost = (FV00_capcost_mn*FV00_capcost_sw) + (FV06_nm_mn*FV06_nm_sw) + (FV05_nlc_mn*FV05_nlc_sw) + (FV03_n_ener_mn*FV03_n_ener_sw)
	label variable totcost "Total cost"
	
	*Industry energy intensity = FV03: nominal energy inputs / total cost
	gen indener_intensity_1 = (FV03_n_ener_mn*FV03_n_ener_sw) / (totcost)
	gen indener_intensity = indener_intensity_1*p_gp_e 			//multiply energy intensity with p_g/p_e to deflate
	label variable indener_intensity "Industry energy intensity"
	
	drop if indener_intensity==.
	drop if indener_intensity==0
	
*B) Graphing
tab country year // only 9 countries left, 2010-2016 all have values
//keep if year >=2004
tab mac_sector if country=="GERMANY" // Only data for Manufacturing and Consutruction sector for DE

*Drop real estate sector
drop if mac_sector ==7 //real estate sector seems suspiciously high for Poland and Latvia

*All countries, one graph per sector no time aspect
graph bar indener_intensity, over(country, label(angle(45) labsize(tiny))) by(mac_sector) ///
subtitle(, size(vsmall)) ///
ylabel(,labsize(vsmall)) ///
ytitle(Energy intensity, size(vsmall)) /// 
legend(off) ///
graphregion(color(white) fcolor(white)) plotregion(color(white) fcolor(white))
***



*** 2. Energy intensity of imports/exports/domestic production (slides 4-6) ***
** TASK 2 A: Energy intensity and imports **
*Energy intensity of top import industries per country over time
*Housekeeping
clear all
clear
eststo clear
set more off

*Set directory and open relevant data
//Mac
cd "/Users/lauralehtonen/Desktop/CompNet/Compnet Data/8th vintage/Data files"
use "unconditional_industry2d_20e_weighted.dta", clear

merge m:1 country year using "Deflators" //note: we only have certain countries + for each year we have the country average deflator. 
										//therefore, every industry in a country in a given year will have the same deflator
drop _merge

*A) Calculate each country's import share
//Import variables: TV08_imp_sw ; TV08_imp_mn
drop if TV08_imp_sw ==.
drop if TV08_imp_mn ==.
	*Industry total imports by year: imp_mn x sw firms in industry 
	gen indtotimports = TV08_imp_sw*TV08_imp_mn
	label variable indtotimports "Industry total imports"
		 
	*Country total imports: sum industry total imports
	bysort country year: egen countrytotimports=total(indtotimports)
	label variable countrytotimports "Country total imports"
	
	*Import share: industry total imports / country total imports
	gen imp_share = indtotimports / countrytotimports
	label variable imp_share "Import share"

*Rank top 3-5 industries by country per year
gsort country year -imp_share

*Assign import share rank for each industry for each year per country
bysort country year: egen rank1 = rank(-imp_share), unique

*B) Calculate energy intensity
//Nominal energy inputs: FV03_n_ener_mn ; Nominal revenue: FV08_nrev_mn
//Total cost: capital cost + nominal intermediate inputs + nominal labor cost + nominal energy inputs
//capcost + nm + nlc + n_ener: FV00_capcost_ ; FV06_nm_ ; FV05_nlc_ ; FV03_n_ener_
	
	*Total cost:
	gen totcost = (FV00_capcost_mn*FV00_capcost_sw) + (FV06_nm_mn*FV06_nm_sw) + (FV05_nlc_mn*FV05_nlc_sw) + (FV03_n_ener_mn*FV03_n_ener_sw)
	label variable totcost "Total cost"
	
	*Industry energy intensity
	gen indener_intensity_1 = (FV03_n_ener_mn*FV03_n_ener_sw) / (totcost)
	gen indener_intensity = indener_intensity_1*p_gp_e //multiply energy intensity with p_g/p_e to deflate
	label variable indener_intensity "Industry energy intensity"
	count if indener_intensity==0
	
	drop if indener_intensity_1==.
	drop if indener_intensity_1==0
	
	tab industry2d
	tab country year

*C) Country Index
*Weighted average using same weights as these industries had in the import (imp_share)
	*Weighted industry energy intensity
	gen indener_weighted = (indener_intensity * imp_share)*100
	
	*Total weighted industry energy intensity 
	bysort country year: egen weighted_average = sum(indener_weighted)
	
*View
br country year industry2d imp_share indener_intensity indener_weighted rank1

*D) Graphing
*Select years
tab country year 
//7 countries in total (no Slovenia or Germany), Portugal from year==2010, DK until year==2016

*Check industries
tab industry2d //only manufacturing sector industries

*Weighted energy intensity by country - Country Index (slide 3)
	*By year, all industries 
	*2010
	graph bar weighted_average if year==2010, over(country, label(angle(45))) ///
	ytitle("Industry energy intensity - weighted average - Imports") graphregion(color(white)) title("2010")

	*2016
	graph bar weighted_average if year==2016, over(country, label(angle(45))) ///
	ytitle("Industry energy intensity - weighted average - Imports") graphregion(color(white)) title("2016")
	
*Color coding - top 3 industries per country (slide 4)
	keep if year== 2010 | year == 2016
	keep if rank1<=3
	keep country year industry2d indener_weighted
 
	rename indener_weighted indener_weighted_
	reshape wide indener_weighted_, i(country year) j(industry2d)
	
	*Plot industry energy intensity by country
	*2010
	graph bar indener_weighted_* if year==2010, stack over(country, label(angle(30) labsize(vsmall))) ///
ytitle(Weighted industry energy intensity (%), size(vsmall)) ylabel(, labsize(vsmall)) ///
	subtitle(Manufacturing sector industries - 2010, size(small)) ///
	graphregion(color(white)) plotregion(color(white)) ///
	legend(off) ///
	saving(energy2a_2010, replace)
	//note: if necessary to see what industries included in legend, for example when including only certain countries, keep legend(on) 
	
	*2016
	graph bar indener_weighted_* if year==2016, stack over(country, label(angle(30) labsize(vsmall))) ///
ytitle(Weighted industry energy intensity (%), size(vsmall)) ylabel(, labsize(vsmall)) ///
	subtitle(Manufacturing sector industries - 2016, size(small)) ///
	graphregion(color(white)) plotregion(color(white)) legend(off) ///
	saving(energy2a_2016, replace)
	//note: if necessary to see what industries included in legend, for example when including only certain countries, keep legend(on) 
		
	*Combine graphs
	graph combine energy2a_2010.gph energy2a_2016.gph, ycommon title(Weighted industry energy intensity by country, size(medium) color(black)) note(Industry energy intensity is weighted by industry import share, size(vsmall)) ///
	graphregion(color(white)) plotregion(color(white))
	graph export energy2a.png, as(png) replace	

	*Add legend - copy paste to picture 
	//NOTE: If only specific countries are used, or other datasets, the legend needs to be manually edited (first by checking which industries are included in the above 2 graphs)
	graph bar indener_weighted_*, stack over(country, label(angle(30) labsize(0))) ///
	yscale(off) ///
	graphregion(color(white)) plotregion(color(white)) ///
	legend(symxsize(small) size(vsmall) label(1 Food products) label(2 Chemicals and chemical products) ///
	label(3 Basic pharmaceutical products and pharmaceutical preparations) label(4 Rubber and plastic products) ///
	label(5 Basic metals) label(6 Computer, electronic and optical products) ///
	label(7 Electrical equipment) label(8 Machinery and equipment) /// 
	label(9 Motor vehicles, trailers and semitrailers) col(1))
	gr_edit .plotregion1.draw_view.setstyle, style(no)
**

	
** TASK 2 B: Energy intensity and exports **
*Energy intensity of top export industries per country over time
*Housekeeping
clear all
clear
eststo clear
set more off

*Set directory and open relevant data
//Mac
cd "/Users/lauralehtonen/Desktop/CompNet/Compnet Data/8th vintage/Data files"
use "unconditional_industry2d_20e_weighted.dta", clear

merge m:1 country year using "Deflators" //note: we only have certain countries + for each year we have the country average deflator. 
										//therefore, every industry in a country in a given year will have the same deflator
drop _merge

*A) Calculate each country's export share
//Export variables: TV02_exp_sw ; TV02_exp_mn
drop if TV02_exp_sw ==.
drop if TV02_exp_mn ==.
	*Industry total exports by year: export_mn x _sw firms in industry 
	gen indtotexports = TV02_exp_sw*TV02_exp_mn
	label variable indtotexports "Industry total exports"
		 
	*Country total exports: sum industry total exports
	bysort country year: egen countrytotexports=total(indtotexports)
	label variable countrytotexports "Country total exports"
	
	*Export share: industry total exports / country total exports
	gen exp_share = indtotexports / countrytotexports
	label variable exp_share "Export share"
	
*Rank top 3-5 industries by country per year
gsort country year -exp_share

*Assign export share rank for each industry for each year per country
bysort country year: egen rank1 = rank(-exp_share), unique

*B) Calculate energy intensity
//Nominal energy inputs: FV03_n_ener_mn ; Nominal revenue: FV08_nrev_mn
//Total cost: capital cost + nominal intermediate inputs + nominal labor cost + nominal energy inputs
//capcost + nm + nlc + n_ener: FV00_capcost_ ; FV06_nm_ ; FV05_nlc_ ; FV03_n_ener_
	
	*Total cost:
	gen totcost = (FV00_capcost_mn*FV00_capcost_sw) + (FV06_nm_mn*FV06_nm_sw) + (FV05_nlc_mn*FV05_nlc_sw) + (FV03_n_ener_mn*FV03_n_ener_sw)
	label variable totcost "Total cost"
	
	*Industry energy intensity
	gen indener_intensity_1 = (FV03_n_ener_mn*FV03_n_ener_sw) / (totcost)
	gen indener_intensity = indener_intensity_1*p_gp_e //multiply energy intensity with p_g/p_e to deflate
	label variable indener_intensity "Industry energy intensity"
	count if indener_intensity==0
	
	drop if indener_intensity==.
	drop if indener_intensity==0
	
	tab country year
	tab year
	tab industry2d
	
*C) Country Index
*Weighted average using same weights as these industries had in the export (exp_share)
	*Weighted industry energy intensity
	gen indener_weighted = (indener_intensity * exp_share)*100
	
	*Total weighted industry energy intensity 
	bysort country year: egen weighted_average = sum(indener_weighted)	
	
*View
br country year industry2d exp_share indener_intensity indener_weighted rank1

*D) Graphing
*Select years
tab country year 
tab industry2d
//9 countries in total, Portugal from year==2010, DK until year==2016

*Weighted energy intensity by country - Country Index (slide 3)
	*By year, all industries
	*2010
	graph bar weighted_average if year==2010, over(country, label(angle(45))) ///
	ytitle("Industry energy intensity - weighted average - Exports") graphregion(color(white)) title("2010")

	*2016
	graph bar weighted_average if year==2016, over(country, label(angle(45))) ///
	ytitle("Industry energy intensity - weighted average - Exports") graphregion(color(white)) title("2016")
	
*Color coding - top 3 industries per country (slide 5)
	keep if year== 2010 | year == 2016
	keep if rank1<=3
	keep country year industry2d indener_intensity indener_weighted weighted_average exp_share rank1
	keep country year industry2d indener_weighted
 
	rename indener_weighted indener_weighted_
	reshape wide indener_weighted_, i(country year) j(industry2d)
	
	*Plot industry energy intensity by country
	*2010
	graph bar indener_weighted_* if year==2010, stack over(country, label(angle(30) labsize(vsmall))) ///
ytitle(Weighted industry energy intensity (%), size(vsmall)) ylabel(, labsize(vsmall)) ///
	subtitle(Manufacturing sector industries - 2010, size(small)) ///
	graphregion(color(white)) plotregion(color(white)) legend(off) ///
	saving(energy2b_2010, replace)
	//note: if necessary to see what industries included in legend, for example when including only certain countries, keep legend(on) 
	
	*2016
	graph bar indener_weighted_* if year==2016, stack over(country, label(angle(30) labsize(vsmall))) ///
ytitle(Weighted industry energy intensity (%), size(vsmall)) ylabel(, labsize(vsmall)) ///
	subtitle(Manufacturing sector industries - 2016, size(small)) ///
	graphregion(color(white)) plotregion(color(white)) legend(off) ///
	saving(energy2b_2016, replace)
	//note: if necessary to see what industries included in legend, for example when including only certain countries, keep legend(on) 
	
	*Combine graphs
	graph combine energy2b_2010.gph energy2b_2016.gph, ycommon title(Weighted industry energy intensity by country, size(medium) color(black)) note(Industry energy intensity is weighted by industry export share, size(vsmall)) ///
	graphregion(color(white)) plotregion(color(white))
	graph export energy2b.png, as(png) replace	
	
	*Add legend - copy paste to picture
	//NOTE: If only specific countries are used, or other datasets, the legend needs to be manually edited (first by checking which industries are included in the above 2 graphs)
	graph bar indener_weighted_*, stack over(country, label(angle(30) labsize(0))) ///
	yscale(off) ///
	graphregion(color(white)) plotregion(color(white)) ///
	legend(symxsize(small) size(vsmall) label(1 Food products) label(2 Paper and paper products) label(3 Chemicals and chemical products) ///
	label(4 Rubber and plastic products) label(5 Basic metals) label(6 Fabricated metal products except machinery and equipment) ///
	label(7 Computer, electronic and optical products) label(8 Electrical equipment) label(9 Machinery and equipment) /// 
	label(10 Motor vehicles, trailers and semitrailers) label(11 Other transport equipment) label(12 Furniture) col(1))
	gr_edit .plotregion1.draw_view.setstyle, style(no)
**


** TASK 2 C: Industry energy intensity and domestic production (value added) **
*Energy intensity of top value-adding industries per country over time
use "unconditional_industry2d_20e_weighted.dta", clear

merge m:1 country year using "Deflators" //note: we only have certain countries + for each year we have the country average deflator. 
										//therefore, every industry in a country in a given year will have the same deflator
drop _merge

*A) Calculate each country's VA share
//VA variables (nominal): FV10_nva_sw ; FV10_nva_mn
drop if FV10_nva_sw ==.
drop if FV10_nva_mn ==.
	*Industry total VA by year: nva_mn x sw firms in industry 
	gen indtotva = FV10_nva_sw*FV10_nva_mn
	label variable indtotva "Industry total VA"
		 
	*Country total VA: sum industry total VA
	bysort country year: egen countrytotva=total(indtotva)
	label variable countrytotva "Country total VA"
	
	*VA share: industry total VA / country total VA
	gen va_share = indtotva / countrytotva
	label variable va_share "VA share"

*Rank top 3-5 industries by country per year
gsort country year -va_share

*Assign VA share rank for each industry for each year per country
bysort country year: egen rank1 = rank(-va_share), unique

*B) Calculate energy intensity
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
	
	tab country year
	
*C) Country Index
*Weighted average using same weights as these industries had in the import (imp_share)
	*Weighted industry energy intensity
	gen indener_weighted = (indener_intensity * va_share)*100
	
	*Total weighted industry energy intensity 
	bysort country year: egen weighted_average = sum(indener_weighted)

*View
br country year industry2d va_share indener_intensity indener_weighted rank1	

*D) Graphing
*Select years
tab country year 
//9 countries in total, Portugal from year==2010, DK until year==2016

*Check industries
tab industry2d //all sector industries

*Weighted energy intensity by country - Country Index (slide 3)
	*By year, all industries
	*2010
	graph bar weighted_average if year==2010, over(country, label(angle(45))) ///
	ytitle("Industry energy intensity - weighted average - Value added") graphregion(color(white)) title("2010")

	*2016
	graph bar weighted_average if year==2016, over(country, label(angle(45))) ///
	ytitle("Industry energy intensity - weighted average - Value added") graphregion(color(white)) title("2016")
	
*Color coding - top 3 industries per country (slide 6)
	keep if year== 2010 | year == 2016
	keep if rank1<=3
	keep country year industry2d indener_weighted
 
	rename indener_weighted indener_weighted_
	reshape wide indener_weighted_, i(country year) j(industry2d)
	
	* Plot industry energy intensity by country
	*2010
	graph bar indener_weighted_* if year==2010, stack over(country, label(angle(30) labsize(vsmall))) ///
ytitle(Weighted industry energy intensity (%), size(vsmall)) ylabel(, labsize(vsmall)) ///
	subtitle(Top 3 value adding industries - 2010, size(small)) ///
	graphregion(color(white)) plotregion(color(white)) legend(off) ///
	saving(energy2c_2010, replace)
	//note: if necessary to see what industries included in legend, for example when including only certain countries, keep legend(on) 
	
	*2016
	graph bar indener_weighted_* if year==2016, stack over(country, label(angle(30) labsize(vsmall))) ///
ytitle(Weighted industry energy intensity (%), size(vsmall)) ylabel(, labsize(vsmall)) ///
	subtitle(Top 3 value adding industries - 2016, size(small)) ///
	graphregion(color(white)) plotregion(color(white)) legend(off) ///
	saving(energy2c_2016, replace)
	//note: if necessary to see what industries included in legend, for example when including only certain countries, keep legend(on) 
	
	*Combine graphs
	graph combine energy2c_2010.gph energy2c_2016.gph, ycommon title(Weighted industry energy intensity by country, size(medium) color(black)) note(Industry energy intensity is weighted by industry value added share, size(vsmall)) ///
	graphregion(color(white)) plotregion(color(white))
	graph export energy2c.png, as(png) replace	

	*Add legend - copy paste to picture
	//NOTE: If only specific countries are used, or other datasets, the legend needs to be manually edited (first by checking which industries are included in the above 2 graphs)
	graph bar indener_weighted_*, stack over(country, label(angle(30) labsize(0))) ///
	yscale(off) ///
	graphregion(color(white)) plotregion(color(white)) ///
	legend(symxsize(small) size(vsmall) label(1 Manufacture of food products) label(2 Manufacture of paper and paper products) label(3 Manufacture of electrical equipment) label(4 Manufacture of machinery and equipment) ///
	label(5 Manufacture of motor vehicles, trailers and semitrailers) ///
	label(6 Wholesale and retail trade and repair of motor vehicles and motorcycles) ///
	label(7 Wholesale trade, except of motor vehicles and motorcycles) ///
	label(8 Retail trade, except of motor vehicles and motorcycles) label(9 Land transport and transport via pipelines)  ///
	label(10 Warehousing and support activities for transportation) label(11 Telecommunications) col(1))
	gr_edit .plotregion1.draw_view.setstyle, style(no)
**
***



*** 3. Energy intensity and firms' characteristics (slide 10) ***
* Energy intensity and labor productivity, real value-added, wages per worker, firm size
*Housekeeping
clear all
clear
eststo clear
set more off

*Set directory and open relevant data
//Mac
cd "/Users/lauralehtonen/Desktop/CompNet/Compnet Data/8th vintage/Data files"
use "unconditional_industry2d_20e_weighted.dta", clear

merge m:1 country year using "Deflators" //note: we only have certain countries + for each year we have the country average deflator. 
										//therefore, every industry in a country in a given year will have the same deflator
drop _merge

*A) Generate variables
*Energy intensity	
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
	
	drop if indener_intensity==.
	drop if indener_intensity==0
	
	*Trim outliers - p10
	egen indener_intensity_p10=pctile(indener_intensity), p(10)
	egen indener_intensity_p90=pctile(indener_intensity), p(90)
	replace indener_intensity=. if indener_intensity<indener_intensity_p10 | indener_intensity>indener_intensity_p90
	
	drop if indener_intensity==.

* Mean and median values for labor productivity, real VA, wages per worker, firm size
	* Mean
	gen Labor_Productivity = (PV07_lprod_va_mn)/1000000
	
	gen Real_VA = (FV18_rva_mn)/1000000
	
	gen Wages_per_Worker = (LV00_avg_wage_mn)/1000000
	
	gen Firm_Size = (LV21_l_mn)/1000000
	
	* Median 
	gen Labor_Productivity_p50 = (PV07_lprod_va_p50)/1000000
	
	gen Real_VA_p50 = (FV18_rva_p50)/1000000
	
	gen Wages_per_Worker_p50 = (LV00_avg_wage_p50)/1000000
	
	gen Firm_Size_p50 = (LV21_l_p50)/1000000	
	

*B) Regress all variables on energy intensity - productivity, real value added, wages per worker, firm size
	*Industry energy intensity and means 
	xi: reg indener_intensity Labor_Productivity Real_VA Wages_per_Worker Firm_Size i.country*i.industry i.year
	outreg2 using energy3.doc, addtext(Country x Industry FE, Yes, Year FE, Yes) ctitle("Mean (in Mil)") keep(Labor_Productivity Real_VA Wages_per_Worker Firm_Size) word replace
		
	*Industry energy intensity and median
	xi: reg indener_intensity Labor_Productivity_p50 Real_VA_p50 Wages_per_Worker_p50 Firm_Size_p50 i.country*i.industry i.year
	outreg2 using energy3.doc, addtext(Country x Industry FE, Yes, Year FE, Yes) ctitle("Median (in Mil)") keep(Labor_Productivity_p50 Real_VA_p50 Wages_per_Worker_p50 Firm_Size_p50) word append
***



*** APPENDIX (slides 31-37) ***
** 1: Energy intensity and input share (slide 31) **
*Housekeeping
clear all
clear
eststo clear
set more off

*Set directory and open relevant data
//Mac
cd "/Users/lauralehtonen/Desktop/CompNet/Compnet Data/8th vintage/Data files"
use "unconditional_industry2d_20e_weighted.dta", clear

merge m:1 country year using "Deflators" //note: we only have certain countries + for each year we have the country average deflator. 
										//therefore, every industry in a country in a given year will have the same deflator
drop _merge

*A) Generate variables
*Energy intensity
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
	
	drop if indener_intensity==.
	drop if indener_intensity==0
	
	*Trim outliers - p10
	egen indener_intensity_p10=pctile(indener_intensity), p(10)
	egen indener_intensity_p90=pctile(indener_intensity), p(90)
	replace indener_intensity=. if indener_intensity<indener_intensity_p10 | indener_intensity>indener_intensity_p90
	
	drop if indener_intensity==.	

*Labor cost, capital cost, intermediate cost out of total cost
	*Share of capital cost/tot cost/tot
	gen share_capcost_tot = (FV00_capcost_mn*FV00_capcost_N)/totcost
		
	*Share of labor cost/total cost
	gen share_lc_tot = (FV05_nlc_mn*FV05_nlc_N)/totcost
		
	*Share of intermediate input cost/total cost/tot
	gen share_nm_tot = (FV06_nm_mn*FV06_nm_N)/totcost 
		
*B) Regress 
	*Industry energy intensity and FEs 
		*Share of capcost
		xi: reg share_capcost_tot indener_intensity i.country*i.industry i.year
		outreg2 using energyA_1.doc, addtext(Country x Industry FE, Yes, Year FE, Yes) ctitle("Capital") keep(indener_intensity) word replace
			
		*Share of lc
		xi: reg share_lc_tot indener_intensity i.country*i.industry i.year
		outreg2 using energyA_1.doc, addtext(Country x Industry FE, Yes, Year FE, Yes) ctitle("Labor") keep(indener_intensity) word append
			
		*Share of intermediate cost
		xi: reg share_nm_tot indener_intensity i.country*i.industry i.year
		outreg2 using energyA_1.doc, addtext(Country x Industry FE, Yes, Year FE, Yes) ctitle("Int. inputs") keep(indener_intensity) word append
		
	*No energy intensity, only constant and FEs
		*Share of capcost
		xi: reg share_capcost_tot i.country*i.industry i.year
		outreg2 using energyA_1.doc, addtext(Country x Industry FE, Yes, Year FE, Yes) ctitle("Capital") keep(indener_intensity) word append
			
		*Share of lc
		xi: reg share_lc_tot i.country*i.industry i.year
		outreg2 using energyA_1.doc, addtext(Country x Industry FE, Yes, Year FE, Yes) ctitle("Labor") keep(indener_intensity) word append
			
		*Share of intermediate cost
		xi: reg share_nm_tot i.country*i.industry i.year
		outreg2 using energyA_1.doc, addtext(Country x Industry FE, Yes, Year FE, Yes) ctitle("Int. inputs") keep(indener_intensity) word append
**


** 2: Coefficient plots: energy intensity and firms characteristics (slides 32-37) **
*Housekeeping
clear all
clear
eststo clear
set more off

*Set directory and open relevant data
//Mac
cd "/Users/lauralehtonen/Desktop/CompNet/Compnet Data/8th vintage/Data files"
use "unconditional_industry2d_20e_weighted.dta", clear

merge m:1 country year using "Deflators" //note: we only have certain countries + for each year we have the country average deflator. 
										//therefore, every industry in a country in a given year will have the same deflator
drop _merge

*A) Generate variables
* Energy intensity
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
	
	drop if indener_intensity==.
	drop if indener_intensity==0
	
	*Trim outliers - p10
	egen indener_intensity_p10=pctile(indener_intensity), p(10)
	egen indener_intensity_p90=pctile(indener_intensity), p(90)
	replace indener_intensity=. if indener_intensity<indener_intensity_p10 | indener_intensity>indener_intensity_p90
	
	drop if indener_intensity==.
	
*B) Graphing: energy intensity and labor productivity, value-added, wages, firm size, total assets
//Each graph is a specific country and maps the coefficients over time of the relationship of energy intensity and a firm characteristic.
//Loops are used in the code, however manual editing is required to edit the country name and to then create the overall image that shows all countries in 1 image - if only a specific country is of interest, then no need to combine graphs, and only update the 'country==""' with the specific country of interest

	*Labor productivity (mean)
		forvalues i = 2010/2016 {
			regress PV07_lprod_va_mn indener_intensity if year == `i' & country=="SLOVENIA"
			estimates store year`i'
			local allyears `allyears' year`i' ||
			local labels `labels' `i'
		}
		coefplot `allyears', keep(indener_intensity) vertical bycoefs bylabels(`labels') ///
		subtitle("Slovenia") xtitle("Industry energy intensity", size(vsmall)) ytitle("") noci ///
		ylabel(-2000(1000)1000, labsize(vsmall)) xlabel(, labsize(vsmall)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		saving(SloveniaA_2a.gph, replace)
		//NOTE: remember to edit the 'saving' file name to match the country name
			
		*Combine graphs
		graph combine CroatiaA_2a.gph DenmarkA_2a.gph FinlandA_2a.gph GermanyA_2a.gph LithuaniaA_2a.gph ///
		PolandA_2a.gph  PortugalA_2a.gph SlovakiaA_2a.gph SloveniaA_2a.gph, ///
		ycommon title(Estimated coefficients - Dependent variable: Labor productivity (mean), size(medium) color(black)) ///
		graphregion(color(white)) plotregion(color(white))
		
		graph export energyA_2a.png, as(png) replace	
	
	*Real value added (mean)
		forvalues i = 2010/2016 {
			regress FV18_rva_mn indener_intensity if year == `i' & country=="SLOVENIA"
			estimates store year`i'
			local allyears `allyears' year`i' ||
			local labels `labels' `i'
			}
		coefplot `allyears', keep(indener_intensity) vertical bycoefs bylabels(`labels') ///
		subtitle("Slovenia") xtitle("Industry energy intensity", size(vsmall)) ytitle("") noci ///
		ylabel(-2000000(1000000)1000000, labsize(vsmall)) xlabel(, labsize(vsmall)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		saving(SloveniaA_2b.gph, replace)
		//NOTE: remember to edit the 'saving' file name to match the country name

		*Combine graphs
		graph combine CroatiaA_2b.gph DenmarkA_2b.gph FinlandA_2b.gph GermanyA_2b.gph LithuaniaA_2b.gph ///
		PolandA_2b.gph  PortugalA_2b.gph SlovakiaA_2b.gph SloveniaA_2b.gph, ///
		ycommon title(Estimated coefficients - Dependent variable: Real value added (mean), size(medium) color(black)) ///
		graphregion(color(white)) plotregion(color(white))
			
		graph export energyA_2b.png, as(png) replace	
	
	*Wages (total)		
		forvalues i = 2010/2016 {
			regress LV24_rwage_tot indener_intensity if year == `i' & country=="SLOVENIA"
			estimates store year`i'
			local allyears `allyears' year`i' ||
			local labels `labels' `i'
		}
		coefplot `allyears', keep(indener_intensity) vertical bycoefs bylabels(`labels') ///
		subtitle("Slovenia") xtitle("Industry energy intensity", size(vsmall)) ytitle("") noci ///
		ylabel(-.50(0.25)0.50, labsize(vsmall)) xlabel(, labsize(vsmall)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		saving(SloveniaA_2c.gph, replace)
		//NOTE: remember to edit the 'saving' file name to match the country name

		
		*Combine graphs
		graph combine CroatiaA_2c.gph DenmarkA_2c.gph FinlandA_2c.gph GermanyA_2c.gph LithuaniaA_2c.gph ///
		PolandA_2c.gph  PortugalA_2c.gph SlovakiaA_2c.gph SloveniaA_2c.gph, ///
		ycommon title(Estimated coefficients - Dependent variable: Real wages (total) mil.EUR, size(medium) color(black)) ///
		graphregion(color(white)) plotregion(color(white))
		
		graph export energyA_2c.png, as(png) replace	
		
	*Wages (mean)
		forvalues i = 2010/2016 {
			regress LV24_rwage_mn indener_intensity if year == `i' & country=="SLOVENIA"
			estimates store year`i'
			local allyears `allyears' year`i' ||
			local labels `labels' `i'
		}
		coefplot `allyears', keep(indener_intensity) vertical bycoefs bylabels(`labels') ///
		subtitle("Slovenia") xtitle("Industry energy intensity", size(vsmall)) ytitle("") noci ///
		ylabel(-400(200)200, labsize(vsmall)) xlabel(, labsize(vsmall)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		saving(SloveniaA_2d.gph, replace)
		//NOTE: remember to edit the 'saving' file name to match the country name
	
		*Combine graphs
		graph combine CroatiaA_2d.gph DenmarkA_2d.gph FinlandA_2d.gph GermanyA_2d.gph LithuaniaA_2d.gph ///
		PolandA_2d.gph  PortugalA_2d.gph SlovakiaA_2d.gph SloveniaA_2d.gph, /// 
		ycommon title(Estimated coefficients - Dependent variable: Real wages (mean), size(medium) color(black)) ///
		graphregion(color(white)) plotregion(color(white))
		
		graph export energyA_2d.png, as(png) replace	
	
	*Firm size (mean)
		forvalues i = 2010/2016 {
			regress LV21_l_mn indener_intensity if year == `i' & country=="SLOVENIA"
			estimates store year`i'
			local allyears `allyears' year`i' ||
			local labels `labels' `i'
		}
		coefplot `allyears', keep(indener_intensity) vertical bycoefs bylabels(`labels') ///
		subtitle("Slovenia") xtitle("Industry energy intensity", size(vsmall)) ytitle("") noci ///
		ylabel(-6000(3000)3000, labsize(vsmall)) xlabel(, labsize(vsmall)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		saving(SloveniaA_2e.gph, replace)
		//NOTE: remember to edit the 'saving' file name to match the country name
	
		*Combine graphs
		graph combine CroatiaA_2e.gph DenmarkA_2e.gph FinlandA_2e.gph GermanyA_2e.gph LithuaniaA_2e.gph ///
		PolandA_2e.gph  PortugalA_2e.gph SlovakiaA_2e.gph SloveniaA_2e.gph, /// 
		ycommon title(Estimated coefficients - Dependent variable: Number of employees (mean), size(medium) color(black)) ///
		graphregion(color(white)) plotregion(color(white))
		
		graph export energyA_2e.png, as(png) replace	
		
	*Total assets (mean)
		gen FV20_ta_mn_1 = FV20_ta_mn/1000000
		drop if FV20_ta_mn_1==.
	
		forvalues i = 2010/2016 {
			regress FV20_ta_mn_1 indener_intensity if year == `i' & country=="GERMANY"
			estimates store year`i'
			local allyears `allyears' year`i' ||
			local labels `labels' `i'
		}
		coefplot `allyears', keep(indener_intensity) vertical bycoefs bylabels(`labels') ///
		subtitle("Germany") xtitle("Industry energy intensity", size(vsmall)) ytitle("") noci ///
		ylabel(, labsize(vsmall)) xlabel(, labsize(vsmall)) ///
		graphregion(color(white)) plotregion(color(white)) ///
		saving(GermanyA_2f.gph, replace)
		//NOTE: remember to edit the 'saving' file name to match the country name
	
		*Combine graphs
		graph combine CroatiaA_2f.gph DenmarkA_2f.gph FinlandA_2f.gph GermanyA_2f.gph LithuaniaA_2f.gph ///
		PolandA_2f.gph  PortugalA_2f.gph SlovakiaA_2f.gph SloveniaA_2f.gph, /// 
		title(Estimated coefficients - Dependent variable: Total assets (mean) mil., size(medium) color(black)) ///
		graphregion(color(white)) plotregion(color(white))
		
		graph export energyA_2f.png, as(png) replace
**
***
***********
*** END ***
***********
		
	