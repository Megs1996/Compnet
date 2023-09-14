
*** This code plots the figure on HHI trends by dimension in Chapter 6 using data
*** produced in Replication_Conc_Report.do

clear
clear matrix
clear mata
set more off

cd "C:\Users\Marco\Desktop\CompNet 2023\Concentration"

import excel "Replication results\Info_for_figure1.xls", sheet("Sheet1") firstrow clear

twoway (line hhi_rev_eu year, lcolor(edkblue) lwidth(medthick)) (line hhi_rva_pos_eu year, lcolor(cranberry) lwidth(medthick)) (line hhi_rk_eu year, lcolor(dkgreen) lwidth(medthick)) (line hhi_l_eu year, lcolor(gold) lwidth(medthick)) (line hhi_lc_eu year, lcolor(dkorange) lwidth(medthick)) (line hhi_ifa_eu year, yaxis(2) lcolor(gs10) lwidth(medthick)),  graphr(color(white)) plotr(color(white)) subtitle(, bcolor(white) lcolor(black)) xlabel(2010(1)2018,labsize(4)) yla(0(0.04)0.24,labsize(4) angle(0) axis(1)) yla(0.24(0.2)1.24,labsize(4) angle(0) axis(2))  ytitle("", size(1) axis(1)) ytitle("", size(1) axis(2)) legend(on label(1 "Revenues") label(2 "Value Added") label(3 "Capital")label(4 "Employment") label(5 "Labor Cost") label(6 "Intangibles (rhs)") size(4) cols(3) symxsize(*0.5) position(12) order(1 "Revenues" 2 "Value Added" 3 "Capital" 4 "Employment" 5 "Labor Cost" 6 "Intangibles (rhs)") region(lwidth(none)) /*region(lwidth(none))*/) /*yline(0, lpattern() lcolor(grey))*/ xtitle("") title("", size(3)) note("") name(HHIs, replace) 
graph export "HHIs_trends.pdf", as(pdf) replace