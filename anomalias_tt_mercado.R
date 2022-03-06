#Inspiração - OMNP (Leandro Guerra)

#-------------------------------------------------------------
setwd("~/Documentos/fea_dev/Anomalias_mercado")
library(quantmod)
library(AnomalyDetection)
library(hrbrthemes)
library(ggplot2)
library(PerformanceAnalytics)
library(data.table)
library(anomalize)
library(coindeskr)
library(cowplot)

options(warn = -1) 
source("anomalies_functions.R")

#---------------------------------------------------------------------------------------------------------------------------------

# Estrategia trading com base em anomalias da ambev



abev <- get.instruments("ABEV", as.Date("2009-01-01"), as.Date("2019-09-30"))
anom_abev <- get.anomalies(abev)
graf_anom_abev <- plot.anomalies(abev,anom_abev,instrument = "ABEV")

abev_buy_n_hold <- BnH_instrument(abev,split_size = 0.5)
grafico_abev_BnH <- plot.BnH(abev_buy_n_hold)

test_abev <- strat_anoms(abev,anom_abev,trend = -1,return_validation = FALSE)
validation_abev <- strat_anoms(abev,anom_abev,trend = -1,return_validation = TRUE)


grafico_teste_abev <- plot.returns.anom.strat(test_abev)
grafico_validacao_abev <- plot.returns.anom.strat(validation_abev,sep_grupo = "Validacao")

plot.strat_X_BnH(validation_abev, abev_buy_n_hold)



dd_start_abev <- plot.DD(validation_abev,color='blue')

data(managers)
SharpeRatio(managers[,1,drop=FALSE], Rf=.035/12, FUN="StdDev") 


#---------------------------------------------------------------------------------------------------------------------------------




# Estrategia trading com base em anomalias do bitcoin

# btc <- get.instruments("BTC-USD", as.Date("2015-01-01"), as.Date("2022-01-17"))
# 
# anom_btc <- get.anomalies(btc)
# 
# grafico_anom_btc <- plot.anomalies(btc,get.anomalies(btc),instrument = "BTC")
# 
# test_btc <- strat_anoms(btc,anom_btc,trend = 1,return_validation = FALSE)
# 
# validation_btc <- strat_anoms(btc,anom_btc,trend = -1,return_validation = TRUE)
# 
# grafico_teste_btc <- plot.returns.anom.strat(test_btc)
# 
# grafico_validacao_btc <- plot.returns.anom.strat(validation_btc,sep_grupo = "Validacao")

#-------------------------------------------------------------------------------------------------------------------------------

# Anomalies and Social media data


#btc_internet_data <- read.csv("bitcoin_internet.csv")
#btc_internet_data$date <- as.POSIXct(btc_internet_data$date)

btc_tt_sentiment <- read.csv("btc_tt_sentiment.csv")
btc_tt_sentiment$Date <- as.POSIXct(btc_tt_sentiment$Date)


btc <- get.instruments("BTC-USD", as.Date("2014-03-05"), as.Date("2022-02-20"))

anom_btc <- get.anomalies(btc,split_size = 1.0)

grafico_anom_btc <- plot.anomalies(btc,anom_btc,instrument = "BTC")

## ploting Sentiment Score

ggplot(btc_tt_sentiment,aes(Date,compound_polarity_scores)) + 
  geom_line(color='blue')




