clear all
cap restore // When "error capture" is enabled (which is the default behavior), Stata will intercept errors and store them, rather than displaying them immediately to the user. The cap restore command is used to turn off "error capture" and restore the default behavior of immediately displaying errors to the user. When "error capture" is turned off, Stata will immediately display any errors that occur and stop running the code.
cap log close //used to close the current log file that was opened using the log using command
set more off //used to turn off the "more" prompt that appears when output exceeds one screen

* Create the following folders (whatever name) in your local machine and run the four next commands changing the path according to the ones you created on your machine.
global main_dr "C:\Users\Ribeiro\Downloads\CompNet_23" // Set the main directory here - used to create a global macro to be used later in the session 
global data_dr "9th_Vintage" // Global macros in Stata are variables that can be accessed from anywhere in your do-file or ado-file, and their values can be changed at any point in your code. To access the value of a global macro, you can use the ${} syntax like "use ${data_dr}datafile.dta"
global sub_dr "Tech_wage_alleff" // Set the sub-directory here

cd "$main_dr"

* Employment share of high-tech and knowledge-intensive industries
use "$data_dr\unconditional_techknol_20e_weighted.dta", clear
keep country techknol year LV21_l_mn LV21_l_sw //keep only these variables
gen tot_l=LV21_l_mn*LV21_l_sw //gen new variable related to total labour
bys year country: egen cntr_tot_l=sum(tot_l) //bys year country: specifies that the following command should be executed separately for each unique combination of the variables "year" and "country", also know as "by-group" operation. egen cntr_tot_l= creates a new variable called "cntr_tot_l". sum(tot_l) calculates the sum of values in the variable "tot_l". sum(tot_l) is calculated within each by-group. In summary, this code calculates the sum of values in the variable "tot_l" for each unique combination of "year" and "country", and saves these sums in a new variable called "cntr_tot_l".
gen share_l=(tot_l/cntr_tot_l)*100
keep if year==2020
keep if techknol=="1" | techknol=="5"
collapse (sum) share_l, by(country year) //collapse reduces the dataset to a summary level (a summation, (sum)) by aggregating data within groups. share_l is the variable that is being aggregated. It is the variable for which the summation will be calculated. by(country year) specifies that the summation should be calculated separately for each unique combination of the variables "country" and "year".
save "$sub_dr\tech.dta", replace

* Allocative efficiency
use "$data_dr\op_decomp_country_20e_weighted.dta", clear
keep if weight_type=="standard" & year==2020
keep country year PV06_lprod_rev_Wl_cov
save "$sub_dr\alleff.dta", replace

* Wages
use "$data_dr\unconditional_country_20e_weighted.dta", clear
keep country year LV00_avg_wage_mn
keep if year==2020

merge 1:1 country year using "$sub_dr\alleff.dta"
drop _merge
merge 1:1 country year using "$sub_dr\tech.dta"
drop _merge

graph dot (mean) LV00_avg_wage_mn (mean) PV06_lprod_rev_Wl_cov (mean) share_l, over(country) legend(label(1 "Average Wage")) legend(label(2 "Allocation")) legend(label(3 "Share Labour"))

export excel using "$sub_dr\Tech_wage_alleff.xlsx", firstrow(varlabels) sheet (Sheet1, replace)


