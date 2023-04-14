# CompNet Firm productivity report 23 - initial graphs chapter 5b
# Authors: Marcelo Ribeiro 

# Data import
# required downloads (execute only the first time):
packages <- c("ggplot2", 
              "readxl", 
              "dplyr", 
              "tidyr", 
              "data.table",
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
              "haven")

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

# import data
unconditional_country_all_weighted <- read_dta("unconditional_country_all_weighted.dta") # all data
# filter only relevant data
data_country <- unconditional_country_all_weighted %>% 
  select (country, year, starts_with("FR18_leverage_"),
          starts_with("FR01_cash_ta_"),
          starts_with("FR02_cashflow_ta_"))%>% # select only the relevant variables to plot
  filter(year != 2008 | country != "France")%>% # exclude FR first year
  mutate(year = as.Date(paste0(year, "-01-01"), sep=""))%>% # transform year to Date type
  na.omit() # remove NAs


# Leverage ####
# plot average leverage of all countries per year
leverage_mn <- unconditional_country_all_weighted %>% 
               select (country, year, FR18_leverage_p25,FR18_leverage_p50,FR18_leverage_p75) %>%
               # select (country, year, starts_with("FR18_leverage_"),
               #         starts_with("FR01_cash_ta_"),
               #         starts_with("FR02_cashflow_ta_"))%>% # select only the relevant variables to plot
               filter(year != 2008 | country != "France")%>%
               filter(year != 2009 | country != "France")%>%
  rename("p25" = "FR18_leverage_p25", "p50" = "FR18_leverage_p50", "p75"="FR18_leverage_p75")%>%
               mutate(year = as.Date(paste0(year, "-01-01"), sep=""))%>%
               na.omit(df)%>% # remove NA
  gather(key = "Type", value = "P", p25:p75) %>% # stack columns 
  mutate(Type = gsub("p", "", Type), # add a column identifying which percentile the value comes from
         Type = as.integer(Type)) %>%
  group_by(year, Type) %>% 
  summarize(avg_P = mean(P)) # calculate the average for all countries by year

new_df <- pivot_wider(leverage_mn, names_from = "Type", values_from = "avg_P")
names(new_df)[-1] <- paste0("Type_", names(new_df)[-1])

ggplot(new_df, aes(x = year)) +
  geom_line(aes(y = Type_25, color = "25th percentile")) +
  geom_line(aes(y = Type_50, color = "50th percentile")) +
  geom_line(aes(y = Type_75, color = "75th percentile")) +
  scale_color_viridis_d() +
  labs(title = "Historical leverage of all countries by year",
       caption = "Each line represents the leverage average of all countries per year",
       x = "",
       y = "Leverage",
       color = "")+
  theme_light()+
  theme(axis.text = element_text(size = 8),
        axis.title = element_text(size = 8))

# plot by country:
ggplot(data_country, aes(x = year)) +
  geom_line(aes(y = FR18_leverage_p25, color = "25th percentile")) +
  geom_line(aes(y = FR18_leverage_p50, color = "50th percentile")) +
  geom_line(aes(y = FR18_leverage_p75, color = "75th percentile")) +
  scale_color_viridis_d() +
  #scale_color_manual(values = c("red", "orange", "purple", "brown", "blue")) +
  labs(title = "Historical leverage by country",
       x = "",
       color = "",
       y = "Leverage") +
  theme_light()+
  theme(axis.text = element_text(size = 5),
        axis.title = element_text(size = 5))+
  facet_wrap(vars(country))#, scales = "free")


# Cash over total assets
# plot average leverage of all countries per year
cash_ta_mn <- unconditional_country_all_weighted %>% 
  select (country, year, FR01_cash_ta_p25,FR01_cash_ta_p50,FR01_cash_ta_p75) %>%
  filter(year != 2008 | country != "France")%>%
  filter(year != 2009 | country != "France")%>%
  rename("p25" = "FR01_cash_ta_p25", "p50" = "FR01_cash_ta_p50", "p75"="FR01_cash_ta_p75")%>%
  mutate(year = as.Date(paste0(year, "-01-01"), sep=""))%>%
  na.omit(df)%>% # remove NA
  gather(key = "Type", value = "P", p25:p75) %>% # stack columns 
  mutate(Type = gsub("p", "", Type), # add a column identifying which percentile the value comes from
         Type = as.integer(Type)) %>%
  group_by(year, Type) %>% 
  summarize(avg_P = mean(P)) # calculate the average for all countries by year

new_df <- pivot_wider(cash_ta_mn, names_from = "Type", values_from = "avg_P")
names(new_df)[-1] <- paste0("Type_", names(new_df)[-1])

ggplot(new_df, aes(x = year)) +
  geom_line(aes(y = Type_25, color = "25th percentile")) +
  geom_line(aes(y = Type_50, color = "50th percentile")) +
  geom_line(aes(y = Type_75, color = "75th percentile")) +
  scale_color_viridis_d() +
  labs(title = "Historical levels of cash over total assets of all countries",
       caption = "Each line represents cash over total assets average of all countries per year",
       x = "",
       y = "Cash/total assets",
       color = "")+
  theme_light()+
  theme(axis.text = element_text(size = 8),
        axis.title = element_text(size = 8))

# plot by country
ggplot(data_country, aes(x = year)) +
  geom_line(aes(y = FR01_cash_ta_p25, color = "25th percentile")) +
  geom_line(aes(y = FR01_cash_ta_p50, color = "50th percentile")) +
  geom_line(aes(y = FR01_cash_ta_p75, color = "75th percentile")) +
  scale_color_viridis_d() +
  #scale_color_manual(values = c("red", "orange", "purple", "brown", "blue")) +
  labs(title = "Historical cash over total assets by country",
       x = "Year",
       y = "Cash/total assets") +
  theme_light()+
  theme(axis.text = element_text(size = 5),
        axis.title = element_text(size = 5))+
  facet_wrap(vars(country)) #scales = "free")

# Cashflow over total assets
cashflow_ta_mn <- unconditional_country_all_weighted %>% 
  select (country, year, FR02_cashflow_ta_p25, FR02_cashflow_ta_p50, FR02_cashflow_ta_p75) %>%
  filter(year != 2008 | country != "France")%>%
  filter(year != 2009 | country != "France")%>%
  rename("p25" = "FR02_cashflow_ta_p25", "p50" = "FR02_cashflow_ta_p50", "p75"="FR02_cashflow_ta_p75")%>%
  mutate(year = as.Date(paste0(year, "-01-01"), sep=""))%>%
  na.omit(df)%>% # remove NA
  gather(key = "Type", value = "P", p25:p75) %>% # stack columns 
  mutate(Type = gsub("p", "", Type), # add a column identifying which percentile the value comes from
         Type = as.integer(Type)) %>%
  group_by(year, Type) %>% 
  summarize(avg_P = mean(P)) # calculate the average for all countries by year

new_df <- pivot_wider(cashflow_ta_mn, names_from = "Type", values_from = "avg_P")
names(new_df)[-1] <- paste0("Type_", names(new_df)[-1])

ggplot(new_df, aes(x = year)) +
  geom_line(aes(y = Type_25, color = "25th percentile")) +
  geom_line(aes(y = Type_50, color = "50th percentile")) +
  geom_line(aes(y = Type_75, color = "75th percentile")) +
  scale_color_viridis_d() +
  labs(title = "Historical levels of cashflow over total assets of all countries",
       caption = "Each line represents cashflow over total assets average of all countries per year",
       x = "",
       y = "Cashflow/total assets",
       color = "")+
  theme_light()+
  theme(axis.text = element_text(size = 8),
        axis.title = element_text(size = 8))

# plot by country
ggplot(data_country, aes(x = year)) +
  geom_line(aes(y = FR02_cashflow_ta_p25, color = "25th percentile")) +
  geom_line(aes(y = FR02_cashflow_ta_p50, color = "50th percentile")) +
  geom_line(aes(y = FR02_cashflow_ta_p75, color = "75th percentile")) +
  scale_color_viridis_d() +
  #scale_color_manual(values = c("red", "orange", "purple", "brown", "blue")) +
  labs(title = "Historical cashflow over total assets by country",
       x = "",
       y = "Cashflow/total assets") +
  theme_light()+
  theme(axis.text = element_text(size = 5),
        axis.title = element_text(size = 5))+
  facet_wrap(vars(country), nrow = 4) #scales = "free")


# plot by size class and macro sector ####

# import data
rm(list = ls())
unconditional_macsec_szcl_all_weighted <- read_dta("unconditional_macsec_szcl_all_weighted.dta")

leverage_szcl <- unconditional_macsec_szcl_all_weighted %>% 
  select (country, year, macsec_szcl, starts_with("FR18_leverage_"),
          starts_with("FR01_cash_ta_"),
          starts_with("FR02_cashflow_ta_"))%>% # select only the relevant variables to plot
  mutate(year = as.Date(paste0(year, "-01-01"), sep=""))%>%
  filter(year != 2008 | country != "France")%>% # exclude FR first year
  filter(year != 2009 | country != "France")%>%
  separate(macsec_szcl, c("var1", "var2", "var3", "sizeclass"), sep = "_") %>%
  mutate(sizeclass = as.numeric(sizeclass))%>%
  rename(sector = var2)%>%
  select(-var1,-var3)

# leverage:
names(leverage_szcl)[which(names(leverage_szcl) == "FR18_leverage_p50")] <- "p50" # median
leverage_szcl_by_sz <- leverage_szcl %>%
  mutate(l_p50_micro = if_else(sizeclass == 1, p50, NA_real_),
         l_p50_small = if_else(sizeclass == 2, p50, NA_real_),
         l_p50_medium = if_else(sizeclass == 3, p50, NA_real_),    
         l_p50_large = if_else(sizeclass == 4, p50, NA_real_),
         l_p50_big = if_else(sizeclass == 5, p50, NA_real_))
# overall 
ggplot(leverage_szcl_by_sz, aes(x = year)) +
  geom_smooth(aes(y = l_p50_micro, color = "1-9"), size=0.95, se = FALSE) +
  geom_smooth(aes(y = l_p50_small, color = "10-19"),size=0.5, se = FALSE) +
  geom_smooth(aes(y = p50, color = "Median"),size=0.5, se = FALSE) +
  labs(title = "Historical leverage levels by firm sizes",
       caption = "Median represents p50 leverage of all firms",
       x = "", y = "Leverage by firm size class") +
  guides(color = guide_legend(title = "")) + 
  scale_color_viridis_d() +
  theme_light()+
  theme(axis.text = element_text(size = 12),
        axis.title = element_text(size = 12))

# by sector
leverage_szcl_by_sz$sector_name <- 
  factor(leverage_szcl_by_sz$sector, 
         labels = c("Manufacturing", "Construction", 
                    "Wholesale and retail trade", "Transportation and storage",
                    "Accomodation & food services","Information and communication",
                    "Real estate activities",
                    "Professional scientific & technical activities",
                    "Administrative & support service activities"))

ggplot(leverage_szcl_by_sz, aes(x = year)) +
  geom_smooth(aes(y = l_p50_micro, color = "1-9"), size=0.95, se = FALSE) +
  geom_smooth(aes(y = l_p50_small, color = "10-19"),size=0.5, se = FALSE) +
  geom_smooth(aes(y = p50, color = "Median"),size=0.5, se = FALSE) +
  labs(title = "Historical leverage levels by firm sizes and sectors",
       caption = "Median represents p50 leverage of all firms",
       x = "", y = "Leverage by firm size class") +
  scale_color_viridis_d() +
  guides(color = guide_legend(title = "")) +
  theme_light()+
  theme(axis.text = element_text(size = 8),
        axis.title = element_text(size = 8))+
  facet_wrap(vars(sector_name))

# by country
ggplot(leverage_szcl_by_sz, aes(x = year)) +
  geom_smooth(aes(y = l_p50_micro, color = "1-9"), size=0.65, se = FALSE) +
  geom_smooth(aes(y = l_p50_small, color = "10-19"),size=0.5, se = FALSE) +
  geom_smooth(aes(y = p50, color = "Median"),size=0.5, se = FALSE) +
  labs(title = "Historical leverage levels per countries and firm sizes",
       caption = "Median represents p50 leverage of all firms",
    x = "", y = "Leverage by firm size class") +
  scale_color_viridis_d() +
  guides(color = guide_legend(title = "")) +
  theme_light()+
  theme(axis.text = element_text(size = 6),
        axis.title = element_text(size = 6))+
  facet_wrap(vars(country))#, scales = "free_y")

# by country and sizeclass
# ggplot(leverage_szcl_by_sz, aes(x = sector, y = p50, fill = factor(sizeclass))) + 
#   geom_bar(stat = "identity", position = "dodge") + 
#   labs(title = "Average p25 by Sizeclass and Sector")

# cash over total assets:
names(leverage_szcl)[which(names(leverage_szcl) == "FR01_cash_ta_p50")] <- "p50_cta" # median
cash_ta_szcl_by_sz <- leverage_szcl %>%
  mutate(l_p50_micro = if_else(sizeclass == 1, p50_cta, NA_real_),
         l_p50_small = if_else(sizeclass == 2, p50_cta, NA_real_),
         l_p50_medium = if_else(sizeclass == 3, p50_cta, NA_real_),    
         l_p50_large = if_else(sizeclass == 4, p50_cta, NA_real_),
         l_p50_big = if_else(sizeclass == 5, p50_cta, NA_real_))
# overal
ggplot(cash_ta_szcl_by_sz, aes(x = year)) +
  geom_smooth(aes(y = l_p50_micro, color = "1-9"), size=0.5, se = FALSE) +
  geom_smooth(aes(y = l_p50_small, color = "10-19"),size=0.5, se = FALSE) +
  geom_smooth(aes(y = p50_cta, color = "Median"),size=0.5, se = FALSE) +
  labs(title = "Historical cash over total assets levels by firm sizes",
       caption = "Median represents p50 cash/total assets of all firms",
       x = "", y = "Cash/total assets by firm size class") +
  scale_color_viridis_d() +
  theme_light()+
  theme(axis.text = element_text(size = 6),
        axis.title = element_text(size = 6))

# by country
ggplot(cash_ta_szcl_by_sz, aes(x = year)) +
  geom_smooth(aes(y = l_p50_micro, color = "1-9"), size=0.5, se = FALSE) +
  geom_smooth(aes(y = l_p50_small, color = "10-19"),size=0.5, se = FALSE) +
  geom_smooth(aes(y = p50_cta, color = "Median"),size=0.5, se = FALSE) +
    labs(title = "Historical cash over total assets levels per countries and firm sizes",
       caption = "Median represents p50 cash/total assets of all firms.",
       x = "", y = "Cash/total assets by firm size class") +
   scale_color_viridis_d() +
  theme_light()+
  guides(color = guide_legend(title = "")) +
  theme(axis.text = element_text(size = 5),
        axis.title = element_text(size = 5))+
  facet_wrap(vars(country))#, scales = "free_y")

# cashflow over total assets:
names(leverage_szcl)[which(names(leverage_szcl) == "FR02_cashflow_ta_p50")] <- "p50_cfta" # median
cashflow_ta_szcl_by_sz <- leverage_szcl %>%
  mutate(l_p50_micro = if_else(sizeclass == 1, p50_cfta, NA_real_),
         l_p50_small = if_else(sizeclass == 2, p50_cfta, NA_real_),
         l_p50_medium = if_else(sizeclass == 3, p50_cfta, NA_real_),    
         l_p50_large = if_else(sizeclass == 4, p50_cfta, NA_real_),
         l_p50_big = if_else(sizeclass == 5, p50_cfta, NA_real_))
# overal
ggplot(cashflow_ta_szcl_by_sz, aes(x = year)) +
  geom_smooth(aes(y = l_p50_micro, color = "1-9"), size=0.5, se = FALSE) +
  geom_smooth(aes(y = l_p50_small, color = "10-19"),size=0.5, se = FALSE) +
  geom_smooth(aes(y = p50_cfta, color = "Median"),size=0.5, se = FALSE) +
  labs(title = "Historical cashflow over total assets levels per countries and firm sizes",
       caption = "Median represents p50 cash/total assets of all firms",
       x = "", y = "Cashflow/total assets by firm size class") +
   scale_color_viridis_d() +
  guides(color = guide_legend(title = "")) +
  theme_light()+
  theme(axis.text = element_text(size = 5),
        axis.title = element_text(size = 5))

# by country
ggplot(cashflow_ta_szcl_by_sz, aes(x = year)) +
  geom_smooth(aes(y = l_p50_micro, color = "1-9"), size=0.5, se = FALSE) +
  geom_smooth(aes(y = l_p50_small, color = "10-19"),size=0.5, se = FALSE) +
  geom_smooth(aes(y = p50_cfta, color = "Median"),size=0.5, se = FALSE) +
  labs(title = "Historical cashflow over total assets levels per countries and firm sizes",
       caption = "Median represents p50 cashflow/total assets of all firms.",
       x = "", y = "Cashflow/total assets by firm size class") +
  scale_color_viridis_d() +
  theme_light()+
  guides(color = guide_legend(title = "")) +
  theme(axis.text = element_text(size = 5),
        axis.title = element_text(size = 5))+
  facet_wrap(vars(country))#, scales = "free_y")
