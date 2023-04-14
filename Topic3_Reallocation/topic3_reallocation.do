
*----------------------------------------------------------------
/*
Reallocation over the business cycle.

Authors: Leonardo Indraccolo 

This version: 18.02.23

This do file:

1) Produces summary stats of JC and JD over the business cycle 
2) Produces summary stats of JC and JD over the business cycle and countries 
3) Produces summary stats of JC and JD by firm age 
4) Plots cdf of average firm age by countries 
*/

*----------------------------------------------------------------

*Data preparation 

*----------------------------------------------------------------

clear all 

* Set output directory
global output "...\Replication-Packages\Topic3_Reallocation"

*Choose Compnet sample
global sample "20e"

*Weighted or unweighted version 
global weight "weighted" 

* Set data directory 
global data ".../${sample}_firms_${weight}/Descriptives/unconditional_mac_sector_${sample}_${weight}.dta"

*Load and prepare the CompNet file 
use "$data" , clear 

*Keep and rename only variables you want to work with 
rename LV12_jdr_pop_M_tot jdr
rename LV02_jcr_pop_M_tot jcr 
rename OV01_firm_age_atexit_mn age_exit
rename OV00_firm_age_mn age_mean

keep country year mac_sector  jdr jcr age_exit age_mean

*Tab country 
tab country 

*Drop switzerland and malta (19 countries remaining )
drop if country=="Switzerland" | country=="Malta"

*Tab years (years go from 1999 to 2021)
tab year

*Portugal only starts in 2010. All others start before (at least during great recession)
bys country:tab year  

*Tab sectors 
tab mac_sector

*Drop real estate and admin sectors 
drop if mac_sector==7 | mac_sector==9

*Generate flags for recessions (2009,2012,2020)
g flag=0
replace flag=1 if year==2009 | year==2012 | year==2020

*Generate flag for covid or great recessions and normal times (==0: normal times; ==1: covid; ==2: great recession)
cap drop covid_rec
g covid_rec=0
replace covid_rec=1 if year==2020
replace covid_rec=2 if year==2009 | year==2012
label define covidlabel 0 "normal times" 1 "covid" 2 "great recession"
label values covid_rec covidlabel

*Drop 2021 and years before 2005 because of small sample size. Sample dimension seems stable from 2005
drop if year==2021
drop if year<2005

*---------------------------------------------------------------------------
*Analysis
*---------------------------------------------------------------------------

/*
Sample time span: 2005-2020. Sample is unbalanced. All countries exept Portugal start at least in 2009. 
*/

*JCR and JDR over the business cycle 
bys flag: sum jcr,d
bys flag: sum jdr,d


*JCR and JDR across great recession and covid recession 
eststo clear
estpost tabstat jcr jdr, by(covid_rec) statistics(mean) columns(statistics) listwise nototal
esttab . using "$output/jcr_jdr_over_business_cycle.tex", replace main(mean) nostar unstack noobs nonote label nonumber title("JC and JD over the business cycle")


*Define country groups (==0: southern ,==1: nordic, ==2: east, ==3: central )
cap drop country_group
g country_group =0 
*North
replace country_group = 1 if country=="Finland" | country=="Denmark" | country=="Sweden"
*East 
replace country_group = 2 if country=="Croatia" | country=="Czech Republic" | country=="Hungary" | country=="Latvia"
replace country_group=2 if  country=="Lithuania" | country=="Poland" | country=="Romania"
replace country_group=2 if country=="Slovakia" |country=="Slovenia" 
*Central
replace country_group=3 if country=="Belgium" |country=="France" | country=="Germany" | country=="Netherlands"

label define countrylabel 0 "southern" 1 "nordic" 2 "east" 3 "central"
label values country_group countrylabel


*check 
bys country_group: tab country



*JCR and JDR across great recession and covid recession and country groups
eststo clear
levelsof covid_rec
foreach l in `r(levels)' {
	eststo jcr`l': estpost tabstat jcr if covid_rec == `l', by(country_group) statistics(mean) columns(statistics) listwise nototal
	eststo jdr`l': estpost tabstat jdr if covid_rec == `l', by(country_group) statistics(mean) columns(statistics) listwise nototal
}
esttab *0 *1 *2 using "$output/jcr_jdr_across_countries_and_business_cycle.tex",main(mean) nostar noobs nonote label nonumber mtitles("JC" "JD" "JC" "JD" "JC" "JD") mgroups("normal times" "covid" "great recession", pattern(1 0 1 0 1 0)) replace title("JC and JD across countries and business cycle")


/*
Age at exit cannot be used because almost always missing 
*/


*Generate age quintile based on mean age. Pool together years and countries and sectors 
cap drop age_decile
xtile age_decile = age_mean,nq(5)
label define agelabel 1 "Age quintile 1" 2 "Age quintile 2" 3 "Age quintile 3" 4 "Age quintile 4" 5 "Age quintile 5"
label values age_decile agelabel


*JC and JD by firm age 
eststo clear
eststo jcr: estpost tabstat jcr, by(age_decile) statistics(mean) columns(statistics) listwise nototal
eststo jdr: estpost tabstat jdr, by(age_decile) statistics(mean) columns(statistics) listwise nototal
esttab jcr jdr using "$output/jcr_jdr_by_firm_age.tex", main(mean) nostar unstack noobs nonote label nonumber replace mtitles("JCR" "JDR") title("JC and JD by firm age")


*JC and JD by firm age and recession
eststo clear
levelsof covid_rec
foreach l in `r(levels)' {
	eststo jcr`l': estpost tabstat jcr if covid_rec == `l', by(country_group) statistics(mean) columns(statistics) listwise nototal
	eststo jdr`l': estpost tabstat jdr if covid_rec == `l', by(country_group) statistics(mean) columns(statistics) listwise nototal
}
esttab *0 *1 *2 using "$output/jcr_jdr_by_age_and_aggregate_state.tex",main(mean) nostar noobs nonote label nonumber mtitles("JC" "JD" "JC" "JD" "JC" "JD") mgroups("normal times" "covid" "great recession", pattern(1 0 1 0 1 0)) title("JC and JD by firm age and aggregate state") replace
 
bys age_decile covid_rec : sum jdr,d
bys age_decile covid_rec  : sum jcr,d



*Firm age distribution 

preserve
drop if mac_sector==5
twoway kdensity age_mean if country_group==0, bwidth(1.3) lwidth(0.4)|| kdensity age_mean if country_group==1,bwidth(1.3) lwidth(0.4) || kdensity age_mean if country_group==2,bwidth(1.3) lwidth(0.4)|| kdensity age_mean if country_group==3,bwidth(1.3) lwidth(0.4) legend( label(1 "Southern countries") label(2 "Nordic countries") label(3 "East countries") label(4 "Central countries") nobox) graphregion(color(white)) title("") xtitle("Average firm age ") ytitle("density")
restore 



*CDF of age distribution 
*Define country groups (==0: southern ,==1: nordic, ==2: east, ==3: central )

preserve
cumul age_mean if country_group==0, g(cum_s)
cumul age_mean if country_group==1, g(cum_n) 
cumul age_mean if country_group==2, g(cum_e)
cumul age_mean if country_group==3, g(cum_c)

stack cum_s age_mean cum_n age_mean cum_e age_mean cum_c age_mean, into(ecd v) wide clear

line cum_s cum_n cum_e cum_c v, sort lwidth(thick thick thick thick) lpattern(solid dash dashdot dash) xtitle("Average firm age") ytitle("Cumulative Probability") legend(label(1 "Southern") label(2 "Nordic") label(3 "Eastern") label(4 "Central") nobox region(lcolor(white))) graphregion(color(white)) title("Age distribution of firms by countries")
graph export "$output/age_distribution_of_firms_by_country.pdf", replace
restore 















