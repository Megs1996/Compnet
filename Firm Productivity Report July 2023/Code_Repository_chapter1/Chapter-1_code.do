* 13 Jun * 


clear all


global source = "My Drive/CompNet_GDrive/CompNet 9th vintage data/20e_firms_weighted/Descriptives"
global savepath = "My Drive/CompNet_GDrive/TSI Research_Productivity/Data Analysis"
global savegraph = "My Drive/CompNet_GDrive/TSI Research_Productivity/Data Analysis/Graphs"

set more off
*set maxvar 15000

* Fig 2: TFP (REVENUE) GROWTH 

{
eststo clear 
use  "${source}/op_decomp_industry2d_20e_weighted.dta" , clear 

drop if year <=2000 | year>2020
encode country, gen(cn)

label define lyear 2000 "2000" 2001 "2001" 2002 "2002" 2003 "2003" 2004 "2004" 2005 "2005" 2006 "2006" 2007 "2007" 2008 "2008" 2009 "2009" 2010 "2010" 2011 "2011"  2012 "2012" 2013 "2013" 2014 "2014" 2015 "2015" 2016 "2016" 2017 "2017" 2018 "2018" 2019 "2019" 2020 "2020" 2021 "2021"
label value year lyear

cd "$savegraph"

drop if country=="Netherlands" | country=="Latvia" | country=="Germany"
* now we have a balanced sample of 18 countries with 2020 data available

tab country year

*** TFP ***
gen ln_tfp = ln(PEb1_tfp_1_Wrrv_wmn) 
*original code: PE99_tfp_rcd_ols_S_Wrrv_wmn 

* Margins = Predicted TFP Growth
keep if weight_type == "standard" 
*original code error in xtset cs year : repeated time values within panel reason 9th vintage has several weight_type, keep only one. There are still missing tfps in standard, ideal would be to take a weight type which generates a non-empty tfp

egen cs = group(country industry2d) 

xtset cs year 

*creating a dummy var for the "EU only sample" i.e. excluding Switzerland 
gen onlyEU=1 if country!="Switzerland"
replace onlyEU=0 if country=="Switzerland"

gen D_ln_tfp = D.ln_tfp*100
*reg D_ln_tfp i.year i.industry2d i.cn if onlyEU==1 & year<2021, cluster(industry2d)
reg D_ln_tfp i.year i.cs if onlyEU==1 & year<2021, cluster(cs)
eststo tfp_EU: margin year, post
marginsplot, graphr(color(white)) plotr(color(white)) recast(line) ciopt(color(%20)) recastci(rarea) subtitle(, bcolor(white) lcolor(black)) xlabel(2000(5)2020,labsize(3)) yla(,labsize(3) angle(0)) ytitle(" ") legend(on label(1 "95% CI") label(2 "Mean") size(4)) yline(0, lpattern(dash) lcolor(grey)) xtitle("") title("Average Revenue TFP Growth: Europe") saving(tfp_EUROPE, replace)	 scheme(s2color) graphregion(color(white)) xline(2010 2020)

* this gives the left-side panel of fig 1.1.1:
graph export "${savegraph}/TFP_gr.png", replace


* separately for each country to calculate country deviation
replace country="Czech_Republic" if country=="Czech Republic"
levelsof country
foreach cn in `r(levels)'{
	reg D_ln_tfp i.year i.industry2d if country == "`cn'", cluster(industry2d)
	eststo tfp_`cn': margin year, post
	marginsplot, graphr(color(white)) plotr(color(white)) recast(line) ciopt(color(%20)) recastci(rarea) subtitle(, bcolor(white) lcolor(black)) xlabel(2000(5)2020,labsize(3)) yla(,labsize(3) angle(0)) ytitle(" ") legend(label(1 "95% CI") label(2 "Mean")) yline(0, lpattern(dash)) xtitle("") title(`cn') saving("TFP_`cn'", replace)
	*original code: 2015 instead of 2020
	graph export "${savegraph}/TFP_gr_`cn'.png", replace
}


* store estimates in a csv to be read-in below
esttab tfp_EU tfp_Belgium tfp_Croatia tfp_Czech_Republic tfp_Denmark tfp_Finland tfp_France tfp_Hungary tfp_Italy tfp_Lithuania tfp_Malta tfp_Poland tfp_Portugal tfp_Romania tfp_Slovakia tfp_Slovenia tfp_Spain tfp_Sweden tfp_Switzerland  using "${savepath}/margins_prod_growth.csv", replace plain mtitles nostar noobs not label

import delimited "$savepath/margins_prod_growth.csv", clear varnames(1)
drop if v1 == . 
rename v1 year
keep if year>=2009

ds
foreach var in `r(varlist)' {
	destring `var', replace
}

local countries "tfp_belgium tfp_croatia tfp_czech_republic tfp_denmark tfp_finland tfp_france tfp_hungary tfp_italy  tfp_lithuania tfp_malta  tfp_poland tfp_portugal tfp_romania tfp_slovakia tfp_slovenia tfp_spain tfp_sweden tfp_switzerland"
foreach x in `countries' {
rename  `x' `x', upper
}
rename tfp_eu tfpgr_EU

graph combine TFP_Belgium.gph TFP_Croatia.gph TFP_Czech_Republic.gph TFP_Denmark.gph TFP_Finland.gph TFP_France.gph  , cols(2) graphr(color(white)) plotr(color(white))  ycommon title("Revenue TFP Growth")   
graph export "${savegraph}/countrytfp_1.png", replace

graph combine  TFP_Hungary.gph TFP_Italy.gph TFP_Lithuania.gph TFP_Malta.gph  TFP_Poland.gph TFP_Portugal.gph, cols(2) graphr(color(white)) plotr(color(white)) ycommon title("Revenue TFP Growth")   
graph export "${savegraph}/countrytfp_2.png", replace

graph combine  TFP_Romania.gph TFP_Slovakia.gph TFP_Slovenia.gph TFP_Spain.gph TFP_Sweden.gph TFP_Switzerland.gph  , cols(2) graphr(color(white)) plotr(color(white)) ycommon title("Revenue TFP Growth")   
graph export "${savegraph}/countrytfp_3.png", replace


xtset  year
reshape long  TFP_  , i(year) j(country,string)
rename TFP_ TFP_gr
*bys country year: gen dev_lprod= lprod_gr-lprodgr_EU if lprod_gr!=.
bys country year: gen dev_TFP= TFP_gr-tfpgr_EU if TFP_gr!=.

* keep if year>2009
*graph hbar dev_TFP, over(country, sort(dev_TFP dev_lprod) descending label(labsize(3) angle(0))) graphr(color(white)) plotr(color(white)) subtitle(, bcolor(white) lcolor(black)) ytitle(" ", size(.5)) title("Average Deviation per country (2010-2020)", size(4)) legend(on label(1 "deviation from European average")span size(4)) ylabel(,labs(3)) saving(TFPgr_deviation_country1, replace) name(TFPgr_deviation_country,replace)

* this gives the right-side panel of fig 1.1.1:
preserve
keep if year==2020
graph hbar dev_TFP, over(country, sort(dev_TFP dev_lprod) descending label(labsize(3) angle(0))) graphr(color(white)) plotr(color(white)) subtitle(, bcolor(white) lcolor(black)) ytitle(" ", size(.5)) title("Deviation per country (2020)", size(4)) legend(on label(1 "deviation from European average")span size(4)) ylabel(,labs(3)) saving(TFPgr_deviation_country2, replace) name(TFPgr_deviation_country,replace)
restore

* combining both panels to get Fig 1.1.1:
graph combine "tfp_Europe.gph" "TFPgr_deviation_country2", cols(2) graphr(color(white)) plotr(color(white))
graph export "${savepath}/fig1_Europe.png", replace
graph export "1.1.1_tfp_growth.pdf", as(pdf) replace
}


* Fig 3: TFP (REVENUE) DISPERSION


{
eststo clear

use country year industry2d *tfp* *lprod* FV13* FV14*  using "${source}/unconditional_industry2d_20e_weighted.dta" , clear

egen cs = group(country industry2d)
xtset cs year

drop if year <=2000 | year>2020

drop if country=="Netherlands" | country=="Latvia" | country=="Germany"
* now we have a balanced sample of 18 countries with 2020 data available


*creating a dummy var for the "EU only sample" i.e. excluding Switzerland 
gen onlyEU=1 if country!="Switzerland"
replace onlyEU=0 if country=="Switzerland"

gen prod_disp = PEj0_ln_tfp_1_p90 - PEj0_ln_tfp_1_p10 
*original code: PE22_lntfp_rcd_ols_M_p90 - PE22_lntfp_rcd_ols_M_p10
gen ifa_intens = (FV13_rifa_mn * FV13_rifa_sw)/(FV14_rk_mn*FV14_rk_sw)

replace country = "Czech_Republic" if country == "Czech Republic"
encode country, gen(cn)
drop if year<2000
label define years  2000 "2000" 2001 "2001" 2002 "2002" 2003 "2003" 2004 "2004" 2005 "2005" 2006 "2006" 2007 "2007" 2008 "2008" 2009 "2009" 2010 "2010" 2011 "2011" 2012 "2012" 2013 "2013" 2014 "2014" 2015 "2015" 2016 "2016" 2017 "2017" 2018 "2018" 2019 "2019" 2020 "2020" 2021 "2021"
label values year years
	
* productivity dispersion over time
*reg prod_disp i.year i.industry2d i.cn if onlyEU==1 & year<2021, cluster(industry2d)
reg prod_disp i.year i.cs if onlyEU==1 & year<2021, cluster(cs)
eststo EU: margin year, post

marginsplot, graphr(color(white)) plotr(color(white)) recast(line) ciopt(color(%20)) recastci(rarea) subtitle(, bcolor(white) lcolor(black)) xlabel(2000(5)2020,labsize(3)) yla(,labsize(3) angle(0)) ytitle(" ") ylabel(.5(.05).75) legend(on label(1 "95% CI") label(2 "Mean") span size(4)) xtitle("") title("Dispersion in Average Revenue TFP: Europe") saving(prod_dispersion_Europe, replace) name(prod_dispersion_Europe,replace) xline(2010 2020)

grc1leg "prod_dispersion_Europe.gph" , cols(1) graphr(color(white)) plotr(color(white))
* this gives the left-side panel of fig 1.1.2:
graph export "${savegraph}/prod_dispersion_Europe.png", replace

	
* separately for each country to calculate country deviations
levelsof country
foreach cn in `r(levels)'{
	reg prod_disp i.year i.industry2d if country == "`cn'", cluster(industry2d)
	eststo `cn': margin year, post
	marginsplot, graphr(color(white)) plotr(color(white)) recast(line) ciopt(color(%20)) recastci(rarea) subtitle(, bcolor(white) lcolor(black)) xlabel(2000(5)2020,labsize(3)) yla(,labsize(3) angle(0)) ytitle(" ") ylabel(.25(.25)1) legend(label(1 "95% CI") label(2 "Mean")) xtitle("") title("`cn'") saving("`cn'", replace)
	 	graph export "${savegraph}/TFP_dev_`cn'.png", replace
}

* store estimates in a csv to be read-in below
esttab EU Belgium Croatia Czech_Republic Denmark Finland France  Hungary Italy  Lithuania Malta  Poland Portugal Romania Slovakia Slovenia Spain Sweden Switzerland  using "${savepath}/margins_pdisp.csv", replace plain mtitles nostar noobs not label

import delimited "$savepath/margins_pdisp.csv", clear varnames(1)
drop if v1 == . 
rename v1 year
drop if year<2000
ds
foreach var in `r(varlist)' {
	destring `var', replace
}


keep if year>=2009
local countries "belgium croatia czech_republic denmark finland france  hungary italy  lithuania malta  poland portugal romania slovakia slovenia spain sweden switzerland"
foreach x in `countries' {
rename  `x' `x', upper
}
rename eu EU

local countries "BELGIUM CROATIA CZECH_REPUBLIC DENMARK FINLAND FRANCE  HUNGARY ITALY  LITHUANIA MALTA  POLAND PORTUGAL ROMANIA SLOVAKIA SLOVENIA SPAIN SWEDEN SWITZERLAND"
foreach x in `countries' {
rename `x' m_`x'
}

xtset  year
reshape long  m_  , i(year) j(country,string)
rename m_ margins
bys country year: gen dev_yearly= margins-EU if margins!=.


*graph hbar dev_yearly, over(country, sort(dev_yearly) descending label(labsize(3) angle(0))) graphr(color(white)) plotr(color(white)) subtitle(, bcolor(white) lcolor(black)) ytitle(" ", size(.5)) title("Average Deviation per country (2010-2020)", size(4)) legend(on label(1 "deviation from European average")span size(4)) ylabel(,labs(3)) saving(prod_dispersion_country1, replace) name(prod_dispersion_country,replace)

* this gives the right-side panel of fig 1.1.2:
preserve
keep if year==2020
graph hbar dev_yearly, over(country, sort(dev_yearly) descending label(labsize(3) angle(0))) graphr(color(white)) plotr(color(white)) subtitle(, bcolor(white) lcolor(black)) ytitle(" ", size(.5)) title("Deviation per country (2020)", size(4)) legend(on label(1 "deviation from European average")span size(4)) ylabel(,labs(3)) saving(prod_dispersion_country2, replace) name(prod_dispersion_country,replace)
restore

* combining both panels to get Fig 1.1.2:
graph combine  "prod_dispersion_Europe.gph" "prod_dispersion_country2"  , cols(2) graphr(color(white)) plotr(color(white)) 
graph export "${savepath}/EU_PROD_DISPERSION.png", replace
graph export "1.1.2_tfp_dispersion.pdf", as(pdf) replace
}


graph combine  Belgium.gph Croatia.gph Czech_Republic.gph Denmark.gph Finland.gph France.gph Germany.gph Hungary.gph , cols(2) graphr(color(white)) plotr(color(white))  title("Dispersion in Average Revenue TFP")   
graph export "${savegraph}/countrydispersion_1.png", replace

graph combine  Italy.gph Latvia.gph Lithuania.gph Malta.gph Netherlands.gph Poland.gph Portugal.gph Romania.gph , cols(2) graphr(color(white)) plotr(color(white)) title("Dispersion in Average Revenue TFP")   
graph export "${savegraph}/countrydispersion_2.png", replace

graph combine  Slovakia.gph Slovenia.gph Spain.gph Sweden.gph Switzerland.gph, cols(2) graphr(color(white)) plotr(color(white))  title("Dispersion in Average Revenue TFP")   
graph export "${savegraph}/countrydispersion_3.png", replace


************************************************************************


* Section 2: Technology & Knowledge Intensity *

* Fig 4: technology intensity: growth of number of firms by tech category

clear all 
global source = "My Drive/CompNet_GDrive/CompNet 9th vintage data/20e_firms_weighted/Descriptives"
global savepath = "My Drive/CompNet_GDrive/TSI Research_Productivity/Data Analysis"
global savegraph = "My Drive/CompNet_GDrive/TSI Research_Productivity/Data Analysis/Graphs"

* Objective 1: analyze the proportion of firms in each technology category by country & year
clear all
* using unconditional_techknol_20e_weighted:
use "$source/unconditional_techknol_20e_weighted.dta"
* clean variables:
rename techknol technology 
destring technology, replace 
drop if technology < 1 | technology > 6 
* exclude NAs firms  from the dataset
* transform year to date for graph purposes:
generate date = mdy(12, 31, year) 
format date %td
gen year1=year(date)
* keep only variables indicating the n° of firms (_N)
keep country technology year date year1 *_N 
* create a variable indicating the max n° obs (per row) among all the variables 
egen max_N = rowmax(CD01_old_high_0_N-TV13_imp_in_adj_N)
* reduce dataset
keep country technology year1 max_N
* calculate the number of firms per country per year and per technology type
bysort country technology year1: egen firms = sum(max_N)
drop if firms < 1 
* drop possible NAs or zeros
* calculate the country-year total number of firms
*bysort country year: egen total_firms = sum(firms)
* generate the proportion of firms by country-technology type-year
*gen prop_firms = firms/total_firms

rename year1 year
drop max_N

keep if year>2009 & year<2021
tab country year
drop if country=="Netherlands"| country=="Latvia"
* balanced panel of 18 countries between 2010-2020

reshape wide firms, i(country year) j(tech)
rename firms1 tech1
rename firms2 tech2
rename firms3 tech3
rename firms4 tech4
rename firms5 tech5
rename firms6 tech6

sort country year

foreach var of varlist tech1-tech6{
bysort country: gen deflator_`var'= `var'*100/`var'[1]
}

label var deflator_tech1 "Tech 1"
label var deflator_tech2 "Tech 2"
label var deflator_tech3 "Tech 3"
label var deflator_tech4 "Tech 4"
label var deflator_tech5 "Tech 5"
label var deflator_tech6 "Tech 6"
*twoway line deflator_tech1 year || line deflator_tech2 year||line deflator_tech3 year||line deflator_tech4 year||line deflator_tech5 year||line deflator_tech6 year, by(country)


collapse (mean) deflator_tech*, by(year)

line deflator_tech1 deflator_tech2 deflator_tech3 deflator_tech4 deflator_tech5 deflator_tech6 year, plotregion(fcolor(white)) graphregion(fcolor(white)) legend(label(1 "Tech 1") label(2 "Tech 2") label(3 "Tech 3") label(4 "Tech 4") label(5 "Tech 5") label(6 "Tech 6")) ytitle("Number of firms" "(Index, 2010=100)" " ") lpattern(solid dash dot dash_dot shortdash longdash) scheme(s2color)
graph export "${savepath}/fig1.2.1.png", as(png) name("Graph") replace 

graph export "1.2.1_firms_by_tech.pdf", as(pdf) replace 


* Fig 5: VA LABOR PRODUCTIVITY (BY TECHNOLOGY) 

clear
use "unconditional_techknol_20e_weighted.dta", replace

keep country techknol year PV07_lprod_va_p50 PV07_lprod_va_p75 PV07_lprod_va_p25 TV02_exp_mn TV02_exp_sw TV02_exp_p75 TV02_exp_p50 TV02_exp_p25 LV28_jcr_pop_T_tot LV32_jdr_pop_T_tot


** VA Labor Productivity - Median and dispersion **
preserve
keep if year>=2010 & year<=2020 
drop if country=="Latvia" | country=="Netherlands" | country=="Malta" 
*| country=="Italy" | country=="Germany" 
* now we have a balanced panel of 18 countries between 2010-2020

keep country techknol year PV07_lprod_va_p50 PV07_lprod_va_p75 PV07_lprod_va_p25
collapse (mean) PV07_lprod_va_p50 PV07_lprod_va_p75 PV07_lprod_va_p25, by(techknol year)
gen PV07_lprod_va_disp=PV07_lprod_va_p75-PV07_lprod_va_p25

foreach m in p50 disp {
gen base_`m'_l= PV07_lprod_va_`m' if year==2010
by techknol: egen base_`m'=mean(base_`m'_l)
drop base_`m'_l
gen PV07_lprod_va_`m'_index=(PV07_lprod_va_`m'/base_`m')*100
gen PV07_lprod_va_`m'_growth=(PV07_lprod_va_`m'/base_`m'-1)*100
}

drop base* PV07_lprod_va_p75 PV07_lprod_va_p25
drop if techknol=="."
gen tr="_"
replace techknol=tr+techknol
drop tr
reshape wide PV07_lprod_va_p50-PV07_lprod_va_disp_growth, i(year) j(techknol) string

foreach n of numlist 1/6 {
label var PV07_lprod_va_p50_`n' "Tech `n' median"
label var PV07_lprod_va_p50_index_`n' "Tech `n' median in"
label var PV07_lprod_va_p50_growth_`n' "Tech `n' median gr"
label var PV07_lprod_va_disp_`n' "Tech `n' dispersion"
label var PV07_lprod_va_disp_index_`n' "Tech `n' dispersion in"
label var PV07_lprod_va_disp_growth_`n' "Tech `n' dispersion gr"
}

*export excel using "${savepath}/Technology_Charts.xlsx", firstrow(varlabels) sheet (Labor_prod, replace)

*keep if year==2020
*keep year *_growth_*
*reshape long PV07_lprod_va_p50_growth_ PV07_lprod_va_disp_growth_, i(year) j(techknol) string
*label var PV07_lprod_va_p50_growth_ "Median"
*label var PV07_lprod_va_disp_growth_ "Dispersion"

*export excel using "${savepath}/Technology_Charts.xlsx", firstrow(varlabels) sheet (Labor_prod_gr, replace)

keep year PV07_lprod_va_p50_index_1 PV07_lprod_va_p50_index_2 PV07_lprod_va_p50_index_3 PV07_lprod_va_p50_index_4 PV07_lprod_va_p50_index_5 PV07_lprod_va_p50_index_6

line PV07_lprod_va_p50_index_1 PV07_lprod_va_p50_index_2 PV07_lprod_va_p50_index_3 PV07_lprod_va_p50_index_4 PV07_lprod_va_p50_index_5 PV07_lprod_va_p50_index_6 year, plotregion(fcolor(white)) graphregion(fcolor(white)) legend(label(1 "Tech 1") label(2 "Tech 2") label(3 "Tech 3") label(4 "Tech 4") label(5 "Tech 5") label(6 "Tech 6")) ytitle("VA labor productivity" "(Index, 2010=100)" " ") lpattern(solid dash dot dash_dot shortdash longdash) scheme(s2color)

graph export "${savepath}/fig1.2.2.png", as(png) name("Graph") replace 

graph export "1.2.2_lab_prod_by_tech.pdf", as(pdf) replace

restore

************************************************************************


* Section 3: Frontier Firms Analysis *

* Fig 6
* Labor productivity gap between frontier and laggard firms: Europe (2000-2020)

clear
use "unconditional_industry2d_all_weighted.dta"
drop if year==2021 | year<2010
gen l=LV21_l_mn*LV21_l_sw
g k=FV14_rk_mn*FV14_rk_sw
g log_kl=log(k/l)

encode country, gen(countryname)

drop if country=="Netherlands"| country=="Latvia"
* also drop France because it has no observations on PV03_lnlprod_va_p90 and PV03_lnlprod_va_p10
drop if country=="France"
* now we have a balanced sample of 14 countries

reghdfe PV03_lnlprod_va_p90 i.year log_kl  [aweight=l], absorb (i.countryname#i.industry2d) cluster(industry2d)
est store a
reghdfe PV03_lnlprod_va_p10 i.year log_kl  [aweight=l], absorb (i.countryname#i.industry2d) cluster(industry2d)
est store b
coefplot (a, label(Frontier)) (b, label(Laggard)), drop(_cons log_kl) vertical recast(connected) title("Predicted labor productivity") graphregion(color(white)) bgcolor(white) nolabel coeflabels(, truncate(4))
graph export "${savepath}/fig1.3.1.png", as(png) name("Graph") replace 
graph export "1.3.1_productivity_gap.pdf", as(pdf) replace



/* repeating the analysis of fig 6 using joint distribution data:

use "jd_inp_prod_mac_sector_all_weighted.dta"

tab by_var
keep if by_var=="PV03_lnlprod_va"

*create dummy variable for frontier and laggard firms
sort country year mac_sector by_var_value
bysort country year mac_sector :gen frontier=1 if by_var_value==100
bysort country year mac_sector :replace frontier=0 if by_var_value==10
label def frontierlab 1 "Frontier firms" 0 "Laggard firms"
label val frontier frontierlab
tab frontier
keep if frontier!=.

encode country, gen (countryname)

drop if year==2021 | year<2010

gen l=LV21_l_mn*LV21_l_sw
g k=FV14_rk_mn*FV14_rk_sw
g log_kl=log(k/l)

reghdfe PV03_lnlprod_va_mn i.year log_kl  [aweight=l] if frontier==1, absorb (i.countryname#i.mac_sector) cluster(mac_sector)
est store a
reghdfe PV03_lnlprod_va_mn i.year log_kl  [aweight=l] if frontier==0, absorb (i.countryname#i.mac_sector) cluster(mac_sector)
est store b
coefplot (a, label(Frontier)) (b, label(Laggard)), drop(_cons log_kl) vertical recast(connected) title("Predicted labor productivity") graphregion(color(white)) bgcolor(white) nolabel coeflabels(, truncate(4))

* results are consistent

*/

* Fig 7
* Labor productivity gap between frontier and laggard firms by country (2020)

clear
use "unconditional_industry2d_all_weighted.dta"
tab country if PV03_lnlprod_va_p90!=.
keep if year==2020
bysort country year: gen frontier_labprod= PV03_lnlprod_va_p90 
bysort country year: gen laggard_labprod= PV03_lnlprod_va_p10 

tab country year if laggard_==.
tab country year if frontier_==.
drop if country=="France"
*balanced sample of 14 countries

graph bar frontier_labprod laggard_labprod, over(country, sort(1 ) descending label(angle(45))) ytitle("Log value-added labor productivity" "(2020)" " ") plotregion(fcolor(white)) graphregion(fcolor(white)) legend(label(1 "Frontier firms") label(2 "Laggard firms")) 
graph export "${savepath}/fig_1.3.2.png", as(png) name("Graph") replace 
graph export "1.3.2_productivity_gap_by_country.pdf", as(pdf) replace


* Table 1.3.1 
* comparing average size, lab prod, value added and real wage across countries: frontier firms vs laggard firms

clear
use "jd_inp_prod_mac_sector_all_weighted.dta"
tab by_var
keep if by_var=="PV03_lnlprod_va"

*create dummy variable for frontier and laggard firms

sort country year mac_sector by_var_value
bysort country year mac_sector :gen frontier=1 if by_var_value==100
bysort country year mac_sector :replace frontier=0 if by_var_value==10
label def frontierlab 1 "Frontier firms" 0 "Laggard firms"
label val frontier frontierlab
tab frontier
keep if frontier!=.
encode country, gen (countryname)

keep if year==2020
*balanced sample of 14 countries

*label var LV21_l_p50 size
*label var LV24_rwage_p50 realwage
*label var PV03_lnlprod_va_p50 va_labprod
*label var FV18_rva_p50 real_va

*table countryname  if type==1, stat (mean FV18_rva_p50 PV03_lnlprod_va_p50 LV24_rwage_p50 LV21_l_p50)
*table countryname  if type==2, stat (mean FV18_rva_p50 PV03_lnlprod_va_p50 LV24_rwage_p50 LV21_l_p50)

tabout country if frontier==1 using table_frontier.csv,  c(mean PV03_lnlprod_va_mn mean FV18_rva_mn mean LV24_rwage_mn mean LV21_l_mn) sum replace style(csv)

tabout country if frontier==0 using table_laggard.csv,  c(mean PV03_lnlprod_va_mn mean FV18_rva_mn mean LV24_rwage_mn mean LV21_l_mn) sum replace style(csv)


clear

************************************************************************
