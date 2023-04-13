clear all
cap restore // When "error capture" is enabled (which is the default behavior), Stata will intercept errors and store them, rather than displaying them immediately to the user. The cap restore command is used to turn off "error capture" and restore the default behavior of immediately displaying errors to the user. When "error capture" is turned off, Stata will immediately display any errors that occur and stop running the code.
cap log close //used to close the current log file that was opened using the log using command
set more off //used to turn off the "more" prompt that appears when output exceeds one screen

// This code produces charts a) and b) in Topic 3 

* Create the following folders (whatever name) in your local machine and run the four next commands.
global main_dr "C:\Users\Ribeiro\Downloads\CompNet_23" // Set the main directory here - used to create a global macro to be used later in the session 
global data_dr "9th_Vintage" // Global macros in Stata are variables that can be accessed from anywhere in your do-file or ado-file, and their values can be changed at any point in your code. To access the value of a global macro, you can use the ${} syntax like "use ${data_dr}datafile.dta"
global sub_dr "Allocative_Efficiency" // Set the sub-directory here

cd "$main_dr\\$sub_dr"

capture noisily mkdir Weights

// Prepare weights

local base_year "2010" //defining a local macro called base_year with a value of 2000 ( local macros are temporary and are lost when the Stata session or do-file ends)

* Country
use "$main_dr\\$data_dr\unconditional_country_20e_weighted.dta", clear //import the data
drop if country=="Latvia" | country=="Netherlands" | country=="Switzerland" // exclude these countries. LV and NL are dropped to obtain a balanced sample over 2010-2020
keep country year FV08_nrev_mn FV08_nrev_sw // keep only these variables
gen rev=FV08_nrev_mn*FV08_nrev_sw // rationale (?)
keep country year rev 
save "Weights\Wgt_country.dta", replace

* Age
use "$main_dr\\$data_dr\unconditional_age_firm_20e_weighted.dta", clear
drop if country=="Latvia" | country=="Netherlands" | country=="Switzerland" 
keep country year age_firm FV08_nrev_mn FV08_nrev_sw
gen rev=FV08_nrev_mn*FV08_nrev_sw
keep country year age_firm rev
save "Weights\Wgt_age.dta", replace

* Technology
use "$main_dr\\$data_dr\unconditional_techknol_20e_weighted.dta", clear
drop if country=="Latvia" | country=="Netherlands" | country=="Switzerland" 
keep country year techknol FV08_nrev_mn FV08_nrev_sw
gen rev=FV08_nrev_mn*FV08_nrev_sw
keep country year techknol rev
save "Weights\Wgt_techknol.dta", replace


// Compute averages for allocative efficiency

* Country
use "$main_dr\\$data_dr\op_decomp_country_20e_weighted.dta", clear
drop if country=="Latvia" | country=="Netherlands" | country=="Switzerland" 
keep if weight_type=="standard" // rationale (?)
keep country year PV07_lprod_va_Wl_cov FR35_va_rev_Wnrv_cov PV06_lprod_rev_Wl_cov
merge 1:1 country year using "Weights\Wgt_country.dta" // merge with previous data
collapse (mean) PV07_lprod_va_Wl_cov FR35_va_rev_Wnrv_cov PV06_lprod_rev_Wl_cov [weight=rev], by(year) // compute the mean of each variable and rev is used as weight in the calculation of the means. Means for each year (by option) are calculated
drop if year < 2010 | year > 2020  // few observations after 2020 . alternatively drop if year < `base_year' | year > 2020

foreach v of varlist PV07_lprod_va_Wl_cov FR35_va_rev_Wnrv_cov PV06_lprod_rev_Wl_cov { //loops over the variables listed in varlist (i.e., PV07_lprod_va_Wl_cov, FR35_va_rev_Wnrv_cov, PV06_lprod_rev_Wl_cov) using the foreach 
gen base_l= `v' if year==2010 //`base_year' //For each variable v, the code generates a new variable called base_l, which is equal to the value of v only for observations where the variable year is equal to a specified value stored in the macro base_year.
egen base=mean(base_l) 
//calculates the mean of base_l using the egen command and stores the result in a new variable called base_l
gen ind_`v'=(`v'/base)*100 
//generates a new variable called ind_v``, which is equal to the ratio of v to base, multiplied by 100. This creates a new variable for each original variable in varlist, representing the ratio of that variable relative to the base year.
drop base* //drops the intermediate variables base_l and base
}
save "Al_eff_country.dta", replace

* Age
use "$main_dr\\$data_dr\op_decomp_age_firm_20e_weighted.dta", clear
drop if country=="Latvia" | country=="Netherlands" | country=="Switzerland" 
keep if weight_type=="standard"
keep country year age_firm PV07_lprod_va_Wl_cov FR35_va_rev_Wnrv_cov PV06_lprod_rev_Wl_cov
merge 1:1 country year age_firm using "Weights\Wgt_age.dta"
drop if age_firm=="."
collapse (mean) PV07_lprod_va_Wl_cov FR35_va_rev_Wnrv_cov PV06_lprod_rev_Wl_cov [weight=rev], by(year age_firm) 
gen a="_a"
replace age_firm=a+age_firm
drop a
drop if year< 2010 | year>2020 //`base_year'
foreach v of varlist PV07_lprod_va_Wl_cov FR35_va_rev_Wnrv_cov PV06_lprod_rev_Wl_cov {
gen base_l= `v' if year==2010 //`base_year'
bys age_firm: egen base=mean(base_l)
gen ind_`v'=(`v'/base)*100
drop base*
}
reshape wide *PV07_lprod_va_Wl_cov *FR35_va_rev_Wnrv_cov *PV06_lprod_rev_Wl_cov, i(year) j(age_firm) string // reshaping of data from a "long" format to a "wide" format. The data is being reshaped according to the values in two identifier variables: "year" and "age_firm". The "i(year) j(age_firm)" part of the code specifies that "year" is the row identifier, and "age_firm" is the column identifier.The last part of the code, "string", indicates that the values in the reshaped data will be treated as string variables.
save "Al_eff_age.dta", replace

* Technology
use "$main_dr\\$data_dr\op_decomp_techknol_20e_weighted.dta", clear
drop if country=="Latvia" | country=="Netherlands" | country=="Switzerland" 
keep if weight_type=="standard"
keep country year techknol PV07_lprod_va_Wl_cov FR35_va_rev_Wnrv_cov PV06_lprod_rev_Wl_cov
merge 1:1 country year techknol using "Weights\Wgt_techknol.dta"
drop if techknol=="."
collapse (mean) PV07_lprod_va_Wl_cov FR35_va_rev_Wnrv_cov PV06_lprod_rev_Wl_cov [weight=rev], by(year techknol) 
gen t="_t"
replace techknol=t+techknol
drop t
drop if year< 2010 | year>2020
foreach v of varlist PV07_lprod_va_Wl_cov FR35_va_rev_Wnrv_cov PV06_lprod_rev_Wl_cov {
gen base_l= `v' if year==2010
bys techknol: egen base=mean(base_l)
gen ind_`v'=(`v'/base)*100
drop base*
}
reshape wide *PV07_lprod_va_Wl_cov *FR35_va_rev_Wnrv_cov *PV06_lprod_rev_Wl_cov, i(year) j(techknol) string
save "Al_eff_techknol.dta", replace

* Join allocative efficiency datasets
use "Al_eff_country.dta", clear
merge 1:1 year using "Al_eff_age.dta"
keep if _merge==3
drop _merge
merge 1:1 year using "Al_eff_techknol.dta"
keep if _merge==3
drop _merge
*drop *_t6 // For tech 6, often variables switch sign inducing strange patterns

label var PV07_lprod_va_Wl_cov "VA Labor Productivity"
label var FR35_va_rev_Wnrv_cov "VA on Revenues share"
label var PV06_lprod_rev_Wl_cov "Revenues Labor Productivity"

label var ind_PV07_lprod_va_Wl_cov "VA Labor Productivity, `base_year'=100"
label var ind_FR35_va_rev_Wnrv_cov "VA on Revenues share, `base_year'=100"
label var ind_PV06_lprod_rev_Wl_cov "Revenues Labor Productivity, `base_year'=100"

foreach v of varlist PV07_lprod_va_Wl_cov FR35_va_rev_Wnrv_cov PV06_lprod_rev_Wl_cov { //loop with the foreach command to repeat a set of commands for each variable in the list PV07_lprod_va_Wl_cov FR35_va_rev_Wnrv_cov PV06_lprod_rev_Wl_cov
twoway (line `v' year, lcolor(black)  lwidth(thick)) (line `v'_a1 year, lcolor(lime)) (line `v'_a2 year, lcolor(dkgreen)), title("`: var label `v''", size(small)) legend(size(vsmall) rows(1) label(1 "Total") label(2 "Age group 1") label(3 "Age group 2")) ytitle("") xtitle("") ylabel(,labsize(tiny)) xlabel(2010 (2)2020,labsize(vsmall)) graphregion(fcolor(white)) note("Source: op_decomp_country_20e_weighted.dta, op_decomp_age_firm_20e_weighted.dta." "Variable: `v'.") name(gal`v') //It specifies a three-line graph for each variable using the twoway command. Each line corresponds to a different age group: the total, age group 1, and age group 2
save "Allocative_Efficiency_lev_age.pdf", replace
} //In summary, this code generates a set of line graphs for three variables, each with three lines representing different age groups, and saves them in a PDF file

// chart b)
foreach v in PV07_lprod_va_Wl_cov FR35_va_rev_Wnrv_cov PV06_lprod_rev_Wl_cov {
twoway (line ind_`v' year, lcolor(black)  lwidth(thick)) (line ind_`v'_a1 year, lcolor(lime)) (line ind_`v'_a2 year, lcolor(dkgreen)), title("`: var label ind_`v''", size(small)) legend(size(vsmall) rows(1) label(1 "Total") label(2 "Age group 1") label(3 "Age group 2")) ytitle("") xtitle("") ylabel(,labsize(tiny)) xlabel(2010 (2)2020,labsize(vsmall)) graphregion(fcolor(white)) note("Source: op_decomp_country_20e_weighted.dta, op_decomp_age_firm_20e_weighted.dta." "Variable: `v'.") name(gai`v')
save "Allocative_Efficiency_ind_age.pdf", replace
}

foreach v of varlist PV07_lprod_va_Wl_cov FR35_va_rev_Wnrv_cov PV06_lprod_rev_Wl_cov {
twoway (line `v' year, lcolor(black)  lwidth(thick)) (line `v'_t1 year, lcolor(blue)) (line `v'_t2 year, lcolor(midblue)) (line `v'_t3 year, lcolor(eltblue)) (line `v'_t4 year, lcolor(ltblue)) (line `v'_t5 year, lcolor(bluishgray)) (line `v'_t6 year, lcolor(lavender)), title("`: var label `v''", size(small)) legend(size(vsmall) rows(3) label(1 "Total") label(2 "Technology group 1") label(3 "Technology group 2") label(4 "Technology group 3") label(5 "Technology group 4") label(6 "Technology group 5") label(7 "Technology group 6")) ytitle("") xtitle("") ylabel(,labsize(tiny)) xlabel(2010 (2)2020,labsize(vsmall)) graphregion(fcolor(white)) note("Source: op_decomp_country_20e_weighted.dta, op_decomp_techknol_20e_weighted.dta." "Variable: `v'.") name(gtl`v')
save "Allocative_Efficiency_lev_tech.pdf", replace
}

// chart a)
foreach v in PV07_lprod_va_Wl_cov FR35_va_rev_Wnrv_cov PV06_lprod_rev_Wl_cov {
twoway (line ind_`v' year, lcolor(black)  lwidth(thick)) (line ind_`v'_t1 year, lcolor(blue)) (line ind_`v'_t2 year, lcolor(midblue)) (line ind_`v'_t3 year, lcolor(eltblue)) (line ind_`v'_t4 year, lcolor(ltblue)) (line ind_`v'_t5 year, lcolor(bluishgray)) /*(line `v'_t6 year, lcolor(ltbluishgray))*/, title("`: var label ind_`v''", size(small)) legend(size(vsmall) rows(2) label(1 "Total") label(2 "Technology group 1") label(3 "Technology group 2") label(4 "Technology group 3") label(5 "Technology group 4") label(6 "Technology group 5") /*label(6 "Technology group 6")*/) ytitle("") xtitle("") ylabel(,labsize(tiny)) xlabel(2010 (2)2020,labsize(vsmall)) graphregion(fcolor(white)) note("Source: op_decomp_country_20e_weighted.dta, op_decomp_techknol_20e_weighted.dta." "Variable: `v'.") name(gti`v')
save "Allocative_Efficiency_ind_tech.pdf", replace
}