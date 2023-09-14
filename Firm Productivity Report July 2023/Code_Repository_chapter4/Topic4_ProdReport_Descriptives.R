################################################
# Topic 4 - Productivity Report - Descriptives #
###############################################

#In this R-script, the evolution of energy mix (country, macro-sector) is created
#For the creation of median energy intensity and evolution of energy prices, please refer 
# to the do-file "Topic4_ProdReport_Descriptives"

#1. Evolution of average energy mix: distinguishing between energy types or renewables /non-renewables
rm(list = ls())

#Set working directory
getwd()
setwd("/Users/lauralehtonen/Desktop/CompNet/CompNet Data/Energy research/")

#Open packages
library(data.table)
library(ggplot2)
library(readxl)
library(haven)
library(ggpubr)
library(ggthemes)
library(scales)

# import data
DT <- as.data.table(read_dta("/Users/lauralehtonen/Desktop/CompNet/CompNet Data/Energy research/Energy_price_mix_TJ_IEA_Eurostat.dta"))

outdir <- "/Users/lauralehtonen/Desktop/CompNet/CompNet Data/Energy research/Output/"

#A. Energy mix per country
  ##i. combine gasoline + fuel-oil + diesel
    DT[, FOSSIL_FUELS := sum(DIESEL, GASOLINE, FUEL_OIL, na.rm=TRUE), by = .(country, year, industry2d)]
    DT1 <- DT[, -c("DIESEL", "GASOLINE", "FUEL_OIL")]
    DT1 <- DT1[,-c(16:33)]  
    DT1 <- DT1[country!="Croatia"]  
   
    
  ##ii. Energy mix shares
    ener_src <- names(DT1)[5:16]
  print(ener_src)
    DT1[, c(paste0("sh_",ener_src)) := lapply(.SD,function(x)x/TOTAL), .SDcols = ener_src]
    data <- DT1[, lapply(.SD,mean,na.rm=T),.SDcols = c(paste0("sh_",ener_src)), by = .(country,year)]
    data[,c(names(data)):=lapply(.SD, function(v)ifelse(is.nan(v)|is.infinite(v),NA,v)), .SDcols=names(data)]
    data <- melt(data,id.vars = c("country","year"))
    data[, variable := gsub("sh_","",variable)]
    data <- data[year>=2007 & year<=2016]
    
  ##iii. combine shares of gasoline + fuel-oil + diesel
  data1 <- data
  data1 <- data1[variable %in% c("ELECTR", "FOSSIL_FUELS", "NATGAS")]
  
  #Rename variable names
  data1[, variable := ifelse(variable == "ELECTR", "Electricity",
                   ifelse(variable == "NATGAS", "Natural_gas",
                                 ifelse(variable == "FOSSIL_FUELS", "Fossil_fuels", variable)))]
## New plots
  show_col(stata_pal("s2color")(15))
  stata_pal(scheme = "s2color")
  
  my_colors <- c("#1a476f", "#90353b", "#55752f")
  
  ggplot(data1, aes(x=year, y=value, fill=variable)) + 
    geom_area()+
    scale_fill_manual(values=my_colors)+
    labs(x = "",
         y = "",)+
    theme_light()+
    theme_stata(scheme = "s2color")+
    theme(axis.text = element_text(size = 7),
          axis.title = element_text(size = 7),
          legend.title= element_text(color= "black", size=8),
          legend.text=element_text(color = "black", size=8),
          legend.position="bottom",
          plot.title = element_text(hjust = 0.5, size=10),
          strip.text = element_text(color = "black", size = 10, face= "bold"),
          strip.background = element_blank(),
          plot.background = element_rect(fill ="white"),
          panel.background = element_rect(fill ="white"),
          panel.grid.minor = element_blank(),
          panel.grid.major.x = element_blank())+
    facet_wrap(vars(country), scales = "free")+
    guides(fill=guide_legend(title="Energy type")) +
    expand_limits(y = c(0, 1))
  ggsave(paste0(outdir,"energymix_all_shares_new.pdf"), width = 8, height = 8)
  

##B. By macro-sector, averaging over countries
DT2 <- as.data.table(read_excel("/Users/lauralehtonen/Desktop/CompNet/CompNet Data/Energy research/Energy_price_mix_TJ_IEA_Eurostat_macro-sector.xls"))

DT2[, FOSSIL_FUELS := sum(DIESEL, GASOLINE, FUEL_OIL, na.rm=TRUE), by = .(country, year, mac_sector)]
DT3 <- DT2[, -c("DIESEL", "GASOLINE", "FUEL_OIL")]
DT3 <- DT3[,-c(15:32)]  
DT3 <- DT3[country!="Croatia"]   

##ii. Energy mix shares
ener_src <- names(DT3)[4:15]
print(ener_src)
DT3[, c(paste0("sh_",ener_src)) := lapply(.SD,function(x)x/TOTAL), .SDcols = ener_src]
data2 <- DT3[, lapply(.SD,mean,na.rm=T),.SDcols = c(paste0("sh_",ener_src)), by = .(mac_sector,year)]
data2[,c(names(data2)):=lapply(.SD, function(v)ifelse(is.nan(v)|is.infinite(v),NA,v)), .SDcols=names(data2)]
data2 <- melt(data2,id.vars = c("mac_sector","year"))
data2[, variable := gsub("sh_","",variable)]
data2 <- data2[year>=2007 & year<=2016]

###iii. combine shares of gasoline + fuel-oil + diesel
data3 <- data2
data3 <- data2[variable %in% c("ELECTR", "FOSSIL_FUELS", "NATGAS")]

#Rename variable names
data3[, variable := ifelse(variable == "ELECTR", "Electricity",
                           ifelse(variable == "NATGAS", "Natural_gas",
                                         ifelse(variable == "FOSSIL_FUELS", "Fossil_fuels", variable)))]

#Energy mix shares
show_col(stata_pal("s2color")(15))
stata_pal(scheme = "s2color")

my_colors <- c("#1a476f", "#90353b", "#55752f")

#Rename macro-sectors
data3[, mac_sector := ifelse(mac_sector == "1", "1 - Manufacturing",
                        ifelse(mac_sector == "2", "2 - Construction",
                          ifelse(mac_sector == "3", "3 - Wholesale and retail trade",
                            ifelse(mac_sector == "4", "4 - Transportation and storage",
                              ifelse(mac_sector == "5", "5 - Accommodation and food service",
                                ifelse(mac_sector == "6", "6 - Information and communication",
                                  ifelse(mac_sector == "7", "7 - Real estate",
                                    ifelse(mac_sector == "8", "8 - Professional scientific and technical",
                                     ifelse(mac_sector == "9", "9 - Administrative and support service", mac_sector)))))))))]

ggplot(data3, aes(x=year, y=value, fill=variable)) + 
  geom_area()+
  scale_fill_manual(values = my_colors)+
  ggtitle("")+
  labs(x = "",
       y = "") +
  ylim(c(0,1))+
  theme_light()+
  theme_stata(scheme = "s2color")+
  theme(axis.text = element_text(size = 7),
        axis.title = element_text(size = 7),
        legend.title= element_text(color= "black", size=8),
        legend.text=element_text(color ="black", size=8),
        legend.position="bottom",
        plot.title = element_text(hjust = 0.5, size=10),
        plot.caption = element_text(size=7), 
        strip.text = element_text(color = "black", size = 6.5, face= "bold"),
        strip.background = element_blank(),
        plot.background = element_rect(fill ="white"),
        panel.background = element_rect(fill ="white"),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank())+
  facet_wrap(vars(mac_sector), scales = "free")+
  guides(fill=guide_legend(title="Energy type"))
ggsave(paste0(outdir,"energymix_macro_shares_new.pdf"), width = 8, height = 8)


ggplot(data3, aes(x=year, y=value, fill=variable)) + 
  geom_area()+
  scale_fill_manual(values = my_colors)+
  ggtitle("")+
  labs(x = "",
       y = "") +
  ylim(c(0,1))+
  theme_stata(scheme = "s2color")+
  theme(
    plot.background = element_rect(fill = "white"),
    panel.background = element_rect(fill = "white"),
    panel.grid.minor = element_blank(),
    legend.text=element_text(color ="black"))+
  facet_wrap(vars(mac_sector), scales = "free")+
  guides(fill=guide_legend(title="Energy type"))


ggplot(data2, aes(x=year, y=value, fill=variable)) + 
  geom_area()+
  ggtitle("")+
  labs(x = "",
       y = "") +
  theme_light()+
  theme(axis.text = element_text(size = 7),
        axis.title = element_text(size = 7),
        legend.title= element_text(size=8),
        legend.text=element_text(size=7),
        legend.position="bottom",
        plot.title = element_text(hjust = 0.5, size=10),
        plot.caption = element_text(size=7), 
        strip.text = element_text(color = "black", size = 6.5, face= "bold"),
        strip.background = element_blank()) + 
  facet_wrap(vars(mac_sector), scales = "free")+
  guides(fill=guide_legend(title="Energy type"))
ggsave(paste0(outdir,"energymix_macro_shares_new.pdf"), width = 8, height = 8)


#######
# END #
#######

