"
In this script we try to replicate the Stata regressions on firm resilience 
and add some principal component analysis.

We construct 3 PC and test them in the regression. 

As I am getting uncertain on the robustness of our assumption, I also tried to 
not weight PCs by the exposure. 
  Could try to lag them and/or aggregate in one single PC.
  Otherwise, use it to establish that we regress only on ELECTR, NATGAS 
  and PC1.

Results so far seem unconclusive.

" 

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
prices <- as.data.table(read_dta("/Users/lauralehtonen/Desktop/CompNet/CompNet Data/Energy research/Energy_price_mix_TJ_IEA_Eurostat.dta"))

compnet_data <- "/Users/lauralehtonen/Desktop/CompNet/CompNet Data/9th vintage/Data files/"

outdir <- "/Users/lauralehtonen/Desktop/CompNet/CompNet Data/Energy research/Output/"

library(data.table)
library(ggplot2)
theme_set(theme_classic())
library(ggpubr)
library(readr)
library(corrr)
library(FactoMineR)
library(factoextra)
library(plm)
library(lmtest)
library(sandwich)
library(readxl)
library(ggthemes)

#compnet_data <- "C:/Users/a_zon/Dropbox/PHD VU/6_Energy/Energy regressions/"
#setwd("C:/Users/a_zon/Dropbox/PHD VU/6_Energy/Energy regressions/") 
#outdir <- paste0(compnet_data,"reg_tables/R/")

#prices <- as.data.table(read_xls("C:/Users/a_zon/OneDrive/CompNet Main Directory/17_TSI/Research/Collaboration with NPBs/4. Energy/Data/Energy_price_mix_TJ_IEA_Eurostat.xls",
                                 sheet = "Sheet1", col_names = T, col_types = "text"))

prices[, c(5:36):= lapply(.SD, as.numeric), .SDcols = c(names(prices)[5:36])]
setkeyv(prices, c("country", "industry2d", "year"))

prices[,mac_sector:=0]
prices[industry2d>=10 & industry2d<34, mac_sector := 1]
prices[industry2d>=41 & industry2d<44, mac_sector := 2]
prices[ industry2d>=45 & industry2d<48, mac_sector := 3]
prices[ industry2d>=49 & industry2d<54, mac_sector := 4]
prices[ industry2d>=55 & industry2d<=56, mac_sector := 5]
prices[ industry2d>=58 & industry2d<64, mac_sector := 6]
prices[ industry2d==68, mac_sector := 7]
prices[ industry2d>=69 & industry2d<76, mac_sector := 8]
prices[ industry2d>=77 & industry2d<=82, mac_sector := 9]
prices <- prices[mac_sector != 0]

#### STEP 1 #### ---------------------------------------------------------------

srcs <- c("DIESEL", "ELECTR", "FUEL_OIL", 
          "NATGAS", "GASOLINE") # exclude OTHPETRO and gain lots of countries

# run PCA
data <- prices[, c(names(prices)[1:3], 
                   paste0(srcs,"_Price_afterTax"), "mac_sector"), with=F]
data <- data[, num_NA := rowSums(is.na(.SD)),
             .SDcols = paste0(srcs,"_Price_afterTax")]
data <- data[num_NA == 0][, num_NA := NULL]

# will do a manual standardization
# should I standardize over time or across countries? 

# for(v in paste0(srcs,"_Price_afterTax")){
#   
#   data[, mean := mean(get(v),na.rm=T),
#        by = .(country)]
#   data[, sd := sd(get(v),na.rm=T),
#        by = .(year,mac_sector)]
#   data[, c(paste0(v,"_std")) := (get(v) - mean )/sd]
#   
# }
# data <- data[, lapply(.SD, function(x)ifelse(is.infinite(x)|is.nan(x),NA,x))]

setnames(data, paste0(srcs,"_Price_afterTax"), srcs)
pca <- prcomp(data[,c(srcs),with=F],center = T, scale=T)
#Props of variance
summary(pca)
#Eigenvalues
pca$sdev^2 
#Eigenvectors: 
pca$rotation

# visualize the components
fviz_pca_var(pca, c(1,2))

fviz_eig(pca, addlabels = TRUE, 
         barfill = "#1A476F", barcolor = "#1A476F", main=" ") +
  theme_stata(scheme = "s2color") +
  theme(
    plot.background = element_rect(fill = "white"),
    panel.background = element_rect(fill = "white"),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank())
ggsave(paste0(outdir,"PCA_Panel_A.pdf"), width = 8, height = 8)


ggarrange(fviz_cos2(pca, choice = "var", axes = 1),
          fviz_cos2(pca, choice = "var", axes = 1:2),
          fviz_cos2(pca, choice = "var", axes = 1:3), nrow = 1)
fviz_pca_var(pca, col.var = "cos2",axes = c(1,2),
             gradient.cols = c("black", "orange", "green"),
             repel = TRUE)

# contrib of prices to each component (used later)
contrib <- get_pca_var(pca)$contrib[,1:3]
contrib

# make a smaller dataset
pcl <- pca$rotation[,1:3]
data.mat <- data.matrix(data[,c(srcs),with=F], rownames.force = NA)
pcdata <- t(t(pcl) %*% t(data.mat))
pcdata <- data.table(country = data$country,
                     year = data$year,
                     industry2d = data$industry2d,
                     PC1 = pcdata[,1],
                     PC2 = pcdata[,2],
                     PC3 = pcdata[,3])
rm(data, pcl)

# some trends and distributions
data4chart <- melt(pcdata, id.vars = c("country","industry2d","year"))
ggplot(data4chart[, mean(value), by =.(variable,year)],
       aes(x=as.numeric(year),y=V1,color=variable)) + geom_line() +theme_classic()
ggplot(data4chart, aes(x=value,color=variable,fill=variable)) + 
  geom_density() + theme_classic()
rm(data4chart)

# now I need to match with quantities used so to compute weights.

pca.weights <- prices[, c(names(prices)[1:3], srcs), with = F]
pca.weights.mat <- data.matrix(pca.weights[,c(srcs),with=F], 
                               rownames.force = NA)

for(i in 1:3){
  c <- contrib[,i]/100
  w <- pca.weights.mat %*% c
  pca.weights[, c(paste0("PC",i,"_w")):= w]
}

rm(pca.weights.mat,c,w)
data4chart <- melt(pca.weights[, c("country","industry2d","year",
                                   "PC1_w","PC2_w","PC3_w"), with=F], 
                   id.vars = c("country","industry2d","year"))
ggplot(data4chart[year %in% c(2007:2016), mean(value,na.rm=T),by=.(year,variable)],
       aes(x=as.numeric(year), y=V1,color=variable)) + geom_line()

pcdata <- merge(pcdata, pca.weights, by = c("country","industry2d","year"))
setnames(pcdata, srcs, paste0(srcs, "_Price_afterTax"))
pcdata <- merge(pcdata, prices[, c(c("country","industry2d","year","mac_sector","TOTAL","RENEWABLES_NUCLEAR"),srcs),with=F], 
                by = c("country","industry2d","year"))

# Compute weighted price shock
pcdata[, cov := rowSums(.SD,na.rm=T) / TOTAL, .SDcols = srcs]
pcdata <- pcdata[!is.na(cov)]

pc <- c("PC1","PC2","PC3")
setkeyv(pcdata, c("country","industry2d","year"))
for(s in pc){
  
  # lagged weight
  pcdata[, c(paste0("w_",s)) := get(paste0(s,"_w")) / TOTAL]
  pcdata[, c(paste0("l1_w_",s)) := shift(get(paste0("w_",s)),1,NA,"lag"), 
         by = .(industry2d,country)]
  
  # % changes in 'prices'
  pcdata[, c(paste0("Dp_",s)) := (get(s) - shift(get(s),1,NA,"lag")) / shift(get(s),1,NA,"lag"),
         by = .(industry2d,country)]
  pcdata[, c(paste0("Dp_",s)) := ifelse(is.nan(get(paste0("Dp_",s))) | is.infinite(get(paste0("Dp_",s))),
                                         NA, get(paste0("Dp_",s)))]
  
  # weighted change
  pcdata[, c(paste0("w_Dp_",s)) := get(paste0("Dp_",s)) * get(paste0("l1_w_",s))]
  
}

data4chart <- melt(pcdata[, c("country","industry2d","year",
                                   paste0("Dp_",pc),paste0("w_Dp_",pc)), with=F], 
                   id.vars = c("country","industry2d","year"))
data4chart[substr(variable,1,3)=="Dp_", type := "Dp"]
data4chart[substr(variable,1,5)=="w_Dp_", type := "w_Dp"]

ggplot(data4chart[year %in% c(2007:2016), mean(value,na.rm=T),by=.(year,variable,type)],
       aes(x=as.numeric(year), y=V1,color=variable, linetype=type)) + geom_line() +
  geom_hline(yintercept = 0, alpha =.5, linetype = "dashed")


#### STEP 2 #### ---------------------------------------------------------------

# Regressions

# will do a table with each source separately and then with PC

DT <- as.data.table(read_dta(paste0(compnet_data,"unconditional_industry2d_20e_weighted.dta")))
pcdata[, industry2d := as.numeric(industry2d)]
pcdata[, year := as.numeric(year)]
DT <- merge(DT,pcdata, by = c("country","industry2d","year"))

DT[, ener_eff := TOTAL / (FV18_rva_mn * FV18_rva_sw )]
DT[, green_sh := RENEWABLES_NUCLEAR / TOTAL]

depvar_diff <- c("FR40_ener_costs_mn","TR02_exp_adj_rev_mn",
                 "FR37_invest_k_mn","FR22_profitmargin_mn",
                 "ener_eff", "green_sh")
setkeyv(DT, c("country","industry2d","year"))
DT[, c(paste0("d_",depvar_diff)) := lapply(.SD,function(v){
  
  v = v - shift(v,1,NA,"lag")
  v = ifelse(is.nan(v)|is.infinite(v),NA,v)
  
}), .SDcols = depvar_diff, by = .(industry2d,country)]


for(v in depvar_diff){
  
  p <- ggplot(DT[, mean(get(paste0("d_",v)), na.rm=T), by = .(country,year)],
         aes(x = year, y = V1, color=country)) + 
    geom_line() + labs(title=paste0("d_",v)) + geom_hline(yintercept = 0,alpha=0.5,linetype=3)
  print(p)
  
}

# profitmargin and investment rate have some big outliers, will do some cleaning
vars2winsorize <- c("d_FR22_profitmargin_mn", "d_FR37_invest_k_mn")
DT[, c(vars2winsorize) := lapply(.SD,function(x){
  x = ifelse(x < quantile(x,.01,na.rm=T) | 
           x > quantile(x,.99,na.rm=T),
         NA, x)
}),by = .(year, mac_sector), .SDcols = vars2winsorize]

# change sign of jdr (it's all negative values)
DT[, LV15_jdr_pop_2D_tot_old := LV15_jdr_pop_2D_tot]
DT[, LV15_jdr_pop_2D_tot := - LV15_jdr_pop_2D_tot]
DT[, ID:=.GRP,by=list(country,industry2d)]

write_dta(DT, paste0(compnet_data,"data_afterPCA.dta"))

"Run until the line above, regressions are done in Stata"

# ##### regressions
# 
# depvar <- c("d_FR22_profitmargin_mn", "LV15_jdr_pop_2D_tot","d_FR40_ener_costs_mn","d_ener_eff",
#             "TR02_exp_adj_rev_mn","d_FR37_invest_k_mn","d_green_sh")
# headers <- c("profitability", "job destruction rate", "share energy cost", "energy / va", 
#              "export intensity", "investment rate", "green share")
# controls <- c("LV21_l_mn", "FV08_nrev_mn", "CE44_markup_0_mn","FR40_ener_costs_mn",
#               "FR22_profitmargin_mn")                           
# 
# # 1) PC unweighted
# 
# mms <- lapply(depvar, function(y){
#   
#   controls <- if(y == "d_FR22_profitmargin_mn") controls[controls != "FR22_profitmargin_mn"] else controls
#   f <- paste0(y,"~ Dp_PC1 + Dp_PC2 + Dp_PC3 ",
#               " + as.factor(year) + ",
#               paste(controls,collapse = " + "))
#   res <- plm(as.formula(f), data = DT, 
#       index = c("ID","year"),
#       model = "within",
#       weights = LV21_l_sw)
#   # res.clust <- coeftest(res,vcovHC(res,cluster = "group"))
#   # res.clust <- coeftest(res,cluster.vcov(res,cluster = DT$ID))
#   return(res)
#   
# })
# 
# stargazer(mms, type = "text", 
#           column.labels = headers,
#           notes = c("Clustered std. errors at the country-industry level."),
#           omit = c("as\\.factor\\(year\\)"),
#           covariate.labels = c("\\% ch. PC1","\\% ch. PC2","\\% ch. PC3",
#                                "Num. Firms", "Avg. Firm Size", "Avg. Revenues",
#                                "Avg. Markup"),
#           add.lines=list(c('Year Fixed effects', rep("Yes",length(mms)))),
#           out = paste0(outdir,"main_reg_noweigh.txt"))
# 
# # 2) PC weighted
# 
# mms <- lapply(depvar, function(y){
#   
#   controls <- if(y == "d_FR22_profitmargin_mn") controls[controls != "FR22_profitmargin_mn"] else controls
#   f <- paste0(y,"~ w_Dp_PC1 + w_Dp_PC2 + w_Dp_PC3 ",
#               " + as.factor(year) + ",
#               paste(controls,collapse = " + "))
#   res <- plm(as.formula(f), data = DT, 
#              index = c("ID","year"),
#              model = "within",
#              weights = LV21_l_sw)
#   # res.clust <- coeftest(res,vcovHC(res,cluster = "group"))
#   
#   return(res)
#   
# })
# 
# stargazer(mms, type = "text", 
#           column.labels = headers,
#           notes = c("Clustered std. errors at the country-industry level."),
#           omit = c("as\\.factor\\(year\\)"),
#           covariate.labels = c("\\% ch. PC1","\\% ch. PC2","\\% ch. PC3",
#                                "Num. Firms", "Avg. Firm Size", "Avg. Revenues",
#                                "Avg. Markup"),
#           add.lines=list(c('Year Fixed effects', rep("Yes",length(mms)))),
#           out = paste0(outdir,"main_reg_weigh.txt"))
# 
# # se = lapply(mms,function(m)diag(sqrt(vcovHC(m,cluster = "group"))))
# 
# # 3) PC unweighted - remove PC3
# 
# mms <- lapply(depvar, function(y){
#   
#   controls <- if(y == "d_FR22_profitmargin_mn") controls[controls != "FR22_profitmargin_mn"] else controls
#   f <- paste0(y,"~ Dp_PC1 + Dp_PC2 ",
#               " + as.factor(year) + ",
#               paste(controls,collapse = " + "))
#   res <- plm(as.formula(f), data = DT, 
#              index = c("ID","year"),
#              model = "within",
#              weights = LV21_l_sw)
#   # res.clust <- coeftest(res,vcovHC(res,cluster = "group"))
#   
#   return(res)
#   
# })
# 
# stargazer(mms, type = "text", 
#           column.labels = headers,
#           notes = c("Clustered std. errors at the country-industry level."),
#           omit = c("as\\.factor\\(year\\)"),
#           covariate.labels = c("\\% ch. PC1","\\% ch. PC2",
#                                "Num. Firms", "Avg. Firm Size", "Avg. Revenues",
#                                "Avg. Markup"),
#           add.lines=list(c('Year Fixed effects', rep("Yes",length(mms)))),
#           out = paste0(outdir,"main_reg_noweigh_noPC3.txt"))
# 
# # 4) PC weighted - remove PC3
# 
# mms <- lapply(depvar, function(y){
#   
#   controls <- if(y == "d_FR22_profitmargin_mn") controls[controls != "FR22_profitmargin_mn"] else controls
#   f <- paste0(y,"~ w_Dp_PC1 + w_Dp_PC2 ",
#               " + as.factor(year) + ",
#               paste(controls,collapse = " + "))
#   res <- plm(as.formula(f), data = DT, 
#              index = c("ID","year"),
#              model = "within",
#              weights = LV21_l_sw)
#   # res.clust <- coeftest(res,vcovHC(res,cluster = "group"))
#   
#   return(res)
#   
# })
# 
# stargazer(mms, type = "text", 
#           column.labels = headers,
#           notes = c("Clustered std. errors at the country-industry level."),
#           omit = c("as\\.factor\\(year\\)"),
#           covariate.labels = c("\\% ch. PC1","\\% ch. PC2",
#                                "Num. Firms", "Avg. Firm Size", "Avg. Revenues",
#                                "Avg. Markup"),
#           add.lines=list(c('Year Fixed effects', rep("Yes",length(mms)))),
#           out = paste0(outdir,"main_reg_weigh_noPC3.txt"))
