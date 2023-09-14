# CompNet Firm productivity report 23 - chapter 5b
# Authors: Marcelo Ribeiro 

# pacakages upload ####
# required downloads (execute only the first time):
packages <- c("ggplot2", 
              "rdbnomics",
              "readxl", 
              "dplyr", 
              "tidyr", 
              "data.table",
              "purrr",
              "pander", 
              "devtools",
              "tidyverse",
              "data.table",
              "curl",
              "zip",
              "rio",
              "stringr",
              "magrittr",
              "here",
              "haven",
              "ggallin",
              "patchwork",
              "cowplot",
              "ggpubr",
              "grid",
              "gridExtra",
              "stargazer", 
              "ggforce",
              "scales",
              "xtable",
              "vtable",
              "stringr",
              "ggthemes",
              "emmeans",
              "jtools",
              "sjPlot",
              "sjmisc")

# Check installed packages
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
#Packages loading
invisible(lapply(packages, library, character.only = TRUE))

# clean environment
rm(list = ls())

# set your directory if necessary
# setwd("/Users/Ribeiro/OneDrive/Ignore/?rea de Trabalho/CompNet/Firm productivity report/Chpt 5b SMEs")
load("./external_data_sources.RData")

# Import CompNet data: ####

# at country level only:
unconditional_country_all_weighted <- read_dta("unconditional_country_all_weighted.dta") %>%
  rename(`Reference area`=country)

# at country and age level:
unconditional_age_firm_all_weighted <- read_dta("unconditional_age_firm_all_weighted.dta") %>%
  rename(`Reference area`=country)%>%
  rename(FIRM_AGE=age_firm)

# at country and size level:
unconditional_szcl_all_weighted <- read_dta("unconditional_macsec_szcl_all_weighted.dta")  %>% # import data
  separate(macsec_szcl, into = c("var1", "mac_sector", "var3", "sizeclass"), sep = "_") %>% # split macsector and sizeclass variable
  mutate(across(c(mac_sector, sizeclass), as.numeric)) %>% # transform the splitted variables into numeric
  select(-var1, -var3) %>% 
  drop_na(FD00_absconstr_flag) %>%# remove entries without information about credit constraint
  select(country, year, mac_sector, sizeclass,LV03_jcr_pop_MS_tot,
         CD01_old_high_0_mn, CD08_old_low_0_mn, CD15_young_high_0_mn, CD22_young_low_0_mn,CE56_markdown_k_5_mn, CE56_markdown_k_5_p50, CE58_markdown_l_5_mn, CE58_markdown_l_5_p50, CE60_markup_5_mn, CE60_markup_5_p50,FD00_absconstr_N, FD00_absconstr_flag, FD00_absconstr_mn, FD00_absconstr_sw, FD01_safe_N, FD01_safe_flag, FD01_safe_mn, FD01_safe_sw,FD05_zombie_intcov_pos_mn, FD06_zombie_intcov_mn, FD07_zombie_negprof_mn,FR00_capcost_m_mn, FR00_capcost_m_p50, FR01_cash_ta_mn, FR01_cash_ta_p50, FR02_cashflow_ta_mn, FR02_cashflow_ta_p50,FR03_collateral_ta_mn, FR03_collateral_ta_p50, FR04_costcov_lc_m_mn, FR04_costcov_lc_m_p50, FR08_equity_debt_mn, FR08_equity_debt_p50, FR09_equity_ta_mn, FR09_equity_ta_p50,FR10_fingap_mn, FR10_fingap_p50, FR12_inte_debt_mn, FR12_inte_debt_p50, FR15_lc_capcost_mn, FR15_lc_capcost_p50, FR18_leverage_mn, FR18_leverage_p50,FR19_op_inte_mn, FR19_op_inte_p50, FR22_profitmargin_mn, FR22_profitmargin_p50, FR30_rk_l_mn, FR30_rk_l_p50, FR31_roa_mn, FR31_roa_p50,FR32_trade_credit_mn, FR32_trade_credit_p50, FR33_trade_debt_mn, FR33_trade_debt_p50, FR37_invest_k_mn, FR37_invest_k_p50, FR38_invest_rev_mn, FR38_invest_rev_p50,FV00_capcost_mn, FV00_capcost_p50, FV01_debt_mn, FV01_debt_p50, FV02_debt_fin_mn, FV02_debt_fin_p50, FV04_nk_mn, FV04_nk_p50,FV05_nlc_mn, FV05_nlc_p50, FV08G1_nrev_mn, FV08G1_nrev_p50, FV10_nva_mn, FV10_nva_p50, FV12_nvi_mn, FV12_nvi_p50,FV14G3_rk_mn, FV14G3_rk_p50, FV14_rk_mn, FV14_rk_p50, FV15_rlc_mn, FV15_rlc_p50, FV16_rm_mn, FV16_rm_p50,FV17_rrev_mn, FV17_rrev_p50, FV18_rva_mn, FV18_rva_p50, FV20_ta_mn, FV20_ta_p50, FV23_y_zombie_negprof_mn, FV23_y_zombie_negprof_p50,FV24_etr_mn, FV24_etr_p50, FV26_ninvest_mn, FV26_ninvest_p50, FV29_rinvest_mn, FV29_rinvest_p50, LR02_tertshare_mn, LR02_tertshare_p50,LV03_jcr_pop_MS_tot, LV13_jdr_pop_MS_tot, LV21G1_l_mn, LV21G1_l_p50, LV21G3_l_mn, LV21G3_l_p50, LV21_l_mn,LV21_l_p50, LV24_rwage_mn, LV24_rwage_p50, OD00_exit_mn, OD01_firm_age_medium_mn, OD02_firm_age_new_mn, OD03_firm_age_old_mn, OD04_firm_age_young_mn, OD05_foreign_own_mn,OD06_llc_mn, OD07_publ_own_mn, OV00_firm_age_mn, OV00_firm_age_p50, OV01_firm_age_atexit_mn, OV01_firm_age_atexit_p50, OV02_years_till_exit_mn, OV02_years_till_exit_p50,PEd5_mrpk_0_mn, PEd5_mrpk_0_p50, PEe1_mrpl_0_mn, PEe1_mrpl_0_p50, PEe7_oe_k_0_mn, PEe7_oe_k_0_p50, PEh1_oe_m_0_mn, PEh1_oe_m_0_p50, PEl3_oe_k_5_mn, PEl3_oe_k_5_p50, PV01_lnkprod_va_mn,PV01_lnkprod_va_p50, PV02_lnlprod_rev_mn, PV02_lnlprod_rev_p50, PV03_lnlprod_va_mn, PV03_lnlprod_va_p50, PV05_lnsr_cs_mn, PV05_lnsr_cs_p50, PV06_lprod_rev_mn, PV06_lprod_rev_p50,PV07_lprod_va_mn, PV07_lprod_va_p50, TD01_2w_exterior_adj_mn, TD03_2w_extersale_adj_mn, TD07_2w_interior_adj_mn, TD09_2w_intersale_adj_mn,TD13_2w_total_adj_mn, TD14_exp_mn, TD16_exp_adj_con2_mn, TD17_exp_adj_con3_mn, TD18_exp_adj_net_mn,TD19_exp_adj_new2_mn, TD21_exp_adj_non2_mn, TD22_exp_adj_non3a_mn, TD24_exp_adj_stop3a_mn,TV02_exp_mn, TV02_exp_p50, TV03_exp_adj_mn, TV03_exp_adj_p50, TV04_exp_ex_mn, TV04_exp_ex_p50, TV05_exp_ex_adj_mn,TV05_exp_ex_adj_p50, TV06_exp_in_mn, TV06_exp_in_p50, TV07_exp_in_adj_mn, TV07_exp_in_adj_p50, TV08_imp_mn,TV08_imp_p50, TV09_imp_adj_mn, TV09_imp_adj_p50, TV10_imp_ex_mn, TV10_imp_ex_p50, TV11_imp_ex_adj_mn, TV11_imp_ex_adj_p50, TV12_imp_in_mn, TV12_imp_in_p50,TV13_imp_in_adj_mn, TV13_imp_in_adj_p50) %>%
  mutate(effective_tax_ta=FV24_etr_mn/FV20_ta_mn,
         real_inv_ta=FV29_rinvest_mn/FV20_ta_mn,
         n_employees_ta=(LV21_l_mn/FV20_ta_mn),
         debt_ta=FV01_debt_mn/FV20_ta_mn,
         equity_debt_ta=FR08_equity_debt_mn/FV20_ta_mn,
         real_input_ta=FV16_rm_mn/FV20_ta_mn,
         real_va_ta=FV18_rva_mn/FV20_ta_mn,
         real_wage_ta=LV24_rwage_mn/FV20_ta_mn)%>%
  rename(`Cash/Tot.assets` = FR01_cash_ta_mn, `Collateral/Tot.assets` = FR03_collateral_ta_mn, 
         `Cost coverage rate`=FR04_costcov_lc_m_mn,`Financial gap`=FR10_fingap_mn, 
         Leverage=FR18_leverage_mn, `Effective tax/Tot.assets`=effective_tax_ta,
         `Job creation`=LV03_jcr_pop_MS_tot,`D=1 firm limited liability`=OD06_llc_mn,
         Age=OV00_firm_age_mn, `Log Solow resid`=PV05_lnsr_cs_mn, `Growth rate`=FV14G3_rk_mn, 
         `Real inv/Tot.assets`=real_inv_ta,`Capital intensity`=FR30_rk_l_mn, 
         `Log labor product.`=PV03_lnlprod_va_mn, `Real interm inp/Tot.assets` =real_input_ta, 
         `Real-value added`=real_va_ta, `Headcounts/Tot.assets`=n_employees_ta,
         `Real wage`=real_wage_ta, `Accounts receivable/Tot.assets`=FR33_trade_debt_mn, 
         `L&S Debt/Tot.aseets`=debt_ta, `Equity-debt/Tot.assets`=equity_debt_ta)%>%
  pivot_longer(cols = -c(country, year, mac_sector, sizeclass), 
               names_to = "survey_indicator", 
               values_to = "yearly_avg")%>%
  mutate(sizeclass = case_when(
    sizeclass == 1 ~ "MIC",
    sizeclass == 2 ~ "SML",
    sizeclass == 3 ~ "SML",
    sizeclass == 4 ~ "MED",
    sizeclass == 5 ~ "LAR",
    TRUE ~ ""
  ))%>%
  group_by(year, country, sizeclass, survey_indicator) %>% 
  summarise(yearly_avg = round(mean(yearly_avg, na.rm = TRUE), digits = 3)) %>%  
  rename(aggregation_level=sizeclass) %>%
  rename(`Reference area`=country)%>%
  pivot_wider(
    names_from = "survey_indicator",
    values_from = "yearly_avg"
  ) 


# 5.1 Credit constraints - figure 29
# summary OECD ####
oecd_data_plot<-oecd_data %>% 
  filter(survey_indicator=="OECD-Long-term interest rates, Per cent per annum")

ggplot(oecd_data_plot, aes(x = as.numeric(year), y = yearly_avg, color = REF_AREA)) +
  scale_x_continuous(breaks=seq(1999, 2023, 2))+
  scale_y_continuous(breaks=seq(-2, 25, 2))+
  geom_line(size = 0.75)  +
  scale_color_manual(values = c("LT" = "gold", "GR" = "maroon", "LV" = "forestgreen", "PT"="darkorange",
                                "IE"="sienna", "SI"="black", "IT"="lavender", "ES"="navy")) +
  labs(
    x = "Year",
    y = "Long-term interest rates",
    color = "")+
  theme_stata(scheme = "s2color")+ 
  geom_vline(xintercept = c(2009, 2012), linetype = "dashed", color = "black") +
  labs(x = "") + labs(x = NULL)+
  theme(
    plot.background = element_rect(fill = "white"),
    panel.background = element_rect(fill = "white"),
    panel.grid.minor = element_blank()
  )

# Figure 30
mean_data <- oecd_data %>%
  group_by(year,survey_indicator) %>%
  subset(survey_indicator %in% c("OECD-Outstanding business loans, total",
                                 "OECD-Government guaranteed loans, SMEs",
                                 "OECD-Short-term loans, SMEs",
                                 "OECD-Long-term loans, SMEs",
                                 "OECD-Outstanding business loans, SMEs", 
                                 "OECD-Outstanding business loans, total",
                                 "OECD-Percentage of SME loan applications (SME loan applications/ total number of SMEs)",
                                 "OECD-Rejection rate (1-(SME loans authorised/ requested))"
  ))%>%
  summarise(mean_yearly_avg = median(yearly_avg))%>% group_by(survey_indicator)%>%
  mutate(
    yoy = (mean_yearly_avg - lag(mean_yearly_avg)) / lag(mean_yearly_avg)
  )

ggplot(mean_data, aes(x=as.numeric(year), y=as.numeric(yoy), fill=survey_indicator)) +
  geom_bar(stat="identity")+
  scale_fill_manual(values=c("navy", "maroon", "forestgreen", "darkorange", "lavender", "khaki", "sienna"),
                    labels = c("Govt guaranteed loans, SMEs", "Long-term loans, SMEs", "Outstanding business loans, SMEs", 
                               "Business loans, total", "SME loan applications", "SME loan rejection rate/requests", "Short-term loans, SMEs"))+
  labs(
    x = "Year",
    y = "Log scale", fill="")+
  scale_x_continuous(breaks=seq(2007, 2020, 1))+
  #scale_y_continuous(breaks=seq(0, 15, 1))+
  theme_stata(scheme = "s1mono")+
  guides(fill = guide_legend(nrow = 4))+
  labs(x = "") + theme(axis.title = element_text(size = 9),
                       legend.text = element_text(size = 9),
                       legend.title = element_text(size = 9)) + 
  labs(x = NULL)+theme(
    plot.background = element_rect(fill = "white"),
    panel.background = element_rect(fill = "white"),
    panel.grid.minor = element_blank()
  )

# figure 31
external_data_merged_long<-bank_lending_survey %>%
  bind_rows(bank_lending_survey_demand)%>%
  bind_rows(safe_survey)%>%
  bind_rows(doing_business_wb_survey)%>%
  bind_rows(enterprise_survey_wb)%>%
  bind_rows(world_dvp_ind_wb)%>%
  bind_rows(oecd_data)%>%
  bind_rows(eurostat)%>%
  filter(aggregation_level %in% c("Z","ALL","ZZ")) %>%
  filter(FIRM_AGE %in% c(NA,"0")) %>%
  filter(sector %in% c(NA, "All sectors")) %>%
  mutate(aggregation_level = "ZZ")%>%
  mutate(FIRM_AGE = 0)%>%
  mutate(sector = "All sectors")%>%
  mutate(yearly_avg = round(yearly_avg, 2)) %>%
  select(-sector,-FIRM_AGE, -aggregation_level)

mean_data <- external_data_merged_long %>%
  group_by(aggregation_level,survey_indicator,year) %>%
  subset(survey_indicator %in% c("ECB_BLSS-Overall",
                                 "ECB_BLSD-DR [Impact of debt refinancing/restructuring/renegotiation (36)]",
                                 "ECB_BLSD-FIX [Impact of fixed investment (36)]",
                                 "ECB_BLSD-INV [Impact of inventories and working capital (36)]",
                                 "ECB_BLSD-LTL [Long-term loans (36)]",
                                 "ECB_BLSD-STL [Short-term loans (36)]"))%>%
  summarise(mean_yearly_avg = median(yearly_avg))

ggplot(mean_data, aes(x = as.numeric(year), y = mean_yearly_avg, fill=survey_indicator)) +
  geom_bar(stat="identity", aes(fill = survey_indicator), 
           data = mean_data %>% filter(survey_indicator != "ECB_BLSS-Overall"),
           size = 0.75) +
  scale_x_continuous(breaks=seq(2003, 2023, 2))+
  scale_fill_manual(values = c("maroon", "gold", "forestgreen", "khaki", "navy", "white"), 
                    labels = c("Loan refinancing/restructiring/renegotiation", 
                               "Fixed investment financing needs",
                               "Inventories and working capital financing needs",
                               "Long-term loans demand",
                               "Short-term loans demand", "")) +
  guides(linetype = "none")+
  geom_line(data = filter(mean_data, survey_indicator == "ECB_BLSS-Overall"),
            aes(y = mean_yearly_avg, linetype = "Overal credit supply conditions, index from ECB Euro area bank lending survey"),
            fill = "black",  size = 1)+
  labs(
    x = "Year",
    y = "Diffusion index percentage points", fill="")+
  theme_stata(scheme = "s2color")+
  guides(fill = guide_legend(nrow = 3), linetype = guide_legend(title = "")) +
  labs(x = "")  + 
  geom_vline(xintercept = c(2008, 2012, 2020), linetype = "dashed", color = "black") +
  labs(x = "") + theme(axis.title = element_text(size = 9),
                       legend.text = element_text(size = 9),
                       legend.title = element_text(size = 9)) +
  labs(x = NULL)+theme(
    plot.background = element_rect(fill = "white"),
    panel.background = element_rect(fill = "white"),
    panel.grid.minor = element_blank()
  )

# Figure 32
external_data_country<-bank_lending_survey %>%
  bind_rows(bank_lending_survey_demand)%>%
  bind_rows(safe_survey)%>%
  bind_rows(doing_business_wb_survey)%>%
  bind_rows(enterprise_survey_wb)%>%
  bind_rows(world_dvp_ind_wb)%>%
  bind_rows(oecd_data)%>%
  bind_rows(eurostat)%>%
  #bind_rows(imf_interest)%>%
  filter(aggregation_level %in% c("Z","ALL","ZZ")) %>%
  filter(FIRM_AGE %in% c(NA,"0")) %>%
  filter(sector %in% c(NA, "All sectors")) %>%
  mutate(aggregation_level = "ZZ")%>%
  mutate(FIRM_AGE = 0)%>%
  mutate(sector = "All sectors")%>%
  mutate(yearly_avg = round(yearly_avg, 2)) %>%
  select(-sector,-FIRM_AGE, -aggregation_level) %>%
  pivot_wider(
    names_from = "survey_indicator",
    values_from = "yearly_avg"
  ) 

unconditional_country_20e_weighted <- read_dta("unconditional_country_20e_weighted.dta") %>%
  mutate(`Reference area`=country)%>%
  merge(external_data_country, by=c("Reference area", "year"), all.x=T)%>%
  select("Reference area", "year","FD01_safe_mn","FD00_absconstr_mn",
         "OECD-Long-term interest rates, Per cent per annum",
         "OECD-Short-term interest rates, Per cent per annum",
         "OECD-Interest rate, SMEs","OECD-Interest rate, large firms",
         #"WB_WDI-Annual - Domestic credit to private sector by banks (% of GDP) -",
         "Eurostat-Composite cost-of-borrowing indicator for new loans to non-financial corporations (percentages per annum, rates on new business)",
         "Eurostat-Composite cost-of-borrowing indicator for short-term loans to both households and non-financial corporations" ,
         "ECB_BLSS-Overall","ECB_BLSD-O [Overall (72)]")

mean_data <- unconditional_country_20e_weighted %>%
  group_by(year) %>%
  summarise(mean_yearly_avg = mean(FD01_safe_mn, na.rm = T),
            mean_yearly_avg3= mean(`OECD-Long-term interest rates, Per cent per annum`,na.rm = T),
            mean_yearly_avg4= mean(`OECD-Short-term interest rates, Per cent per annum`,na.rm = T))%>%
  filter(!(is.na(mean_yearly_avg)))

ggplot(mean_data, aes(x = mean_yearly_avg, y = mean_yearly_avg3)) +
  geom_point(color = "navy") +
  stat_smooth(se = FALSE, method = "lm", color = "maroon", linetype = "solid")+
  labs(title = "")+
  theme_stata(scheme = "s2color")+
  theme(
    plot.background = element_rect(fill = "white"),
    panel.background = element_rect(fill = "white"),
    panel.grid.minor = element_blank()
  )+labs(title = NULL, x = "Credit score CompNet (% firms credit constrained)",
         y = "Interest rate (Long) - OECD")

# Table 14
data <- read_dta("unconditional_macsec_szcl_all_weighted.dta")  %>% # import data
  separate(macsec_szcl, into = c("var1", "mac_sector", "var3", "sizeclass"), sep = "_") %>% # split macsector and sizeclass variable
  mutate(across(c(mac_sector, sizeclass), as.numeric)) %>% # transform the splitted variables into numeric
  select(-var1, -var3) %>% 
  drop_na(FD00_absconstr_flag) %>%# remove entries without information about credit constraint
  select(country, year, mac_sector, sizeclass,CD01_old_high_0_mn, CD08_old_low_0_mn, CD15_young_high_0_mn, CD22_young_low_0_mn,CE56_markdown_k_5_mn, CE56_markdown_k_5_p50, CE58_markdown_l_5_mn, CE58_markdown_l_5_p50, CE60_markup_5_mn, CE60_markup_5_p50,FD00_absconstr_N, FD00_absconstr_flag, FD00_absconstr_mn, FD00_absconstr_sw, FD01_safe_N, FD01_safe_flag, FD01_safe_mn, FD01_safe_sw,FD05_zombie_intcov_pos_mn, FD06_zombie_intcov_mn, FD07_zombie_negprof_mn,FR00_capcost_m_mn, FR00_capcost_m_p50, FR01_cash_ta_mn, FR01_cash_ta_p50, FR02_cashflow_ta_mn, FR02_cashflow_ta_p50,FR03_collateral_ta_mn, FR03_collateral_ta_p50, FR04_costcov_lc_m_mn, FR04_costcov_lc_m_p50, FR08_equity_debt_mn, FR08_equity_debt_p50, FR09_equity_ta_mn, FR09_equity_ta_p50,FR10_fingap_mn, FR10_fingap_p50, FR12_inte_debt_mn, FR12_inte_debt_p50, FR15_lc_capcost_mn, FR15_lc_capcost_p50, FR18_leverage_mn, FR18_leverage_p50,FR19_op_inte_mn, FR19_op_inte_p50, FR22_profitmargin_mn, FR22_profitmargin_p50, FR30_rk_l_mn, FR30_rk_l_p50, FR31_roa_mn, FR31_roa_p50,FR32_trade_credit_mn, FR32_trade_credit_p50, FR33_trade_debt_mn, FR33_trade_debt_p50, FR37_invest_k_mn, FR37_invest_k_p50, FR38_invest_rev_mn, FR38_invest_rev_p50,FV00_capcost_mn, FV00_capcost_p50, FV01_debt_mn, FV01_debt_p50, FV02_debt_fin_mn, FV02_debt_fin_p50, FV04_nk_mn, FV04_nk_p50,FV05_nlc_mn, FV05_nlc_p50, FV08G1_nrev_mn, FV08G1_nrev_p50, FV10_nva_mn, FV10_nva_p50, FV12_nvi_mn, FV12_nvi_p50,FV14G3_rk_mn, FV14G3_rk_p50, FV14_rk_mn, FV14_rk_p50, FV15_rlc_mn, FV15_rlc_p50, FV16_rm_mn, FV16_rm_p50,FV17_rrev_mn, FV17_rrev_p50, FV18_rva_mn, FV18_rva_p50, FV20_ta_mn, FV20_ta_p50, FV23_y_zombie_negprof_mn, FV23_y_zombie_negprof_p50,FV24_etr_mn, FV24_etr_p50, FV26_ninvest_mn, FV26_ninvest_p50, FV29_rinvest_mn, FV29_rinvest_p50, LR02_tertshare_mn, LR02_tertshare_p50,LV03_jcr_pop_MS_tot, LV13_jdr_pop_MS_tot, LV21G1_l_mn, LV21G1_l_p50, LV21G3_l_mn, LV21G3_l_p50, LV21_l_mn,LV21_l_p50, LV24_rwage_mn, LV24_rwage_p50, OD00_exit_mn, OD01_firm_age_medium_mn, OD02_firm_age_new_mn, OD03_firm_age_old_mn, OD04_firm_age_young_mn, OD05_foreign_own_mn,OD06_llc_mn, OD07_publ_own_mn, OV00_firm_age_mn, OV00_firm_age_p50, OV01_firm_age_atexit_mn, OV01_firm_age_atexit_p50, OV02_years_till_exit_mn, OV02_years_till_exit_p50,PEd5_mrpk_0_mn, PEd5_mrpk_0_p50, PEe1_mrpl_0_mn, PEe1_mrpl_0_p50, PEe7_oe_k_0_mn, PEe7_oe_k_0_p50, PEh1_oe_m_0_mn, PEh1_oe_m_0_p50, PEl3_oe_k_5_mn, PEl3_oe_k_5_p50, PV01_lnkprod_va_mn,PV01_lnkprod_va_p50, PV02_lnlprod_rev_mn, PV02_lnlprod_rev_p50, PV03_lnlprod_va_mn, PV03_lnlprod_va_p50, PV05_lnsr_cs_mn, PV05_lnsr_cs_p50, PV06_lprod_rev_mn, PV06_lprod_rev_p50,PV07_lprod_va_mn, PV07_lprod_va_p50, TD01_2w_exterior_adj_mn, TD03_2w_extersale_adj_mn, TD07_2w_interior_adj_mn, TD09_2w_intersale_adj_mn,TD13_2w_total_adj_mn, TD14_exp_mn, TD16_exp_adj_con2_mn, TD17_exp_adj_con3_mn, TD18_exp_adj_net_mn,TD19_exp_adj_new2_mn, TD21_exp_adj_non2_mn, TD22_exp_adj_non3a_mn, TD24_exp_adj_stop3a_mn,TV02_exp_mn, TV02_exp_p50, TV03_exp_adj_mn, TV03_exp_adj_p50, TV04_exp_ex_mn, TV04_exp_ex_p50, TV05_exp_ex_adj_mn,TV05_exp_ex_adj_p50, TV06_exp_in_mn, TV06_exp_in_p50, TV07_exp_in_adj_mn, TV07_exp_in_adj_p50, TV08_imp_mn,TV08_imp_p50, TV09_imp_adj_mn, TV09_imp_adj_p50, TV10_imp_ex_mn, TV10_imp_ex_p50, TV11_imp_ex_adj_mn, TV11_imp_ex_adj_p50, TV12_imp_in_mn, TV12_imp_in_p50,TV13_imp_in_adj_mn, TV13_imp_in_adj_p50) %>%
  mutate(effective_tax_ta=FV24_etr_mn/FV20_ta_mn,
         real_inv_ta=FV29_rinvest_mn/FV20_ta_mn,
         n_employees_ta=(LV21_l_mn/FV20_ta_mn),
         debt_ta=FV01_debt_mn/FV20_ta_mn,
         equity_debt_ta=FR08_equity_debt_mn/FV20_ta_mn,
         real_input_ta=FV16_rm_mn/FV20_ta_mn,
         real_va_ta=FV18_rva_mn/FV20_ta_mn,
         real_wage_ta=LV24_rwage_mn/FV20_ta_mn)%>%
  rename(`Cash/Tot.assets` = FR01_cash_ta_mn, `Collateral/Tot.assets` = FR03_collateral_ta_mn, 
         `Cost coverage rate`=FR04_costcov_lc_m_mn,`Financial gap`=FR10_fingap_mn, 
         Leverage=FR18_leverage_mn, `Effective tax/Tot.assets`=effective_tax_ta,
         `Job creation`=LV03_jcr_pop_MS_tot,`D=1 firm limited liability`=OD06_llc_mn,
         Age=OV00_firm_age_mn, `Log Solow resid`=PV05_lnsr_cs_mn, `Growth rate`=FV14G3_rk_mn, 
         `Real inv/Tot.assets`=real_inv_ta,`Capital intensity`=FR30_rk_l_mn, 
         `Log labor product.`=PV03_lnlprod_va_mn, `Real interm inp/Tot.assets` =real_input_ta, 
         `Real-value added`=real_va_ta, `Headcounts/Tot.assets`=n_employees_ta,
         `Real wage`=real_wage_ta, `Accounts receivable/Tot.assets`=FR33_trade_debt_mn, 
         `L&S Debt/Tot.aseets`=debt_ta, `Equity-debt/Tot.assets`=equity_debt_ta)

data<- data %>% select(country, year, mac_sector, sizeclass,FD01_safe_flag,`Cash/Tot.assets`, `Collateral/Tot.assets`,`Cost coverage rate`,`Financial gap`, Leverage, `Effective tax/Tot.assets`,`Job creation`,`D=1 firm limited liability`, Age, `Log Solow resid`,`Growth rate`,`Real inv/Tot.assets`,`Capital intensity`,`Log labor product.`, `Real interm inp/Tot.assets`,`Real-value added`,`Headcounts/Tot.assets`,`Real wage`, `Accounts receivable/Tot.assets`,`L&S Debt/Tot.aseets`, `Equity-debt/Tot.assets`) %>%
  drop_na(FD01_safe_flag)

# freq_table <- data %>%
#   count(sizeclass) %>%
#   mutate(Percent = n/sum(n),
#          Cum. = cumsum(Percent))
# 
# freq_table1 <- data %>%
#   count(country) %>%
#   mutate(Percent = n/sum(n),
#          Cum. = cumsum(Percent))
# 
# freq_table2 <- data %>%
#   count(year) %>%
#   mutate(Percent = n/sum(n),
#          Cum. = cumsum(Percent))

# Create an empty list to store tables
tables_list <- list()


# Loop through each value of "mac_sector"
for (sector in unique(data$mac_sector)) {
  # Create a new dataset with only the current sector
  sector_data <- data %>% filter(mac_sector == sector)
  # Calculate the means by "CD01_old_high_0_flag"
  means_table3 <- sector_data %>% 
    group_by(FD01_safe_flag, sizeclass) %>% 
    summarise_at(vars(`Cash/Tot.assets`, `Collateral/Tot.assets`,`Cost coverage rate`,`Financial gap`, Leverage, `Effective tax/Tot.assets`,`Job creation`,`D=1 firm limited liability`, Age, `Log Solow resid`,`Growth rate`,`Real inv/Tot.assets`,`Capital intensity`,`Log labor product.`, `Real interm inp/Tot.assets`,`Real-value added`,`Headcounts/Tot.assets`,`Real wage`, `Accounts receivable/Tot.assets`,`L&S Debt/Tot.aseets`, `Equity-debt/Tot.assets`), ~sprintf("%.2f", mean(as.numeric(.), na.rm = TRUE))) %>% 
    pivot_longer(cols = c(`Cash/Tot.assets`, `Collateral/Tot.assets`,`Cost coverage rate`,`Financial gap`, Leverage, `Effective tax/Tot.assets`,`Job creation`,`D=1 firm limited liability`, Age, `Log Solow resid`,`Growth rate`,`Real inv/Tot.assets`,`Capital intensity`,`Log labor product.`, `Real interm inp/Tot.assets`,`Real-value added`,`Headcounts/Tot.assets`,`Real wage`, `Accounts receivable/Tot.assets`,`L&S Debt/Tot.aseets`, `Equity-debt/Tot.assets`), names_to = "variable", values_to = "value") %>% 
    pivot_wider(names_from = FD01_safe_flag, values_from = "value")
  # Rename the table
  table_name <- paste("Balance table for", sector)
  # Create a unique file name for each output file
  file_name <- paste(sector, "output.txt", sep = "_")
  # Print the table to a unique file
  write.table(means_table3, file = file_name, sep = "\t", col.names = NA, quote = FALSE)
  # Store the table in the list
  tables_list[[sector]] <- means_table3
  # Remove the sector_data from memory
  rm(sector_data)
}

# Create a function to merge tibbles
merge_tibbles <- function(list_of_tibbles) {
  merged_tibble <- dplyr::bind_rows(list_of_tibbles, .id = "table_number")
  return(merged_tibble)
}
# Call the function and pass the list of tibbles
merged_tibble <- merge_tibbles(tables_list) %>%  na.omit()

df_wide <- merged_tibble %>%
  pivot_wider(names_from = table_number, 
              values_from = c("0", "1")) %>%
  select(sizeclass, variable, everything())%>%
  rename_all(~gsub("^0_", "NC_", .))%>%
  rename_all(~gsub("^1_", "C_", .)) %>%
  mutate(across(
    starts_with("NC_") | starts_with("C_"), 
    ~ as.numeric(as.character(.))
  )) %>%
  mutate(NC_Avg = round(rowMeans(select(., starts_with("NC_")), na.rm = TRUE),2),
         C_Avg = round(rowMeans(select(., starts_with("C_")), na.rm = TRUE),2))%>%
  select(sizeclass, variable,NC_Avg,C_Avg, NC_1, C_1, NC_2, C_2,NC_3, C_3,NC_4, C_4,NC_5, C_5,NC_6, C_6,NC_7, C_7,NC_8, C_8,NC_9, C_9)


means_table3 <- as.data.frame(means_table3) %>%
  rename(Constrained = `1`, `Not constrained`=`0`, `Firms' characteristics`=variable)%>%
  mutate(Constrained= as.numeric(Constrained))%>%
  mutate(`Not constrained`= as.numeric(`Not constrained`))%>%
  mutate(`Difference` = Constrained - `Not constrained`) %>%
  drop_na(`Difference`) %>%
  mutate(sizeclass = case_when(
    sizeclass == 1 ~ "1-9 empl",
    sizeclass == 2 ~ "10-19 empl",
    sizeclass == 3 ~ "20-49 empl",
    sizeclass == 4 ~ "50-249 empl",
    sizeclass == 5 ~ ">249 empl"))%>% 
  arrange(desc(`Firms' characteristics`))%>%
  filter(`Firms' characteristics` %in% c("Real-value added", "Real inv/Tot.assets",
                                         "Log labor product.", "Leverage",
                                         "L&S Debt/Tot.assets", "Job creation",
                                         "Growth rate", "Collateral/Tot.assets",
                                         "Age"))

print(xtable(means_table3, type="latex",  include.rownames = FALSE))

# Table 15
raw2_unconditional_szcl_all_weighted <- read_dta("unconditional_macsec_szcl_all_weighted.dta")  %>% # import data
  separate(macsec_szcl, into = c("var1", "mac_sector", "var3", "sizeclass"), sep = "_") %>% # split macsector and sizeclass variable
  mutate(across(c(mac_sector, sizeclass), as.numeric)) %>% # transform the splitted variables into numeric
  select(-var1, -var3) %>% 
  drop_na(FD00_absconstr_flag) %>%
  mutate(sizeclass = case_when(
    sizeclass == 1 ~ "MIC",
    sizeclass == 2 ~ "SML",
    sizeclass == 3 ~ "SML",
    sizeclass == 4 ~ "MED",
    sizeclass == 5 ~ "LAR",
    TRUE ~ ""
  ))

lm_bii<-lm(FR31_roa_p50 ~ factor(sizeclass)*OV00_firm_age_p50*FD01_safe_mn*factor(mac_sector) + factor(country) + factor(year), 
           data = raw2_unconditional_szcl_all_weighted, na.action = na.exclude)

lm_cii<-lm(FV08G1_nrev_p50 ~ factor(sizeclass)*OV00_firm_age_p50*FD01_safe_mn*factor(mac_sector) + factor(country) + factor(year), 
           data = raw2_unconditional_szcl_all_weighted, na.action = na.exclude)

lm_dii<-lm(PV05_lnsr_cs_p50 ~ factor(sizeclass)*OV00_firm_age_p50*FD01_safe_mn*factor(mac_sector) + factor(country) + factor(year), 
           data = raw2_unconditional_szcl_all_weighted, na.action = na.exclude)

stargazer(lm_bii,lm_cii,lm_dii,
          type = "latex",
          title="",
          float = TRUE,
          omit = "intercept",
          report = "vcs*",
          #se=lapply(lm2, function(x) sqrt(diag(vcovHC(x, type = "HC1")))),
          no.space = TRUE,
          header=FALSE,
          #covariate.labels = c("Constant","Abs financially constrained", 
          #                     "Median firm age", "Median headcount","Ratio i/debt"),
          single.row = TRUE,
          font.size = "small",
          intercept.bottom = F,
          column.labels = c("ROA","Growth rate (from t-1)", "Log. Solow residual"),
          column.separate = c(1,1, 1),
          digits = 2,
          t.auto = F,
          p.auto = F,
          notes.align = "l",
          caption="CompNet 9th vintage data, unconditional_szcl_all_weighted",
          #notes = c("datasets::freeny", "lm() function", "vcovHC(type = 'HC1')-Robust SE"),
          notes.append = TRUE
)

# Figure 33
lm061<-lm(FD01_safe_mn~ # job creation
            + aggregation_level*Age
          +`Reference area`+ factor(year), 
          data = unconditional_szcl_all_weighted, na.action = na.exclude)

(mylist_age <- list(Age=c(5.59,11.80 ,14.70, 18.97)))
noise.lm = lm061
plot.dat = emmip(noise.lm, aggregation_level~Age,at=mylist_age, plotit = FALSE, CIs=TRUE)
ggplot(data = plot.dat, 
       aes_(x = ~xvar, y = ~yvar, 
            group = ~tvar, linetype = ~tvar, shape = ~tvar)) +
  geom_point(size = 2) +
  geom_line() +
  labs(x = "Firms' age (years)", y = "Predicted share constrained firms (mean)", linetype = "Firms' size", shape = "Firms' size") +
  theme_stata()+theme(
    plot.background = element_rect(fill = "white"),
    panel.background = element_rect(fill = "white"),
    panel.grid.minor = element_blank()
  )

# Figure 34
lm062<-lm(FD01_safe_mn~ # job creation
            + aggregation_level*factor(year)*Age
          +`Reference area`, 
          data = unconditional_szcl_all_weighted, na.action = na.exclude)

plot_model(lm062, type = "pred",alpha = .05,
           terms = c("year[2007:2021]", 
                     "aggregation_level","Age [6,12 ,15, 19]"),colors = "Set2")+ aes(linetype=group, colour=group)+guides(colour = "none")+
  labs(colour = "Firm size:", linetype="Firm size", title="")+
  scale_x_continuous(breaks = seq(2008, 2020, 2)) + ylim(-.1, .35)+ theme_stata(scheme = "s2color")+ theme(
    plot.background = element_rect(fill = "white"),
    panel.background = element_rect(fill = "white"),
    panel.grid.minor = element_blank()
  )+ theme(axis.title = element_text(colour = NA)) +
  scale_color_manual(values = c("navy", "darkorange", "forestgreen", "maroon")) + theme(axis.text = element_text(angle = 45)) +labs(title = NULL)

# Figure 35
data <- raw2_unconditional_szcl_all_weighted %>%
  mutate(constraint_level = case_when(
    FD01_safe_mn < 0.01187 ~ "Little (P25)", #0.01187
    FD01_safe_mn < 0.0408 ~ "Medium (Median)", # 0.052
    FD01_safe_mn < 0.09812 ~ "High (P75)", # 0.09812
    TRUE ~ "Very high"
  ))%>%
  mutate(age_class = case_when(
    OV00_firm_age_p50 < 5 ~ "age < 5",
    OV00_firm_age_p50 < 10 ~ "5 <age < 10",
    OV00_firm_age_p50 < 20 ~ "10 < age <20",
    OV00_firm_age_p50 < 40 ~ "20 < age <40",
    TRUE ~ "40+"
  ))

lm_bi<-lm(FR31_roa_p50 ~ factor(sizeclass)*OV00_firm_age_p50*FD01_safe_mn + factor(country) + factor(year)+ factor(mac_sector), 
          data = raw2_unconditional_szcl_all_weighted, na.action = na.exclude)

lm_ci<-lm(FV08G1_nrev_p50 ~ factor(sizeclass)*OV00_firm_age_p50*FD01_safe_mn + factor(country) + factor(year)+ factor(mac_sector), 
          data = raw2_unconditional_szcl_all_weighted, na.action = na.exclude)

lm_di<-lm(PV05_lnsr_cs_p50 ~ factor(sizeclass)*OV00_firm_age_p50*FD01_safe_mn + factor(country) + factor(year), 
          data = raw2_unconditional_szcl_all_weighted, na.action = na.exclude)

predictions <- data.frame(predict(lm_di))

merged_data <- cbind(data, predictions)
merged_data <- merged_data[complete.cases(merged_data$predict.lm_di.), ]
merged_data <- merged_data[complete.cases(merged_data$OV00_firm_age_p50), ]

ggplot(merged_data, aes(x = OV00_firm_age_p50, y = predict.lm_di., color = factor(constraint_level))) +
  geom_smooth(alpha = 0.05) +
  labs(x = "Age (years old)", y = "Predicted ROA (median)") +
  facet_wrap(~ factor(sizeclass)) + theme_stata(scheme = "s2color")+theme(
    plot.background = element_rect(fill = "white"),
    panel.background = element_rect(fill = "white"),
    panel.grid.minor = element_blank()
  )+
  scale_color_manual(values = c("darkorange", "forestgreen","gold", "maroon"))+
  labs(colour = "Credit constraint levels") + theme(legend.text = element_text(size = 9),
                                                    legend.title = element_text(size = 8))
