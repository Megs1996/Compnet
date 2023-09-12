** Clarifying notes
* Dataset(s) used: op_decomp_industry2d_20e_weighted sample, unconditional_industry2d_20e_weighted, 9th vintage
	

clear all
set more off

* Set output directory
global savepath "...\Replication-Packages\Topic1_Productivity\productivity_trends"

*Choose Compnet sample
global sample "20e"

*Weighted or unweighted version 
global weight "weighted" 

* Set data directory 
global data ".../${sample}_firms_${weight}/Descriptives/"


*----------------------------------*
* FIGURE: WITHIN-SECTOR GROWTH *
*----------------------------------*

{
eststo clear 
use  "${data}\op_decomp_industry2d_${sample}_${weight}.dta" , clear 

drop if year <=2000 | year > 2020
encode country, gen(cn)

label define lyear 2000 "2000" 2001 "2001" 2002 "2002" 2003 "2003" 2004 "2004" ///
2005 "2005" 2006 "2006" 2007 "2007" 2008 "2008" 2009 "2009" 2010 "2010" 2011 "2011" ///
2012 "2012" 2013 "2013" 2014 "2014" 2015 "2015" 2016 "2016" 2017 "2017" 2018 "2018" ///
2019 "2019" 2020 "2020"
label value year lyear

*** TFP ***
gen ln_tfp = ln(PEb1_tfp_1_Wrrv_wmn) //original code: PE99_tfp_rcd_ols_S_Wrrv_wmn 

* Margins = Predicted TFP Growth
keep if weight_type == "standard" // original code error in xtset cs year : repeated time values within panel reason 9th vintage has several weight_type, keep only one. There are still missing tfps in standard, ideal would be to take a weight type which generates a non-empty tfp

egen cs = group(country industry2d) // original code:  sector
xtset cs year 


gen D_ln_tfp = D.ln_tfp*100
reg D_ln_tfp i.year i.industry2d i.cn, cluster(industry2d)
eststo tfp_EU: margin year, post
marginsplot, graphr(color(white)) plotr(color(white)) recast(line) ciopt(color(%20)) recastci(rarea) ///
	subtitle(, bcolor(white) lcolor(black)) xlabel(2000(5)2020,labsize(3)) yla(,labsize(3) angle(0)) ytitle(" ") /// original code: 2015 instead of 2020
	legend(on label(1 "95% CI") label(2 "Mean") size(4)) ///
	yline(0, lpattern(dash) lcolor(grey)) ///
	xtitle("") title("EUROPE") saving(tfp_EUROPE, replace)	


* separately for each country to calculate country deviation
replace country="CzechRepublic" if country=="Czech Republic"
levelsof country
foreach cn in `r(levels)'{
	reg D_ln_tfp i.year i.industry2d if country == "`cn'", cluster(industry2d)
	eststo tfp_`cn': margin year, post
}

* store estimates in a csv to be read-in below
esttab tfp_EU tfp_Belgium tfp_Croatia tfp_CzechRepublic tfp_Denmark tfp_Finland tfp_France tfp_Italy tfp_Lithuania tfp_Poland tfp_Slovakia tfp_Slovenia tfp_Spain tfp_Sweden tfp_Switzerland  using "${savepath}\margins_prod_growth.csv", replace plain mtitles nostar noobs not label

import delimited "$savepath\margins_prod_growth.csv", clear varnames(1)
drop if v1 == . 
rename v1 year
keep if year>=2009

ds
foreach var in `r(varlist)' {
	destring `var', replace
}

local countries "tfp_belgium tfp_croatia tfp_czechrepublic tfp_denmark tfp_eu tfp_finland tfp_france tfp_italy tfp_lithuania tfp_poland tfp_slovakia tfp_slovenia tfp_spain tfp_sweden tfp_switzerland"
foreach x in `countries' {
rename  `x' `x', upper
}
rename TFP_EU tfpgr_EU

xtset  year
reshape long  TFP_  , i(year) j(country,string)
rename TFP_ TFP_gr
*bys country year: gen dev_lprod= lprod_gr-lprodgr_EU if lprod_gr!=.
bys country year: gen dev_TFP= TFP_gr-tfpgr_EU if TFP_gr!=.

graph hbar dev_TFP, over(country, sort(dev_TFP dev_lprod) descending label(labsize(3) angle(0))) graphr(color(white)) plotr(color(white)) subtitle(, bcolor(white) lcolor(black)) ///
	 ytitle(" ", size(.5)) title("DEVIATION PER COUNTRY", size(4)) legend(on label(1 "deviation from European average")span size(4)) ylabel(,labs(3)) saving(TFPgr_deviation_country, replace) name(TFPgr_deviation_country,replace)


* Figure
graph combine "tfp_Europe.gph" "TFPgr_deviation_country.gph", cols(2) graphr(color(white)) plotr(color(white))
graph export "${savepath}\TFPGr_Europe.png", replace


erase "$savepath\margins_prod_growth.csv"
erase "$savepath\tfp_Europe.gph"
erase "$savepath\TFPgr_deviation_country.gph"

}

*-------------------------------------*
* FIGURE: PRODUCTIVITY DISPERSION *
*-------------------------------------*


{
eststo clear

use country year industry2d *tfp* *lprod* FV13* FV14*  using "${data}\unconditional_industry2d_20e_weighted.dta" , clear

// instead of rename throughout the dofile sector to industry2d, change industry2d to sector
rename industry2d sector

egen cs = group(country sector)
xtset cs year

gen prod_disp = PEj0_ln_tfp_1_p90 - PEj0_ln_tfp_1_p10 

replace country = "CZECH_REPUBLIC" if country == "CZECH REPUBLIC"
encode country, gen(cn)
drop if year<2000
label define years  2000 "2000" 2001 "2001" 2002 "2002" 2003 "2003" 2004 "2004" 2005 "2005" 2006 "2006" 2007 "2007" 2008 "2008" 2009 "2009" 2010 "2010" 2011 "2011" 2012 "2012" 2013 "2013" 2014 "2014" 2015 "2015" 2016 "2016" 2017 "2017" 2018 "2018" 2019 "2019" 2020 "2020" 2021 "2021"
label values year years
	
* productivity dispersion over time
reg prod_disp i.year i.sector i.cn, cluster(sector)
eststo EU: margin year, post

marginsplot, graphr(color(white)) plotr(color(white)) recast(line) ciopt(color(%20)) recastci(rarea) ///
	subtitle(, bcolor(white) lcolor(black)) xlabel(2000(5)2020,labsize(3)) yla(,labsize(3) angle(0)) ytitle(" ") /// 
	ylabel(.5(.05).75) ///
	legend(on label(1 "95% CI") label(2 "Mean") span size(4)) ///
	xtitle("") title("EUROPE") 
graph export "${savepath}\prod_dispersion_Europe.png", replace
}
