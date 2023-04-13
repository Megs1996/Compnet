clear all
cap restore // When "error capture" is enabled (which is the default behavior), Stata will intercept errors and store them, rather than displaying them immediately to the user. The cap restore command is used to turn off "error capture" and restore the default behavior of immediately displaying errors to the user. When "error capture" is turned off, Stata will immediately display any errors that occur and stop running the code.
cap log close //used to close the current log file that was opened using the log using command
set more off //used to turn off the "more" prompt that appears when output exceeds one screen

// Lines 13 to 60 produce charts c) e d) in Topic 1, the rest of the code is about productivity maps

* Create the following folders (whatever name) in your local machine and run the four next commands. The datasets used in this following should be stored in the below folde "9th vintage". Note that the access of the datasets is done via your CompNet access. Data uploaded in the related GitHub page are public and you can download them to run this code.
global main_dr "C:\Users\Ribeiro\Downloads\CompNet_23" // Set the main directory here - used to create a global macro to be used later in the session 
global data_dr "9th_Vintage" // Global macros in Stata are variables that can be accessed from anywhere in your do-file or ado-file, and their values can be changed at any point in your code. To access the value of a global macro, you can use the ${} syntax like "use ${data_dr}datafile.dta"

cd "$main_dr" //change directory

use "$data_dr\\unconditional_country_20e_weighted.dta", clear //upload dataset

keep country year PV02_lnlprod_rev_mn PV03_lnlprod_va_mn PV06_lprod_rev_mn PV07_lprod_va_mn FV08_nrev_mn FV08_nrev_sw PV06_lprod_rev_sd PV07_lprod_va_sd // keep only these variables
gen FV08_nrev_tot=FV08_nrev_mn*FV08_nrev_sw // The mn*sw is the way to retrieve totals in the weighted datasets. In these datasets the mean is indeed total/sum of weights rather than total/number of firms. Had the dataset been unweighted, it would have been mn*N

keep if year>=2010 & year<=2020 // We obtain a balanced panel of 17 obs by restricting to these years and dropping NL and LV
drop if country=="Netherlands" | country=="Latvia"

// Run the following lines (from preserve to store, lines 24-31) all at once, otherwise you will receive the error "nothing to restore"
preserve //preserve command is used when you want to make changes to the dataset, but also keep the original data intact. 
bys year: egen sum_FV08_nrev_tot=sum(FV08_nrev_tot) //The mn*sw is the way to retrieve totals in the weighted datasets. In these datasets the mean is indeed total/sum of weights rather than total/number of firms. Had the dataset been unweighted, it would have been mn*N. In summary, this command is useful when you want to create a new variable that represents a summary statistic (such as sum, mean, max, min, etc.) of a variable within each group defined by another variable. In this case, the new variable sum_FV08_nrev_tot will contain the sum of FV08_nrev_tot within each year.
gen sh_FV08_nrev_tot=FV08_nrev_tot/sum_FV08_nrev_tot // rationale (?)
gen wgt_PV06_lprod_rev_mn=sh_FV08_nrev_tot*PV06_lprod_rev_mn // rationale (?)
gen wgt_PV07_lprod_va_mn=sh_FV08_nrev_tot*PV07_lprod_va_mn // rationale (?)
collapse (sum) wgt_PV06_lprod_rev_mn wgt_PV07_lprod_va_mn, by(year) // collapses the dataset by year and calculates the sum of the variables wgt_PV06_lprod_rev_mn and wgt_PV07_lprod_va_mn for each year.
export excel using "Prod.xlsx", firstrow(varlabels) sheet (Trends, replace)
restore 

keep if year>=2016 & year <=2020
drop if country=="Switzerland"

/*bys year: egen avg_PV02_lnlprod_rev=sum(wgt_PV02_lnlprod_rev_mn)
bys year: egen avg_PV03_lnlprod_va=sum(wgt_PV03_lnlprod_va_mn)
gen dev_PV02_lnlprod_rev=PV02_lnlprod_rev_mn-avg_PV02_lnlprod_rev
gen dev_PV03_lnlprod_va=PV03_lnlprod_va_mn-avg_PV03_lnlprod_va*/

bys year: egen avg_PV02_lnlprod_rev=mean(PV02_lnlprod_rev_mn) // calculate the means by years
bys year: egen avg_PV03_lnlprod_va=mean(PV03_lnlprod_va_mn)
gen dev_PV02_lnlprod_rev=((PV02_lnlprod_rev_mn/avg_PV02_lnlprod_rev)-1)*100 // rationale (?) 
gen dev_PV03_lnlprod_va=((PV03_lnlprod_va_mn/avg_PV03_lnlprod_va)-1)*100

// run the next lines (between preserve and restore, both included) at once 
preserve
collapse (mean) dev_*, by(country) // creates a data with all countries and its respective deviations from PV02 and PV03, dev_* selects all variables containing "dev_" 
gsort -dev_PV02_lnlprod_rev // sort higher to lower
export excel using "Prod.xlsx", firstrow(varlabels) sheet (Deviations_srev, replace) // create a new tab in the Prod-xlsx
gsort -dev_PV03_lnlprod_va
export excel using "Prod.xlsx", firstrow(varlabels) sheet (Deviations_svad, replace)
restore

gen covid=0
replace covid=1 if year==2020 // create dummy for covid year

collapse (mean) dev_*, by(country covid) // creates a data with all countries and its respective deviations from PV02 and PV03 per status of being or not in Covid period
reshape wide dev_*, i(country) j(covid) // reshape the data
gsort -dev_PV02_lnlprod_rev1
export excel using "Prod.xlsx", firstrow(varlabels) sheet (Deviations_srev_cov, replace) // chart c)
gsort -dev_PV03_lnlprod_va1
export excel using "Prod.xlsx", firstrow(varlabels) sheet (Deviations_svad_cov, replace) // chart d)

// chart a)
clear all
import excel "Prod.xlsx", sheet("Trends") firstrow clear
//set scheme economist, set scheme s1rcolor or any other if you can change the style of your graph
twoway line sumwgt_PV06_lprod_rev_mn Year || line sumwgt_PV07_lprod_va_mn Year, ///
  xtitle("Year") ytitle("Labour productivity") legend(label(1 "Revenue based") label(2 "Value added based")) title("Labour productivity trends") subtitle("Revenues-weighted cross-country average") caption("Source: CompNet 9th Vintage, unconditional country 20e weighted") 
graph save "Graph" "$main_dr\Labour productivity trends.gph", replace

// chart b)
clear all
import excel "Prod.xlsx", sheet("Deviations_srev") firstrow clear
gen Country_short = strupper(substr(Countryname,1,2))
graph bar meandev_PV02_lnlprod_rev, over(Country_short) ytitle("") ylabel(,angle(vertical)) bar(1, color(gs8)) legend(off) title("Deviation from cross-country average") subtitle("Based on 2016-20 mean")
graph save "Graph" "$main_dr\Deviation from cross-country average.gph", replace

// chart c)
clear all
import excel "Prod.xlsx", sheet("Deviations_srev_cov") firstrow clear
gen Country_short = strupper(substr(Countryname,1,2))
graph bar (mean) dev_PV02_lnlprod_rev (mean) D, over(Country_short) legend(label(1 "2016-2019") label(2 "2020")) title("Deviation from cross-country average") subtitle("Revenues based") 
graph save "Graph" "$main_dr\Covid Deviation from cross-country average.gph", replace
	   

* Maps
use "$data_dr\\unconditional_nuts2_20e_weighted.dta", clear

keep country nuts2 year PV06_lprod_rev_mn PV07_lprod_va_mn PV06_lprod_rev_p50 PV07_lprod_va_p50
keep if year>=2016 
egen nuts2g=group(nuts2) // create a variable identifying each nuts for each country
drop if nuts2g==. // remove non-identifying nuts2
xtset nuts2g year // decalre a panel with nuts2 being the id

foreach p in PV06_lprod_rev_mn PV07_lprod_va_mn PV06_lprod_rev_p50 PV07_lprod_va_p50 {
	gen `p'_chng=`p'/l3.`p'-1
} //  loop that iterates over a list of four variables. Within the loop, the code generates a new variable name by appending the string "_chng" to the current variable name. New variables are created with the expression is "p'/l3.p'-1", which calculates the percentage change in the original variable relative to its 3-year lagged value. The loop continues to iterate over each variable in the list, creating a new variable for each one that measures its percentage change relative to its 3-year lagged value.
keep if year==2020
drop year

rename nuts2 FID

replace FID="PL71" if FID=="PL11" // rationale (?)
replace FID="PL92" if FID=="PL12"
replace FID="PL81" if FID=="PL31"
replace FID="PL82" if FID=="PL32"
replace FID="PL72" if FID=="PL33"
replace FID="PL84" if FID=="PL34"

merge 1:1 FID using "NUTS_RG_20M_2016_3035.shp\nutsdb" // merge with NUTS2 data. root source: https://ec.europa.eu/eurostat/web/gisco/geodata/reference-data/administrative-units-statistical-units/nuts

cd "NUTS_RG_20M_2016_3035.shp"

/*drop if _merge!=3
drop _merge*/
keep if LEVL_CODE==2 | LEVL_CODE==1 & CNTR_CODE=="DE" | LEVL_CODE==1 & CNTR_CODE=="IE" | LEVL_CODE==3 & CNTR_CODE=="BE" | LEVL_CODE==3 & CNTR_CODE=="ES"
drop if FID=="FRY1" |  FID=="FRY2" | FID=="FRY3" | FID=="FRY4" | FID=="FRY5"

// you may need to install the following packages to plot the maps (ssc install spmap, ssc install shp2dta, ssc install mif2dta - reference: https://www.stata.com/support/faqs/graphics/spmap-and-maps/)
spmap PV06_lprod_rev_mn_chng using nutscoord, id(id) fcolor(Blues) clnumber(8) ndfcolor(dimgray) title("Labor productivity, real revenue based - mean")
graph save "Graph" "$main_dr\Map_revlprodgr_mn_2017.gph", replace

spmap PV07_lprod_va_mn_chng using nutscoord, id(id) fcolor(Blues) clnumber(8) ndfcolor(dimgray) title("Labor productivity, real value added based - mean")
graph save "Graph" "$main_dr\Map_valprodgr_mn_2017.gph", replace

spmap PV06_lprod_rev_p50_chng using nutscoord, id(id) fcolor(Blues) clnumber(8) ndfcolor(dimgray) title("Labor productivity, real revenue based - median")
graph save "Graph" "$main_dr\Map_revlprodgr_p50_2017.gph", replace

spmap PV07_lprod_va_p50_chng using nutscoord, id(id) fcolor(Blues) clnumber(8) ndfcolor(dimgray) title("Labor productivity, real value added based - median")
graph save "Graph" "$main_dr\Map_valprodgr_p50_2017.gph", replace