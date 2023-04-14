********************************************************
**** Topic 5: SMEs - Cash and financial constraints ****
********************************************************

//Cash: FR01_cash_ta_mn  (cash over total assets, mean)
//Constraints:
	//Financial: FD01_safe_mn 	//Credit: FD00_absconstr_mn


*** Task 1: Regressions (slide 20 in topic 5 presentation) ***
* Housekeeping 
clear all
clear
eststo clear
set more off

* Set directory & open dataset
cd "/Users/Ribeiro/OneDrive/Ignore/Área de Trabalho/CompNet/Firm productivity report/Chpt 5b SMEs" // use your directory here
use "unconditional_macsec_szcl_all_unweighted.dta", clear // make sure this file is in the latter

* Transform information into numeric values
split macsec_szcl, parse(_) destring gen(var) // split this variable in four new variables
drop macsec_szcl var1 var3
rename var2 mac_sector
rename var4 sizeclass
order mac_sector sizeclass, after(year) 

// summary statistcs
tab sizeclass 
tab country 

tab country sizeclass

* Prepare variables
	* Cash
	rename FR01_cash_ta_mn Cash 

	* Financial constraint
	rename FD01_safe_mn Financial_constraint

	* Credit constraint
	rename FD00_absconstr_mn Credit_constraint

* Generate dummies: financially + credit constrained firms of sizeclass 1 and 2 (less than 10 employees, 10-19 employees) 
	* Financial: FD01_safe_mn
	egen Financial_sizeclass_1=group(Financial_constraint sizeclass)  if sizeclass==1 	
	egen Financial_sizeclass_2=group(Financial_constraint sizeclass)  if sizeclass==2

	* Credit: FD00_absconstr_mn 
	egen Credit_sizeclass_1=group(Credit_constraint sizeclass)  if sizeclass==1 	
	egen Credit_sizeclass_2=group(Credit_constraint sizeclass)  if sizeclass==2

* Table
	* Financial constraint
	xi: reg Cash Financial_constraint i.country*i.mac_sector i.year 
	outreg2 using SME_2b.doc, addtext(MacSector-Country FE, YES, Year FE, YES) drop(_I* o.*) word replace

	xi: reg Cash Financial_sizeclass_1 i.country*i.mac_sector i.year 
	outreg2 using SME_2b.doc, addtext(MacSector-Country FE, YES, Year FE, YES) drop(_I* o.*) word append

	xi: reg Cash Financial_sizeclass_2 i.country*i.mac_sector i.year 
	outreg2 using SME_2b.doc, addtext(MacSector-Country FE, YES, Year FE, YES) drop(_I* o.*) word append

	* Credit constraint
	xi: reg Cash Credit_constraint i.country*i.mac_sector i.year 
	outreg2 using SME_2b.doc, addtext(MacSector-Country FE, YES, Year FE, YES) drop(_I* o.*) word append

	xi: reg Cash Credit_sizeclass_1 i.country*i.mac_sector i.year 
	outreg2 using SME_2b.doc, addtext(MacSector-Country FE, YES, Year FE, YES) drop(_I* o.*) word append

	xi: reg Cash Credit_sizeclass_2 i.country*i.mac_sector i.year 
	outreg2 using SME_2b.doc, addtext(MacSector-Country FE, YES, Year FE, YES) drop(_I* o.*) word append
 
***
 
 
*** Task 2: Coefficient plots - cash and financial constraints by firm size (slide 21) ***
* Housekeeping 
clear all
clear
eststo clear
set more off

* Set directory & open dataset
use "unconditional_macsec_szcl_all_unweighted.dta", clear

* Create sizeclasses
split macsec_szcl, parse(_) destring gen(var)
drop macsec_szcl var1 var3
rename var2 mac_sector
rename var4 sizeclass
order mac_sector sizeclass, after(year) 

tab sizeclass

tab country sizeclass

** Coefficient plots
// Cash: FR01_cash_ta_mn
// Financial constraint: FD01_safe_mn
// Credit constraint: FD00_absconstr_mn

* Cash + Financial constraint	- regress and store results to be shown in a coefplot graph (below)
	* All countries, control for mac_sector and year
	capture xi: regress FR01_cash_ta_mn FD01_safe_mn i.mac_sector*i.country i.year
	capture estimates store results_1 
	capture xi: regress FR01_cash_ta_mn FD01_safe_mn i.mac_sector*i.country i.year if sizeclass==1
	capture estimates store results_2
	capture xi: regress FR01_cash_ta_mn FD01_safe_mn i.mac_sector*i.country i.year if sizeclass==2
	capture estimates store results_3
	capture xi: regress FR01_cash_ta_mn FD01_safe_mn i.mac_sector*i.country i.year if sizeclass==3
	capture estimates store results_4
	capture xi: regress FR01_cash_ta_mn FD01_safe_mn i.mac_sector*i.country i.year if sizeclass==4
	capture estimates store results_5
	capture xi: regress FR01_cash_ta_mn FD01_safe_mn i.mac_sector*i.country i.year if sizeclass==5
	capture estimates store results_6

	coefplot (results_1 \ results_2 \ results_3 \ results_4 \ results_5 \ results_6), keep(FD01_safe_mn) ///
	aseq swapnames vertical ///
    coeflabels(results_1 = "All firm sizes" ///
				results_2 = "1-9 employees" ///
                results_3 = "10-19 employees" ///
				results_4 = "20-49 employees" ///
				results_5 = "50-249 employees" ///
				results_6 = "250+ employees" ) ///
	xtitle("Financial constraint by firm size", size(small)) xlabel(, angle(45) labsize(vsmall)) ///
	ytitle("Cash over total assets (mean)", size(small)) ylabel( ,labsize(vsmall)) ///
	title("Cash and financial constraint by firm size", size(medium) color(black)) ///
	graphregion(color(white)) plotregion(color(white)) ///
	note("Controlling for Controlling for Country*Macro-sector and Year FEs", size(vsmall))

graph export SME_2_1a.pdf, as(pdf) replace	//keep the graph window opened when running this line of code. You can change pdf to png if needed, just replace .pdf and pdf in the () by "png"
	
* Cash + Credit constraint	
	* All countries, control for mac_sector and year 
	capture xi: regress FR01_cash_ta_mn FD00_absconstr_mn i.mac_sector*i.country i.year
	capture estimates store results_1 
	capture xi: regress FR01_cash_ta_mn FD00_absconstr_mn i.mac_sector*i.country i.year if sizeclass==1
	capture estimates store results_2
	capture xi: regress FR01_cash_ta_mn FD00_absconstr_mn i.mac_sector*i.country i.year if sizeclass==2
	capture estimates store results_3
	capture xi: regress FR01_cash_ta_mn FD00_absconstr_mn i.mac_sector*i.country i.year if sizeclass==3
	capture estimates store results_4
	capture xi: regress FR01_cash_ta_mn FD00_absconstr_mn i.mac_sector*i.country i.year if sizeclass==4
	capture estimates store results_5
	capture xi: regress FR01_cash_ta_mn FD00_absconstr_mn i.mac_sector*i.country i.year if sizeclass==5
	capture estimates store results_6
	
	coefplot (results_1 \ results_2 \ results_3 \ results_4 \ results_5 \ results_6), keep(FD00_absconstr_mn) ///
	aseq swapnames vertical ///
    coeflabels(results_1 = "All firm sizes" ///
				results_2 = "1-9 employees" ///
                results_3 = "10-19 employees" ///
				results_4 = "20-49 employees" ///
				results_5 = "50-249 employees" ///
				results_6 = "250+ employees" ) ///
	xtitle("Credit constraint by firm size", size(small)) xlabel(, angle(45) labsize(vsmall)) ///
	ytitle("Cash over total assets (mean)", size(small)) ylabel( ,labsize(vsmall)) ///
	title("Cash and credit constraint by firm size", size(medium) color(black)) ///
	graphregion(color(white)) plotregion(color(white)) ///
	note("Controlling for Country*Macro-sector and Year FEs", size(vsmall))

graph export SME_2_2a.pdf, as(pdf) replace	

***


*** Task 3: Coefficient plots - cash and financial constraints by firm size per macro-sector (Appendix slide 42) 
* Housekeeping 
clear all
clear
eststo clear
set more off

* Set directory & open dataset
use "unconditional_macsec_szcl_all_unweighted.dta", clear

* Create sizeclasses
split macsec_szcl, parse(_) destring gen(var)
drop macsec_szcl var1 var3
rename var2 mac_sector
rename var4 sizeclass
order mac_sector sizeclass, after(year) 

tab sizeclass

tab country sizeclass

** Coefficient plots
// Cash: FR01_cash_ta_mn
// Financial constraint: FD01_safe_mn
// Credit constraint: FD00_absconstr_mn

// in case of error ("results_1 not found"), run the below block of code again

* Cash + Financial constraint	
	* Per macro-sector, controlling for country and year
	levelsof mac_sector, local(newvariablename)
		foreach x in `newvariablename' {
	capture xi: regress FR01_cash_ta_mn FD01_safe_mn i.country i.year & mac_sector== `x'
	capture estimates store results_1 
	xi: regress FR01_cash_ta_mn FD01_safe_mn i.country i.year if sizeclass==1 & mac_sector== `x'
	capture estimates store results_2
	capture xi: regress FR01_cash_ta_mn FD01_safe_mn i.country i.year if sizeclass==2 & mac_sector== `x'
	capture estimates store results_3
	capture xi: regress FR01_cash_ta_mn FD01_safe_mn i.country i.year if sizeclass==3 & mac_sector== `x'
	capture estimates store results_4
	capture xi: regress FR01_cash_ta_mn FD01_safe_mn i.country i.year if sizeclass==4 & mac_sector== `x'
	capture estimates store results_5
	capture xi: regress FR01_cash_ta_mn FD01_safe_mn i.country i.year if sizeclass==5 & mac_sector== `x'
	capture estimates store results_6 
	
	coefplot (results_1 \ results_2 \ results_3 \ results_4 \ results_5 \ results_6), keep(FD01_safe_mn) ///
	aseq swapnames vertical ///
    coeflabels(results_1 = "All" ///
				results_2 = "1-9" ///
                results_3 = "10-19" ///
				results_4 = "20-49" ///
				results_5 = "50-249" ///
				results_6 = "250+" ) ///
	xtitle("", size(vsmall)) xlabel(, labsize(vsmall)) ///
	ytitle("Cash over total assets (mean)", size(vsmall)) ylabel( ,labsize(vsmall)) ///
	subtitle(`x', size(small) color(black)) ///
	graphregion(color(white)) plotregion(color(white)) ///
	saving(SME_1_1b_`x'.gph, replace)
	}
	
	graph combine SME_1_1b_1.gph SME_1_1b_2.gph SME_1_1b_3.gph SME_1_1b_4.gph SME_1_1b_5.gph ///
		SME_1_1b_6.gph SME_1_1b_7.gph SME_1_1b_8.gph SME_1_1b_9.gph, ///
		title("Cash and financial constraint by firm size per macro-sector", size(medium) color(black)) ///
		note("Controlling for Country and Year FEs", size(vsmall)) ///
		graphregion(color(white)) plotregion(color(white))
		graph export SME_1_1b.png, as(png) replace	
	
* Cash + Credit constraint	
	* Per macro-sector, controlling for country and year
	levelsof mac_sector, local(newvariablename)
		foreach x in `newvariablename' {
	capture xi: regress FR01_cash_ta_mn FD00_absconstr_mn i.country i.year & mac_sector== `x'
	capture estimates store results_1 
	xi: regress FR01_cash_ta_mn FD00_absconstr_mn i.country i.year if sizeclass==1 & mac_sector== `x'
	capture estimates store results_2
	capture xi: regress FR01_cash_ta_mn FD00_absconstr_mn i.country i.year if sizeclass==2 & mac_sector== `x'
	capture estimates store results_3
	capture xi: regress FR01_cash_ta_mn FD00_absconstr_mn i.country i.year if sizeclass==3 & mac_sector== `x'
	capture estimates store results_4
	capture xi: regress FR01_cash_ta_mn FD00_absconstr_mn i.country i.year if sizeclass==4 & mac_sector== `x'
	capture estimates store results_5
	capture xi: regress FR01_cash_ta_mn FD00_absconstr_mn i.country i.year if sizeclass==5 & mac_sector== `x'
	capture estimates store results_6 
	
	coefplot (results_1 \ results_2 \ results_3 \ results_4 \ results_5 \ results_6), keep(FD00_absconstr_mn) ///
	aseq swapnames vertical ///
    coeflabels(results_1 = "All" ///
				results_2 = "1-9" ///
                results_3 = "10-19" ///
				results_4 = "20-49" ///
				results_5 = "50-249" ///
				results_6 = "250+" ) ///
	xtitle("", size(vsmall)) xlabel(, labsize(vsmall)) ///
	ytitle("Cash over total assets (mean)", size(vsmall)) ylabel( ,labsize(vsmall)) ///
	subtitle(`x', size(small) color(black)) ///
	graphregion(color(white)) plotregion(color(white)) ///
	saving(SME_1_2b_`x'.gph, replace)
	}
	
	graph combine SME_1_2b_1.gph SME_1_2b_2.gph SME_1_2b_3.gph SME_1_2b_4.gph SME_1_2b_5.gph ///
		SME_1_2b_6.gph SME_1_2b_7.gph SME_1_2b_8.gph SME_1_2b_9.gph, ///
		title("Cash and credit constraint by firm size per macro-sector", size(medium) color(black)) ///
		note("Controlling for Country and Year FEs", size(vsmall)) ///
		graphregion(color(white)) plotregion(color(white))
		graph export SME_1_2b.png, as(png) replace


 