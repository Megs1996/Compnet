/*

Regressions direttamente su data w/ PC


*/

global compnet_data "C:\Users\a_zon\Dropbox\PHD VU\6_Energy\Energy regressions"
global cd "C:\Users\a_zon\Dropbox\PHD VU\6_Energy\Energy regressions"
cd "$cd"
global outdir "${compnet_data}/reg_tables/2nd_draft"

clear all

global compnet_data "/Users/lauralehtonen/Desktop/CompNet/Compnet Data/9th vintage/Data files"
global cd "/Users/lauralehtonen/Desktop/CompNet/Compnet Data/Energy research"
cd "$cd"
global outdir "${compnet_data}/reg"


use data_afterPCA, clear
xtset ID year

egen num_firms_weights = mean(LV21_l_sw), by(ID)

label define macrosectors 1  "Manufacturing  " 2 "Construction  " 3 "Wholesale and retail trade  " 4 "Transportation and storage " 5 "Accommodation and food service activities  " 6 "Information and communication  " 7 "Real estate activities  " 8 "Professional, scientific and technical activities  " 9 "Administrative and support service activities  "
label values mac_sector macrosectors

gen fullsample = (industry2d==10 | industry2d==13 | industry2d==14 | industry2d==17 | industry2d==18  | industry2d==20 | industry2d==22 ///
| industry2d==23 | industry2d==24 | industry2d==25 | industry2d==26 | industry2d==27 | industry2d==28  | industry2d==29 ///
| industry2d==30 | industry2d==31 | industry2d==32 | industry2d==33 | industry2d==42 | industry2d==45 | industry2d==46 ///
| industry2d==47 | industry2d==49 | industry2d==50 | industry2d==52 | industry2d==55 | industry2d==56 | industry2d==58 ///
| industry2d==60 | industry2d==61 | industry2d==70 | industry2d==78 | industry2d==80 | industry2d==81 | industry2d==82)

gen robustsample = (industry2d==10 | industry2d==13 | industry2d==18 | industry2d==22 | industry2d==25 | industry2d==26 ///
| industry2d==27 | industry2d==28 | industry2d==31 | industry2d==42 | industry2d==45 | industry2d==46 | industry2d==47 ///
| industry2d==49 | industry2d==55 | industry2d==78 | industry2d==80 | industry2d==81)

* little test on missing values by variables

tab country if w_Dp_PC1 != . & w_Dp_PC2 != . & w_Dp_PC3 != .
foreach v of varlist LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn{
	
	di "`v'"
	tab country if w_Dp_PC1 != . & w_Dp_PC2 != . & w_Dp_PC3 != . & `v' !=.
	
}


// -----------------------------------------------------------------------  //

* 1) Baseline results
{


*All 
local prices_at w_Dp_PC1 w_Dp_PC2 w_Dp_PC3
		
*Profitability
xtreg d_FR22_profitmargin_mn `prices_at' i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if FR22_profitmargin_mn > -5 & fullsample [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at.xls", replace dec(3) addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") ctitle("Profitability") addtext(Year FE, YES) excel drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)

*drop( LV21_l_mn FV08_nrev_mn CE44_markup_0_mn  FR22_profitmargin_mn i.year FR40_ener_costs_mn)

*Job destruction rate
xtreg LV15_jdr_pop_2D_tot `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if fullsample [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at.xls", append dec(3) ctitle("Job Destruction Rate")  addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)

*Energy cost share
xtreg d_FR40_ener_costs_mn `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if fullsample [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at.xls", append dec(3) ctitle("Ener. Cost Share")  addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)

*Energy efficiency
xtreg d_ener_eff `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if fullsample [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at.xls", append dec(3) ctitle("Energy / VA") addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)

*Export intensity
xtreg d_TR02_exp_adj_rev_mn `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if fullsample [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at.xls", append dec(3) ctitle("Export Share") addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)

*Investment
xtreg d_FR37_invest_k_mn `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if fullsample [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at.xls", append dec(3) ctitle("Invest. over Asset") addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)

*Green share
xtreg d_green_sh `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if fullsample [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at.xls", append dec(3) ctitle("Green Share") addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)

}

// -------------------------------------------------------------------------- //


* 1b) Focus on only positive shocks
{

label define price_shocks 0 "decrease" 1 "increase"

forvalues i = 1/3 {
	
	cap drop price_incr_PC`i'
	g price_incr_PC`i' = 0
	replace price_incr_PC`i' = 1 if w_Dp_PC`i' >= 0
	label values price_incr_PC`i' price_shocks
	
}
	
*All 
local prices_at c.w_Dp_PC1#price_incr_PC1 c.w_Dp_PC2#price_incr_PC2 c.w_Dp_PC3#price_incr_PC3

*Profitability
xtreg d_FR22_profitmargin_mn `prices_at' i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if FR22_profitmargin_mn > -5 & fullsample [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_positive.xls", replace dec(3) ctitle("Profitability") addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)

*drop( LV21_l_mn FV08_nrev_mn CE44_markup_0_mn  FR22_profitmargin_mn i.year FR40_ener_costs_mn)

*Job destruction rate
xtreg LV15_jdr_pop_2D_tot `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if fullsample [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_positive.xls", append dec(3) ctitle("Job Destruction Rate")  addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)

*Energy cost share
xtreg d_FR40_ener_costs_mn `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if fullsample [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_positive.xls", append dec(3) ctitle("Ener. Cost Share")  addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)

*Energy efficiency
xtreg d_ener_eff `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if fullsample [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_positive.xls", append dec(3) ctitle("Energy / VA")  addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)

*Export intensity
xtreg d_TR02_exp_adj_rev_mn `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if fullsample [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_positive.xls", append dec(3) ctitle("Export Share")  addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)

*Investment
xtreg d_FR37_invest_k_mn `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if fullsample [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_positive.xls", append dec(3) ctitle("Invest. Over Asset")  addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)

*Green share
xtreg d_green_sh `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if fullsample [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_positive.xls", append dec(3) ctitle("Green Share")  addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn) 		

}

// -------------------------------------------------------------------------- //

* 2a) Dependent variables by country
{
	
*Profitability by country
*DE, LT, PL, SK, SL, DK, FI, PT

levelsof country, local(newvariablename)
local i = 1
		foreach x in `newvariablename' { 

local prices_at w_Dp_PC1 w_Dp_PC2 w_Dp_PC3
		
if `i' == 1 {
	local exp replace
}
else {
	local exp append
}

capture xtreg d_FR22_profitmargin_mn `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if FR22_profitmargin_mn > -5 & fullsample & country=="`x'" [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_profitability.xls", `exp' dec(3) title("Profitability") ctitle("`x'") addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)
local i `i' + 1

}


*Job destruction rate by country
*DE, LT, PL, SK, SL, DK, FI, PT

levelsof country, local(newvariablename)
local i = 1
		foreach x in `newvariablename' { 

local prices_at w_Dp_PC1 w_Dp_PC2 w_Dp_PC3

if `i' == 1 {
	local exp replace
}
else {
	local exp append
}
		
capture xtreg LV15_jdr_pop_2D_tot `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if fullsample & country=="`x'" [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_jdr.xls", `exp' dec(3) title("Job destruction rate") ctitle("`x'") addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)
local i `i' + 1

}


*Energy cost share by country
*DE, LT, PL, SK, SL, DK, FI, PT

levelsof country, local(newvariablename)
local i = 1
		foreach x in `newvariablename' { 

local prices_at w_Dp_PC1 w_Dp_PC2 w_Dp_PC3

if `i' == 1 {
	local exp replace
}
else {
	local exp append
}
		
capture xtreg d_FR40_ener_costs_mn `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if fullsample & country=="`x'" [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_energycost.xls", `exp' dec(3) title("Energy cost share") ctitle("`x'") addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)
local i `i' + 1

}



*Energy efficiency share by country
*DE, LT, PL, SK, SL, DK, FI, PT

levelsof country, local(newvariablename)
local i = 1
		foreach x in `newvariablename' { 

local prices_at w_Dp_PC1 w_Dp_PC2 w_Dp_PC3

if `i' == 1 {
	local exp replace
}
else {
	local exp append
}
		
capture xtreg d_ener_eff `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if fullsample & country=="`x'" [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_energyefficiency.xls", `exp' dec(3) title("Energy efficiency") ctitle("`x'") addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)
local i `i' + 1

}

}

// -------------------------------------------------------------------------- //

* 2b) Industry vs the rest
{
	
cap drop IND
g IND = "Services"
replace IND = "Manuf & Constr" if mac_sector == 1 | mac_sector == 2

*Profitability by industry

local prices_at w_Dp_PC1 w_Dp_PC2 w_Dp_PC3
		
capture xtreg d_FR22_profitmargin_mn `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if FR22_profitmargin_mn > -5 & fullsample & IND=="Manuf & Constr" [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_ind.xls", replace dec(3)  ctitle("Profitability", "Manuf & Constr")  addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)

capture xtreg d_FR22_profitmargin_mn `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if FR22_profitmargin_mn > -5 & fullsample & IND=="Services" [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_ind.xls", append dec(3)  ctitle(" ", "Services")  addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)

*Job destruction rate by industry
capture xtreg LV15_jdr_pop_2D_tot `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if FR22_profitmargin_mn > -5 & fullsample & IND=="Manuf & Constr" [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_ind.xls", append dec(3)  ctitle("Job Destruction Rate", "Manuf & Constr")  addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)

capture xtreg LV15_jdr_pop_2D_tot `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if FR22_profitmargin_mn > -5 & fullsample & IND=="Services" [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_ind.xls", append dec(3)  ctitle(" ", "Services")  addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)


*Energy cost share by industry
capture xtreg d_FR40_ener_costs_mn `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if FR22_profitmargin_mn > -5 & fullsample & IND=="Manuf & Constr" [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_ind.xls", append dec(3)  ctitle("Energy Cost Share", "Manuf & Constr")  addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)

capture xtreg d_FR40_ener_costs_mn `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if FR22_profitmargin_mn > -5 & fullsample & IND=="Services" [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_ind.xls", append dec(3)  ctitle(" ", "Services")  addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)


*Energy efficiency share by industry
capture xtreg d_ener_eff `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if FR22_profitmargin_mn > -5 & fullsample & IND=="Manuf & Constr" [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_ind.xls", append dec(3)  ctitle("Energy Efficiency", "Manuf & Constr")  addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)

capture xtreg d_ener_eff `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if FR22_profitmargin_mn > -5 & fullsample & IND=="Services" [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_ind.xls", append dec(3)  ctitle(" ", "Services")  addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)

}

// -------------------------------------------------------------------------- //

* 3a) Impact on dispersion
{

local depvars2diff_disp  FR22_profitmargin FR40_ener_costs 
foreach v of loc depvars2diff_disp {
	
	* SD
	cap drop d_`v'_sd
	g d_`v'_sd = D.`v'_sd
	
	* p90-p10
	cap drop `v'_p90_p10 d_`v'_p90_p10
	g `v'_p90_p10 = `v'_p90 - `v'_p10
	g d_`v'_p90_p10 = D.`v'_p90_p10
	
	* p75 - p25
	cap drop `v'_p75_p25 d_`v'_p75_p25
	g `v'_p75_p25 = `v'_p75 - `v'_p25
	g d_`v'_p75_p25 = D.`v'_p75_p25
	
}

	
local prices_at w_Dp_PC1 w_Dp_PC2 w_Dp_PC3
	
* SD	
*Profitability
xtreg d_FR22_profitmargin_sd `prices_at' i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if FR22_profitmargin_mn > -5 & fullsample [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_disp.xls", replace dec(3)  ctitle("SD", "Profitability") addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)

*Energy cost share
xtreg d_FR40_ener_costs_sd `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if fullsample [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_disp.xls", append dec(3)  ctitle(" ", "Ener. Cost Share")  addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)

* p90-p10	
*Profitability
xtreg d_FR22_profitmargin_p90_p10 `prices_at' i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if FR22_profitmargin_mn > -5 & fullsample [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_disp.xls", append dec(3)  ctitle("p90-p10", "Profitability") addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)

*Energy cost share
xtreg d_FR40_ener_costs_p90_p10 `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if fullsample [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_disp.xls", append dec(3)  ctitle(" ", "Ener. Cost Share")  addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)

* p75-p25	
*Profitability
xtreg d_FR22_profitmargin_p75_p25 `prices_at' i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if FR22_profitmargin_mn > -5 & fullsample [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_disp.xls", append dec(3)  ctitle("p75-p25", "Profitability") addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.")drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)

*Energy cost share
xtreg d_FR40_ener_costs_p75_p25 `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if fullsample [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_disp.xls", append dec(3)  ctitle(" ", "Ener. Cost Share")  addtext(Year FE, YES) excel addnote("Clustered std. errors at the country-industry level. Omitted coefficients for control variables: profitability, revenues, firm size (employment), number of firms, energy intensity, average markup on intermediate inputs.") drop(i.year LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn)

	
}

// -------------------------------------------------------------------------- //

* 3b) Firm characteristics
{

* Keep only relevant variables & merge with JD

preserve 
keep country year industry2d w_Dp_PC1 w_Dp_PC2 w_Dp_PC3
	
merge 1:m country year industry2d using "${compnet_data}/jd_inp_ene_industry2d_20e_weighted.dta" 
keep if _merge == 3
keep if by_var == "LV21_l" | by_var == "PV03_lnlprod_va" | by_var == "FR30_rk_l"	
	
* adjust indexing & generate additional indicators
	
egen ID = group(country industry2d by_var by_var_value)
xtset ID year

g d_FR40_ener_costs_mn = D.FR40_ener_costs_mn
egen quintile = group(by_var_value)
egen num_firms_weights = mean(LV21_l_sw), by(ID)
gen fullsample = (industry2d==10 | industry2d==13 | industry2d==14 | industry2d==17 | industry2d==18  | industry2d==20 | industry2d==22 ///
| industry2d==23 | industry2d==24 | industry2d==25 | industry2d==26 | industry2d==27 | industry2d==28  | industry2d==29 ///
| industry2d==30 | industry2d==31 | industry2d==32 | industry2d==33 | industry2d==42 | industry2d==45 | industry2d==46 ///
| industry2d==47 | industry2d==49 | industry2d==50 | industry2d==52 | industry2d==55 | industry2d==56 | industry2d==58 ///
| industry2d==60 | industry2d==61 | industry2d==70 | industry2d==78 | industry2d==80 | industry2d==81 | industry2d==82)

gen robustsample = (industry2d==10 | industry2d==13 | industry2d==18 | industry2d==22 | industry2d==25 | industry2d==26 ///
| industry2d==27 | industry2d==28 | industry2d==31 | industry2d==42 | industry2d==45 | industry2d==46 | industry2d==47 ///
| industry2d==49 | industry2d==55 | industry2d==78 | industry2d==80 | industry2d==81)


* regression	

label var w_Dp_PC1 "Fossil Fuels"
label var w_Dp_PC2 "Electricity"
label var w_Dp_PC3 "Natural Gas"

local prices_at c.w_Dp_PC1#quintile c.w_Dp_PC2#quintile c.w_Dp_PC3#quintile
xtreg d_FR40_ener_costs_mn `prices_at' i.year LV21_l_mn FV17_rrev_mn if by_var == "LV21_l" & fullsample & FR40_ener_costs_N >= 15 [pweight = num_firms_weights], fe cluster(ID)
margins quintile, dydx(w_Dp_PC2)
marginsplot, title("Size", color(black)) xtitle("Size quintile")  ytitle("") graphregion(color(white)) //yscale(r(-0.005 0.03)) 
graph save g1, replace
outreg2 using "${outdir}/energ_cost_cond.xls", replace dec(3) addnote("Clustered std. errors at the country-industry level.") ctitle("Size quintiles") drop(i.year) addtext(Year FE, YES) excel 
xtreg d_FR40_ener_costs_mn `prices_at' i.year LV21_l_mn FV17_rrev_mn if by_var == "PV03_lnlprod_va" & fullsample & PV03_lnlprod_va_N >= 15 [pweight = num_firms_weights], fe cluster(ID)
margins quintile, dydx(w_Dp_PC2)
marginsplot, title("Productivity", color(black)) xtitle("Productivity (VA/worker) quintile") ytitle("") graphregion(color(white)) //yscale(r(-0.005 0.03))
graph save g2, replace

outreg2 using "${outdir}/energ_cost_cond.xls", append dec(3) addnote("Clustered std. errors at the country-industry level.") ctitle("Productivity quintiles") drop(i.year) addtext(Year FE, YES) excel 

xtreg d_FR40_ener_costs_mn `prices_at' i.year LV21_l_mn FV17_rrev_mn if by_var == "FR30_rk_l" & fullsample & PV03_lnlprod_va_N >= 15 [pweight = num_firms_weights], fe cluster(ID)
margins quintile, dydx(w_Dp_PC2)
marginsplot, title("Capital intensity", color(black)) xtitle("Capital intensity quintile") ytitle("") graphregion(color(white)) //yscale(r(-0.005 0.03)) ylabel(0 .01 .02 .03)
graph save g3, replace
outreg2 using "${outdir}/energ_cost_cond.xls", append dec(3) addnote("Clustered std. errors at the country-industry level.") ctitle("Capital intensity quintiles") drop(i.year) addtext(Year FE, YES) excel 

graph combine "g1" "g2" "g3", col(3)  graphregion(color(white)) ycommon // title("Price Shock on Energy Cost Share, by Firm Characteristics")
graph export "${outdir}/marginsplot_PC2.pdf", replace

restore

}

// -------------------------------------------------------------------------- //





******** Not super successful stuff in this braket *****************************
{
	

**Dependent variables by country - positive vs negative shocks
{
	
*Profitability by country
levelsof country, local(newvariablename)
		foreach x in `newvariablename' { 

local prices_at c.w_Dp_PC1#price_incr_PC1 c.w_Dp_PC2#price_incr_PC2 c.w_Dp_PC3#price_incr_PC3
		
capture xtreg d_FR22_profitmargin_mn `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if FR22_profitmargin_mn > -5 & fullsample & country=="`x'" [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_profitability_positive.xls", append dec(3) addnote("Clustered std. errors at the country-industry level.") title("Profitability") ctitle("`x'") drop(i.year) addtext(Year FE, YES) excel 

}


*Job destruction rate by country
levelsof country, local(newvariablename)
		foreach x in `newvariablename' { 

local prices_at c.w_Dp_PC1#price_incr_PC1 c.w_Dp_PC2#price_incr_PC2 c.w_Dp_PC3#price_incr_PC3
		
capture xtreg LV15_jdr_pop_2D_tot `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if fullsample & country=="`x'" [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_jdr_positive.xls", append dec(3) addnote("Clustered std. errors at the country-industry level.") title("Job destruction rate") ctitle("`x'") drop(i.year) addtext(Year FE, YES) excel 

}


*Energy cost share by country
levelsof country, local(newvariablename)
		foreach x in `newvariablename' { 

local prices_at c.w_Dp_PC1#price_incr_PC1 c.w_Dp_PC2#price_incr_PC2 c.w_Dp_PC3#price_incr_PC3
		
capture xtreg d_FR40_ener_costs_mn `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if fullsample & country=="`x'" [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_energycost_positive.xls", append dec(3) addnote("Clustered std. errors at the country-industry level.") title("Energy cost share") ctitle("`x'") drop(i.year) addtext(Year FE, YES) excel 

}


*Energy efficiency share by country
levelsof country, local(newvariablename)
		foreach x in `newvariablename' { 

local prices_at c.w_Dp_PC1#price_incr_PC1 c.w_Dp_PC2#price_incr_PC2 c.w_Dp_PC3#price_incr_PC3
		
capture xtreg d_ener_eff `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if fullsample & country=="`x'" [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_energyefficiency_positive.xls", append dec(3) addnote("Clustered std. errors at the country-industry level.") title("Energy efficiency") ctitle("`x'") drop(i.year) addtext(Year FE, YES) excel 

}


}

// -------------------------------------------------------------------------- //


* Industry vs the rest - positive vs negative shocks
{
	
cap drop IND
g IND = "Services"
replace IND = "Manuf & Constr" if mac_sector == 1 | mac_sector == 2

*Profitability by industry

local prices_at c.w_Dp_PC1#price_incr_PC1 c.w_Dp_PC2#price_incr_PC2 c.w_Dp_PC3#price_incr_PC3
		
capture xtreg d_FR22_profitmargin_mn `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if FR22_profitmargin_mn > -5 & fullsample & IND=="Manuf & Constr" [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_ind_positive.xls", replace dec(3) addnote("Clustered std. errors at the country-industry level.") ctitle("Profitability", "Manuf & Constr") drop(i.year) addtext(Year FE, YES) excel 

capture xtreg d_FR22_profitmargin_mn `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if FR22_profitmargin_mn > -5 & fullsample & IND=="Services" [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_ind_positive.xls", append dec(3) addnote("Clustered std. errors at the country-industry level.") ctitle(" ", "Services") drop(i.year) addtext(Year FE, YES) excel 

*Job destruction rate by industry
capture xtreg LV15_jdr_pop_2D_tot `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if FR22_profitmargin_mn > -5 & fullsample & IND=="Manuf & Constr" [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_ind_positive.xls", append dec(3) addnote("Clustered std. errors at the country-industry level.") ctitle("Job Destruction Rate", "Manuf & Constr") drop(i.year) addtext(Year FE, YES) excel 

capture xtreg LV15_jdr_pop_2D_tot `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if FR22_profitmargin_mn > -5 & fullsample & IND=="Services" [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_ind_positive.xls", append dec(3) addnote("Clustered std. errors at the country-industry level.") ctitle(" ", "Services") drop(i.year) addtext(Year FE, YES) excel 


*Energy cost share by industry
capture xtreg d_FR40_ener_costs_mn `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if FR22_profitmargin_mn > -5 & fullsample & IND=="Manuf & Constr" [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_ind_positive.xls", append dec(3) addnote("Clustered std. errors at the country-industry level.") ctitle("Energy Cost Share", "Manuf & Constr") drop(i.year) addtext(Year FE, YES) excel 

capture xtreg d_FR40_ener_costs_mn `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if FR22_profitmargin_mn > -5 & fullsample & IND=="Services" [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_ind_positive.xls", append dec(3) addnote("Clustered std. errors at the country-industry level.") ctitle(" ", "Services") drop(i.year) addtext(Year FE, YES) excel 


*Energy efficiency share by industry
capture xtreg d_ener_eff `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if FR22_profitmargin_mn > -5 & fullsample & IND=="Manuf & Constr" [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_ind_positive.xls", append dec(3) addnote("Clustered std. errors at the country-industry level.") ctitle("Energy Efficiency", "Manuf & Constr") drop(i.year) addtext(Year FE, YES) excel 

capture xtreg d_ener_eff `prices_at' i.year   LV21_l_mn FV08_nrev_mn FR22_profitmargin_mn CE44_markup_0_mn FR40_ener_costs_mn if FR22_profitmargin_mn > -5 & fullsample & IND=="Services" [pweight = num_firms_weights], fe cluster(ID)
outreg2 using "${outdir}/all_at_ind_positive.xls", append dec(3) addnote("Clustered std. errors at the country-industry level.") ctitle(" ", "Services") drop(i.year) addtext(Year FE, YES) excel 


}





}


