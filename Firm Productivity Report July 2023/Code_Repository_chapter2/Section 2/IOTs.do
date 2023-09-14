clear all
cap restore
cap log close
set more off

*** This code prepares data from the OECD ICIO tables for computations in Section 2

global main_dr "C:\Users\Marco\Desktop\CompNet 2023" // Set the main directory here
global data_dr "IOTs" // Set the input data directory here
global sub_dr "GVC Analysis" // Set the sub-directory here

cd "$main_dr\\$sub_dr"

forvalues y = 2000/2018 {
	import delimited "$data_dr\ICIO2021_`y'.csv", clear 
	gen year=`y'
	order year *
	gen country=substr(v1,1,3)
	gen industry=substr(v1,5,.)
	keep if country=="AUT" | country=="BEL" | country=="HRV" | country=="CZE" | country=="DNK" | country=="FIN" | country=="FRA" | country=="DEU" | country=="HUN" | country=="ITA" | country=="LVA" | country=="LTU" | country=="MLT" | country=="NLD" | country=="POL" | country=="PRT" | country=="ROU" | country=="SVK" | country=="SVN" | country=="ESP" | country=="SWE" | country=="CHE" | country=="GBR"
	keep year country industry aut*  bel*  hrv*  cze*  dnk*  fin*  fra*  deu*  hun*  ita*  lva* ltu* mlt* nld*  pol*  prt*  rou*  svk*  svn*  esp*  swe*  che*  gbr*
	order year country industry
	rename *_* value*_*
	reshape long value, i(year country industry) j(partner) string
	replace partner=upper(partner)
	gen country_partner=substr(partner,1,3)
	gen industry_partner=substr(partner,5,.)
	order year country industry country_partner industry_partner
	drop partner
	sort country industry country_partner industry_partner
	save "$data_dr\Export_`y'.dta", replace
	rename country country_n
	rename industry industry_n
	rename *_partner *
	rename *_n *_partner
	order year country industry country_partner industry_partner
	sort country industry country_partner industry_partner
	save "$data_dr\Import_`y'.dta", replace
}

use "$data_dr\Export_2018.dta", clear
replace year=2019
save "$data_dr\Export_2019.dta", replace
replace year=2020
save "$data_dr\Export_2020.dta", replace

use "$data_dr\Import_2018.dta", clear
replace year=2019
save "$data_dr\Import_2019.dta", replace
replace year=2020
save "$data_dr\Import_2020.dta", replace

foreach f in Export Import {
	use "$data_dr\\`f'_2000.dta", clear
forvalues y = 2001/2020 {
	append using "$data_dr\\`f'_`y'.dta"
}
save "$data_dr\\`f'_TOT.dta", replace
}


import delimited "$data_dr\ISIC REV. 4 - NACE REV. 2_20230426_170248.csv", varnames(1) clear
rename isicrev4nacerev2 ISICREV4
rename v2 NACEREV2
drop v3
gen length=length(ISICREV4)
keep if length==2
drop length

foreach c in ISICREV4 NACEREV2{
replace `c'="01T02" if `c'=="01"
replace `c'="05T06" if `c'=="05"
replace `c'="07T08" if `c'=="07"
replace `c'="10T12" if `c'=="10"
replace `c'="13T15" if `c'=="13"
replace `c'="17T18" if `c'=="17"
replace `c'="31T33" if `c'=="31"
replace `c'="36T39" if `c'=="36"
replace `c'="41T43" if `c'=="41"
replace `c'="45T47" if `c'=="45"
replace `c'="55T56" if `c'=="55"
replace `c'="58T60" if `c'=="58"
replace `c'="62T63" if `c'=="62"
replace `c'="64T66" if `c'=="64"
replace `c'="69T75" if `c'=="69"
replace `c'="77T82" if `c'=="77"
replace `c'="86T88" if `c'=="86"
replace `c'="90T93" if `c'=="90"
replace `c'="94T96" if `c'=="94"
replace `c'="97T98" if `c'=="97"
}

rename ISICREV4 industry
save "$data_dr\ISIC_NACE_Conc_i.dta", replace

rename industry industry_partner
save "$data_dr\ISIC_NACE_Conc_j.dta", replace


use "$data_dr\Export_TOT.dta", clear
merge m:1 industry using "$data_dr\ISIC_NACE_Conc_i.dta"
keep if _merge==3
drop _merge
replace industry=NACEREV2
drop NACEREV2

merge m:1 industry_partner using "$data_dr\ISIC_NACE_Conc_j.dta"
keep if _merge==3
drop _merge
replace industry_partner=NACEREV2
drop NACEREV2

sort year country industry country_partner industry_partner

drop if industry == "01T02" | industry == "03" | industry == "05T06" | industry == "07T08" | industry == "09" | industry == "19" | industry == "35" | industry == "36T39" | industry == "64T66" | industry == "84" | industry == "85" | industry == "86T88" | industry == "90T93" | industry == "94T96" | industry == "97T98"

drop if industry_partner == "01T02" | industry_partner == "03" | industry_partner == "05T06" | industry_partner == "07T08" | industry_partner == "09" | industry_partner == "19" | industry_partner == "35" | industry_partner == "36T39" | industry_partner == "64T66" | industry_partner == "84" | industry_partner == "85" | industry_partner == "86T88" | industry_partner == "90T93" | industry_partner == "94T96" | industry_partner == "97T98"

replace industry="1" if industry=="10T12" | industry=="13T15" | industry=="16" | industry=="17T18" | industry=="20" | industry=="21" | industry=="22" | industry=="23" | industry=="24" | industry=="25" | industry=="26" | industry=="27" | industry=="28" | industry=="29" | industry=="30" | industry=="31T33" 
replace industry="2" if industry=="41T43"
replace industry="3" if industry=="45T47"
replace industry="4" if industry=="49" | industry=="50" | industry=="51" | industry=="52" | industry=="53" 
replace industry="5" if industry=="55T56"
replace industry="6" if industry=="58T60" | industry=="61" | industry=="62T63"
replace industry="7" if industry=="68"
replace industry="8" if industry=="69T75"
replace industry="9" if industry=="77T82"

replace industry_partner="1" if industry_partner=="10T12" | industry_partner=="13T15" | industry_partner=="16" | industry_partner=="17T18" | industry_partner=="20" | industry_partner=="21" | industry_partner=="22" | industry_partner=="23" | industry_partner=="24" | industry_partner=="25" | industry_partner=="26" | industry_partner=="27" | industry_partner=="28" | industry_partner=="29" | industry_partner=="30" | industry_partner=="31T33" 
replace industry_partner="2" if industry_partner=="41T43"
replace industry_partner="3" if industry_partner=="45T47"
replace industry_partner="4" if industry_partner=="49" | industry_partner=="50" | industry_partner=="51" | industry_partner=="52" | industry_partner=="53" 
replace industry_partner="5" if industry_partner=="55T56"
replace industry_partner="6" if industry_partner=="58T60" | industry_partner=="61" | industry_partner=="62T63"
replace industry_partner="7" if industry_partner=="68"
replace industry_partner="8" if industry_partner=="69T75"
replace industry_partner="9" if industry_partner=="77T82"

collapse (sum) value, by(year country industry country_partner industry_partner)

destring industry, replace
destring industry_partner, replace

label define seclab 1 "1 - Manufacturing" 2 "2 - Construction" 3 "3 - Wholesale and retail trade" 4 "4 - Transportation and storage" 5 "5 - Accommodation and food service activities" 6 "6 - Information and communication" 7 "7 - Real estate activities" 8 "8 - Professional, scientific and tehnical activities" 9 "9 - Administrative and support service activities"

label values industry seclab
label values industry_partner seclab

rename value export

save "$data_dr\Export_TOT_NACE.dta", replace



use "$data_dr\Import_TOT.dta", clear
merge m:1 industry using "$data_dr\ISIC_NACE_Conc_i.dta"
keep if _merge==3
drop _merge
replace industry=NACEREV2
drop NACEREV2

merge m:1 industry_partner using "$data_dr\ISIC_NACE_Conc_j.dta"
keep if _merge==3
drop _merge
replace industry_partner=NACEREV2
drop NACEREV2

sort year country industry country_partner industry_partner

drop if industry == "01T02" | industry == "03" | industry == "05T06" | industry == "07T08" | industry == "09" | industry == "19" | industry == "35" | industry == "36T39" | industry == "64T66" | industry == "84" | industry == "85" | industry == "86T88" | industry == "90T93" | industry == "94T96" | industry == "97T98"

drop if industry_partner == "01T02" | industry_partner == "03" | industry_partner == "05T06" | industry_partner == "07T08" | industry_partner == "09" | industry_partner == "19" | industry_partner == "35" | industry_partner == "36T39" | industry_partner == "64T66" | industry_partner == "84" | industry_partner == "85" | industry_partner == "86T88" | industry_partner == "90T93" | industry_partner == "94T96" | industry_partner == "97T98"

replace industry="1" if industry=="10T12" | industry=="13T15" | industry=="16" | industry=="17T18" | industry=="20" | industry=="21" | industry=="22" | industry=="23" | industry=="24" | industry=="25" | industry=="26" | industry=="27" | industry=="28" | industry=="29" | industry=="30" | industry=="31T33" 
replace industry="2" if industry=="41T43"
replace industry="3" if industry=="45T47"
replace industry="4" if industry=="49" | industry=="50" | industry=="51" | industry=="52" | industry=="53" 
replace industry="5" if industry=="55T56"
replace industry="6" if industry=="58T60" | industry=="61" | industry=="62T63"
replace industry="7" if industry=="68"
replace industry="8" if industry=="69T75"
replace industry="9" if industry=="77T82"

replace industry_partner="1" if industry_partner=="10T12" | industry_partner=="13T15" | industry_partner=="16" | industry_partner=="17T18" | industry_partner=="20" | industry_partner=="21" | industry_partner=="22" | industry_partner=="23" | industry_partner=="24" | industry_partner=="25" | industry_partner=="26" | industry_partner=="27" | industry_partner=="28" | industry_partner=="29" | industry_partner=="30" | industry_partner=="31T33" 
replace industry_partner="2" if industry_partner=="41T43"
replace industry_partner="3" if industry_partner=="45T47"
replace industry_partner="4" if industry_partner=="49" | industry_partner=="50" | industry_partner=="51" | industry_partner=="52" | industry_partner=="53" 
replace industry_partner="5" if industry_partner=="55T56"
replace industry_partner="6" if industry_partner=="58T60" | industry_partner=="61" | industry_partner=="62T63"
replace industry_partner="7" if industry_partner=="68"
replace industry_partner="8" if industry_partner=="69T75"
replace industry_partner="9" if industry_partner=="77T82"

collapse (sum) value, by(year country industry country_partner industry_partner)

destring industry, replace
destring industry_partner, replace

label define seclab 1 "1 - Manufacturing" 2 "2 - Construction" 3 "3 - Wholesale and retail trade" 4 "4 - Transportation and storage" 5 "5 - Accommodation and food service activities" 6 "6 - Information and communication" 7 "7 - Real estate activities" 8 "8 - Professional, scientific and tehnical activities" 9 "9 - Administrative and support service activities"

label values industry seclab
label values industry_partner seclab

rename value import

save "$data_dr\Import_TOT_NACE.dta", replace


use "$data_dr\Export_TOT_NACE.dta", clear
joinby year country industry country_partner industry_partner using "$data_dr\Import_TOT_NACE.dta", unmatched(both)
drop _merge
gen trade = export+import
replace trade=export if country==country_partner & industry==industry_partner

save "$data_dr\Trade_TOT_NACE.dta", replace

