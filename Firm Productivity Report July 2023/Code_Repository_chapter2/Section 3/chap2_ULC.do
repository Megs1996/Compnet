*creating dummies to distinguish between high technology intensity vs low technology intensity sectors in manufacturing
rename industry2d ind
tab ind
des ind
replace country = "Czech_Republic" if country == "Czech Republic"
drop if year<2000
label define years  2000 "2000" 2001 "2001" 2002 "2002" 2003 "2003" 2004 "2004" 2005 "2005" 2006 "2006" 2007 "2007" 2008 "2008" 2009 "2009" 2010 "2010" 2011 "2011" 2012 "2012" 2013 "2013" 2014 "2014" 2015 "2015" 2016 "2016" 2017 "2017" 2018 "2018" 2019 "2019" 2020 "2020" 2021 "2021"
label values year years

// high tech 
gen hightech=1 if ind==21|ind==26
replace hightech=0 if hightech!=1
// med high
gen med_high = 1 if ind==20|ind==27|ind==28|ind==29|ind==30
replace med_high=0 if med_high!=1
// low med
gen med_low = 1 if ind == 22|ind==23|ind==24|ind==25|ind==33
replace med_low = 0 if med_low != 1
// low
gen lowtech=1 if ind==10| ind == 11|ind == 12|ind == 13|ind == 14|ind == 15|ind == 16|ind == 17|ind == 18|ind == 31|ind == 32
replace lowtech = 0 if lowtech != 1

//knowledge next
gen high_know = 1 if ind == 50| ind == 51| ind == 58| ind == 59| ind == 60| ind == 61| ind == 62| ind == 63| ind == 69| ind == 70| ind == 71| ind == 72| ind == 73| ind == 74| ind == 75| ind == 78| ind == 80
replace high_know = 0 if high_know != 1
//low knowledge
gen low_know = 1 if ind == 45| ind == 46| ind == 47| ind == 49| ind == 52| ind == 53| ind == 56| ind == 68| ind == 77| ind == 79| ind == 81| ind == 82
replace low_know = 0 if low_know != 1
*creating dummies to distinguish between high knowledge intensity vs low knowledge intensity sectors in services


drop if year==2021
drop if year<2006


* this way we get a unbalanced panel of 14 countries between the years 2006-2020.
**********************************************************************************************************************************************************************************************
//Figure 2.1
**********************************************************************************************************************************************************************************************
**********************************************************************************************************************************************************************************************

* for manufacturing sectors:
tab country year
reghdfe PEb1_tfp_1_p50 i.year if hightech==1, absorb (country ind)
est store a
reghdfe PEb1_tfp_1_p50 i.year if med_high==1, absorb (country ind)
est store b
reghdfe PEb1_tfp_1_p50 i.year if med_low==1, absorb (country ind)
est store c
reghdfe PEb1_tfp_1_p50 i.year if lowtech==1, absorb (country ind)
est store d
coefplot (a, label(High-technology industries)) (b, label(Medium High -technology industries))(c, label(Medium Low -technology industries))(d, label(Low-technology industries)), drop(_cons) vertical recast(connected)
//service industries
reghdfe PEb1_tfp_1_p50 i.year if high_know==1, absorb (country ind)
est store P
reghdfe PEb1_tfp_1_p50 i.year if low_know==1, absorb (country ind)
est store Q
coefplot (P, label(High-Knowledge industries)) (Q, label(Low-Knowledge industries)), drop(_cons) vertical recast(connected)
//combined
coefplot (ulc_1, label("High-Technology Industries")) ///
         (ulc_2, label("Medium-High Technology Industries")) ///
         (ulc_3, label("Medium-Low Technology Industries")) ///
         (ulc_4, label("Low-Technology Industries")) ///
         (ulc_5, label("High-Knowledge Industries")) ///
         (ulc_6, label("Low-Knowledge Industries")), ///
         scheme(s2color) graphregion(color(white)) ///
         drop(_cons) vertical recast(connected) ///
         legend(label(1 "High-Technology Industries") ///
                  label(2 "Medium-High Technology Industries") ///
                  label(3 "Medium-Low Technology Industries") ///
                  label(4 "Low-Technology Industries") ///
                  label(5 "High-Knowledge Industries") ///
                  label(6 "Low-Knowledge Industries"))

**********************************************************************************************************************************************************************************************
//Figure 2.2
**********************************************************************************************************************************************************************************************
**********************************************************************************************************************************************************************************************

// choosing medians
reghdfe LR03_ulc_p50 i.year, absorb (country ind)
est store ulc_growth
//modify real wage 
replace LV24_rwage_p50 = LV24_rwage_p50/10

reghdfe LV24_rwage_p50 i.year, absorb (country ind)
est store wage_growth
reghdfe PV03_lnlprod_va_p50 i.year, absorb (country ind)
est store va_lprod_growth

coefplot (ulc_growth, label("ULC")) ///
         (wage_growth, label("Real Wages")) ///
         (va_lprod_growth, label("VA Labor Productivity")), ///
         drop(_cons) vertical recast(connected) ///
         legend(position(12))


