clear all
cap restore
cap log close
set more off

// This code decomposes year-on-year export growth rates into the intensive and extensive margins.
// Following Bricongne et al. (2022), these are respectively the growth rates in the mean export value and the number of exporters:
// Export = mean(Export) x numerosity(Export) -> ΔExport = Δmean(Export) + Δnumerosity(Export)

global main_dr "C:\Users\Marco\Desktop\CompNet 2023" // Set the main directory here
global data_dr "9th Vintage" // Set the input data directory here

cd "$main_dr"

use "$data_dr\unconditional_country_20e_unweighted.dta", clear
keep country year TV02_exp_mn TV04_exp_ex_mn TV06_exp_in_mn TV08_imp_mn TV10_imp_ex_mn TV12_imp_in_mn TV02_exp_N TV04_exp_ex_N TV06_exp_in_N TV08_imp_N TV10_imp_ex_N TV12_imp_in_N // Keep the variables of interest

preserve
keep country year TV02_exp_*
keep if TV02_exp_mn!=. // Drop empty observations
keep if year>=2010 & year<=2020 // We obtain a balanced panel of the 14 countries with trade variables
// by restricting to these years and dropping NL
drop if country=="Netherlands"
gen TV02_exp_tot=TV02_exp_mn*TV02_exp_N // First, we retrieve the total export amount (note this is done by multiplying 
// export and numerosity because we are using unweighted data, whereas with weighted data we should have used the sum of 
// weights rather than numerosity)
collapse (sum) TV02_exp_tot TV02_exp_N, by(year) // We are interested to the yearly total export for our sample of countries
gen TV02_exp_mn=TV02_exp_tot/TV02_exp_N // Here we compute the yearly mean export value over our sample of countries
tsset year

// We construct an index for export total, mean, and numerosity with base year = 2010, then we take year-on-year growth rates
foreach v in tot mn N {
gen base_`v'_l=TV02_exp_`v' if year==2010 
egen base_`v'=mean(base_`v'_l)
drop base_`v'_l
gen ind_`v'= (TV02_exp_`v'/base_`v')*100
gen gr_ind_`v'=((ind_`v'/l.ind_`v')-1)*100
}

keep year *ind*
export excel using "Trade_decomp.xlsx", firstrow(varlabels) sheet (Exp, replace) // We export to excel to build charts
restore

// We repeat the process, but for export destination (inside or outside the EU) rather than overall
keep if TV04_exp_ex_mn!=. & TV06_exp_in_mn!=. // Drop empty observations
keep country year TV04_exp_ex_mn TV06_exp_in_mn TV04_exp_ex_N TV06_exp_in_N // Keep the variables of interest
keep if year>=2010 & year<=2020 // We obtain a balanced panel of the countries that have trade variables by destination 
// by restricting to these years and dropping NL and RO
drop if country=="Netherlands" | country=="Romania"

gen TV04_exp_ex_tot=TV04_exp_ex_mn*TV04_exp_ex_N // Revert total amounts for exports outside the EU (note this is done by multiplying 
// export and numerosity because we are using unweighted data, whereas with weighted data we should have used the sum of 
// weights rather than numerosity)
gen TV06_exp_in_tot=TV06_exp_in_mn*TV06_exp_in_N // Revert total amounts for exports inside the EU
collapse (sum) *_tot *_N, by(year) // We are interested to the yearly total export for our sample of countries
gen TV04_exp_ex_mn=TV04_exp_ex_tot/TV04_exp_ex_N // Here we compute the yearly mean outside-EU export value over our sample of countries
gen TV06_exp_in_mn=TV06_exp_in_tot/TV06_exp_in_N // Here we compute the yearly mean inside-EU export value over our sample of countries
tsset year


// For export both outside and inside the EU, we construct an index for export total, mean, and numerosity with base year = 2010, then we take
// year-on-year growth rates 
foreach d in 4_exp_ex 6_exp_in {
foreach v in tot mn N {
gen base_`d'_`v'_l=TV0`d'_`v' if year==2010
egen base_`d'_`v'=mean(base_`d'_`v'_l)
drop base_`d'_`v'_l
gen ind_`d'_`v'= (TV0`d'_`v'/base_`d'_`v')*100
gen gr_ind_`d'_`v'=((ind_`d'_`v'/l.ind_`d'_`v')-1)*100
}
}

keep year *ind*
export excel using "Trade_decomp.xlsx", firstrow(varlabels) sheet (Exp_ex_in, replace) // We export to excel to build charts

keep year gr_ind_*

// Compute the share of each margin (extensive=numerosity, intensive=mean) on the total growth rate
foreach d in 4_exp_ex 6_exp_in {
foreach v in mn N {
gen grsh_`d'_`v'=(gr_ind_`d'_`v'/gr_ind_`d'_tot)*100
}
}

keep year grsh_*
rename grsh_4_exp_* grsh_*
rename grsh_6_exp_* grsh_*
rename grsh_*_mn grsh_mn_*
rename grsh_*_N grsh_N_*

// We transform the dimension from being a variable into a category
reshape long grsh_mn_ grsh_N_, i(year) j(dir) string

replace dir="Outside EU" if dir=="ex"
replace dir="Inside EU" if dir=="in"

sort year dir

// These commands help to sort data for excel
gen d=.
bys year: gen n=_n
replace year=. if n>1
drop n

export excel using "Trade_decomp.xlsx", firstrow(varlabels) sheet (Exp_ex_in_grsh, replace) // We export to excel to build charts


********************
// We repeat the process, but for size classes rather than export destinations

use "$data_dr\unconditional_macsec_szcl_20e_unweighted.dta", clear
keep country year macsec_szcl TV02_exp_mn TV04_exp_ex_mn TV06_exp_in_mn TV08_imp_mn TV10_imp_ex_mn TV12_imp_in_mn TV02_exp_N TV04_exp_ex_N TV06_exp_in_N TV08_imp_N TV10_imp_ex_N TV12_imp_in_N // We keep the variables of interest

gen mac_sec=substr(macsec_szcl, 1, 6) 
gen szcl=substr(macsec_szcl, 8, 5) // Disentangle size classes
drop macsec_szcl
order country year mac_sec szcl
sort country year mac_sec szcl

*preserve
keep country year mac_sec szcl TV02_exp_*
keep if TV02_exp_mn!=. // Drop empty observations
keep if year>=2010 & year<=2020 // We obtain a balanced panel of 42 country-size class combinations that have trade variables
// by restricting to these years and dropping NL
drop if country=="Netherlands"
gen TV02_exp_tot=TV02_exp_mn*TV02_exp_N // Revert total export amounts (note this is done by multiplying 
// export and numerosity because we are using unweighted data, whereas with weighted data we should have used the sum of 
// weights rather than numerosity)
collapse (sum) TV02_exp_tot TV02_exp_N, by(year szcl) // We are interested to the sample total, by size class
gen TV02_exp_mn=TV02_exp_tot/TV02_exp_N // Derive the mean for the sample, by size class
egen szcl_g=group(szcl) 
drop szcl
xtset szcl_g year // Set panel data structure
sort szcl_g year

// For each size class, we construct an index for export total, mean, and numerosity with base year = 2010, then we take
// year-on-year growth rates 
foreach v in tot mn N {
gen base_`v'_l=TV02_exp_`v' if year==2010
bys szcl: egen base_`v'=mean(base_`v'_l)
drop base_`v'_l
gen ind_`v'= (TV02_exp_`v'/base_`v')*100
gen gr_`v'=((ind_`v'/l.ind_`v')-1)*100 
gen chg_`v'=(gr_`v'/100)*l.TV02_exp_`v'
}

preserve
keep year szcl ind* gr* chg*
rename ind* ind*_
rename gr* gr*_
rename chg* chg*_
reshape wide ind_tot_- chg_N_, i(year) j(szcl_g) // We transform size classes from being a category to variables
export excel using "Trade_decomp.xlsx", firstrow(varlabels) sheet (Exp_szcl, replace) // We export to excel to build charts
keep year gr*

// Compute the share of each margin (extensive=numerosity, intensive=mean) on the total growth rate
foreach v in mn N {
	foreach n of numlist 1/3 {
		gen gr_sh_`v'_`n'=(gr_`v'_`n'/gr_tot_`n')*100
	}
}	

keep year gr_sh_*
reshape long gr_sh_mn_ gr_sh_N_, i(year) j(szcl) // We transform size classes from being a variable to categories

// These commands help to sort data for excel
gen d=.
bys year: gen n=_n
replace year=. if n>1
drop n

tostring szcl, replace
replace szcl="20-49 empl." if szcl=="1"
replace szcl="50-249 empl." if szcl=="2"
replace szcl=">249 empl." if szcl=="3"

export excel using "Trade_decomp.xlsx", firstrow(varlabels) sheet (Exp_szcl_grsh, replace) // We export to excel to build charts
restore

keep year szcl_g TV02_exp_* chg_*
order year szcl_g
sort year szcl_g

// Compute shares of each size class on the export numerosity, totals, and margins
foreach a in TV02_exp chg {
foreach v in tot mn N {
	bys year: egen sum_`a'_`v'=sum(`a'_`v')
	gen sh_`a'_`v'=(`a'_`v'/sum_`a'_`v')*100
  }
}
drop *_TV02_exp_mn
keep year szcl_g sh_*

rename sh_TV02_exp_* sh_*

reshape long sh_, i(year szcl_g) j(var) string // We put as categories the different dimensions on which we have computed shares 
reshape wide sh_, i(year var) j(szcl_g) // We transform size classes from being a category to variables

replace var="dIntensive margin" if var=="chg_mn"
replace var="cTotal margin" if var=="chg_tot"
replace var="aTotal export" if var=="tot"
replace var="bTotal n. firms" if var=="N"
replace var="eExtensive margin" if var=="chg_N"

sort year var
replace var=substr(var,2,.)

// These commands help to sort data for excel
gen d=.
bys year: gen n=_n
replace year=. if n>1
drop n

export excel using "Trade_decomp.xlsx", firstrow(varlabels) sheet (Exp_szcl_chg, replace) // We export to excel to build charts

