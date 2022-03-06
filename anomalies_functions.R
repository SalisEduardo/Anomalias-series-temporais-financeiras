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

#-----------------------------------------------------------
# FUNCTIONS


get.instruments <- function(tickers,start_date,end_date){
  # Obtem dados relativos a um ativo negociado no mercado financeiro atraves da API do yahoo 
  # obs: datas no formato "as.Date()"  , formato : "YYYY-MM-DD"
  
  # Captura dos dados
  instrum_data <- quantmod::getSymbols(tickers, src = "yahoo", from = start_date, to = end_date, auto.assign = FALSE)
  
  # Renomenado as colunas
  names(instrum_data) <- c("Open", "High", "Low", "Close", "Volume", "Ajustado")
  
  INSTRUMENT <- data.frame(instrum_data)
  
  # Calculando os retornos
  retornos <- PerformanceAnalytics::Return.calculate(data.frame(INSTRUMENT[,"Ajustado",drop=FALSE])) %>% 
    dplyr::rename(Retorno = Ajustado)
  
  
  INSTRUMENT <- cbind(INSTRUMENT,retornos)
  
  #INSTRUMENT$Retorno = INSTRUMENT$Retorno * 100
  INSTRUMENT$Retorno = INSTRUMENT$Retorno
  
  #data como coluna  (nao como index)
  Date <- rownames(INSTRUMENT)
  rownames(INSTRUMENT)  <- NULL
  INSTRUMENT <- cbind(Date, INSTRUMENT)
  
  INSTRUMENT
}

get.anomalies <- function(df, split_size=0.5,max_anoms = 0.05, direction='both',alpha = 0.05){
  
  # calcula as anomalias relativas a uma parte da serie financeira 
  
  # split size: tamanho da base de teste (onde se  calcula os dados das anomalias para depois esses serem usados em nas regras de tradig )
  # max_anoms: maximo numero de anomalias a serem detectadas pelo algoritmo
  # direction: direcao das anomalias
  # alpha : nivel de significancia estatistica para se rejeitar uma anomalia
  
  sub_df <- df[,c("Date","Retorno")]
  sub_df$Date <- as.POSIXct(sub_df$Date) #formato aceitavel de data
  
  
  #Criando serie temporal de anomalias do teste 
  test_size <- dim(df)[1]*split_size  
  anomalies_test <- AnomalyDetection::ad_ts(sub_df[1:test_size,], max_anoms = max_anoms, direction=direction,alpha = alpha)
  
  anomalies_test
}

plot.anomalies <- function(df,anomalies,color = "blue", instrument){
  sub_df <- df[,c("Date","Retorno")]
  sub_df$Date <- as.POSIXct(sub_df$Date)
  
  ggplot() +
    geom_line(
      data = sub_df, aes(Date, Retorno), 
      size = 0.125, color = color
    )  +
    geom_point(
      data = anomalies, aes(timestamp, anoms), color = "#cb181d", alpha = 1/3
    ) +
    #scale_x_datetime(date_labels = "%b/%y") +
    scale_y_comma() + 
    
    labs(x = "Periodo", y = "Retorno", 
         title = paste("Anomalias nos retornos - ", instrument))
  
}

strat_anoms <- function(instrument_series, anom_series, multiplier = 0.5,split_size = 0.5, trend= -1,return_validation = TRUE ){
  
  # a estrategia age conforme esse limite calculado pelo historico de anomalias
  
  
  anom_positive <- mean(data.matrix(anom_series[anom_series$anoms > 0,"anoms"]))*multiplier
  
  anom_negative <- mean(data.matrix(anom_series[anom_series$anoms < 0,"anoms"]))*multiplier
  
  test_size <- dim(instrument_series)[1]*split_size  
  
  test_series <- instrument_series[1:test_size,] 
  
  test_series$anoms <-  ifelse(test_series$Retorno > anom_positive, 1, 0)
  
  test_series$anoms <-  ifelse(test_series$Retorno < anom_negative, -1, test_series$anoms)
  
  test_series$Alvo <- data.table::shift(test_series$Retorno,-1)
  
  test_series[is.na(test_series)] <- 0
  
  #trend <- -1  revertendo a média ou em momentum 
  
  test_series$Resultado <- test_series$anoms*test_series$Alvo*(trend)
  
  #retorno_modelo_acumulado_TEST <- cumsum(test_series$Resultado)
  
  #test_series$ret_cum <- cumsum(test_series$Resultado)
  test_series$ret_cum <- cumprod(test_series$Resultado + 1) -1
  
  
  #VALIDATION
  
  # VALIDACAO
  
  validation_series <- instrument_series[(test_size+1):dim(instrument_series)[1],]
  
  validation_series$anoms <- ifelse(validation_series$Retorno > anom_positive, 1, 0)
  validation_series$anoms <- ifelse(validation_series$Retorno < anom_negative, -1, validation_series$anoms)
  
  # Criando o alvo
  validation_series$Alvo <- data.table::shift(validation_series$Retorno,-1)
  
  validation_series[is.na(validation_series)] <- 0
  
  validation_series$Resultado <-validation_series$anoms*validation_series$Alvo*(trend)
  
  
  #retorno_modelo_acumulado_VALIDATION <- cumsum(validation_series$Resultado)
  
  #validation_series$ret_cum <- cumsum(validation_series$Resultado)
  validation_series$ret_cum <- cumprod(validation_series$Resultado + 1) -1
  
  if(return_validation){
    #return(retorno_modelo_acumulado_VALIDATION)
    return(validation_series)
  }else{
    #return(retorno_modelo_acumulado_TEST)
    return(test_series)
  }
  
  
}

plot.returns.anom.strat <- function(df,sep_grupo="Teste"){
  ggplot(df, aes(x = as.Date(Date), ret_cum, group = 1)) +
    geom_line(color="BLue") +
    scale_x_date(date_labels = "%Y") + 
    labs(x = "Periodo", y = "Retorno em %", 
         title = paste("Retorno do Trading System Anomalia -", sep_grupo))
}

BnH_instrument <- function(df,split_size = 0.5) {
  df_buy_n_hold <- na.omit(df)[,c("Date","Retorno")]
  test_size <- dim(df_buy_n_hold )[1]* split_size
  df_buy_n_hold <- df_buy_n_hold [(test_size+1):dim(df_buy_n_hold)[1],]
  df_buy_n_hold$CumRet <- cumprod(df_buy_n_hold$Retorno + 1) -1
  
  return(df_buy_n_hold)
}

plot.BnH <- function(df_buy_n_hold){
  ggplot(df_buy_n_hold, aes(x = as.Date(Date), df_buy_n_hold$CumRet, group = 1)) +
    #geom_point() +
    geom_line(color="Red") +
    scale_x_date(date_labels = "%Y") + 
    labs(x = "Periodo", y = "Retorno", 
         title = "Retorno do Buy and Hold")
  
}

plot.strat_X_BnH <- function(val_series,BnH){
  ggplot() +
    geom_line(BnH, mapping = aes(x = as.Date(Date), y = BnH$CumRet, group = 1),color="red") +
    geom_line(val_series, mapping =  aes(x = as.Date(Date), y = ret_cum, group = 1),color="blue") + 
    labs(x = "Periodo", y = "Retorno", 
         title = "Buy and Hold X Anomalies Trading System")
  
}

rets_strat <- function(df,col_ret){
  df_retornos <- df[,c("Date",col_ret)]
  row.names(df_retornos) <- df_retornos$Date
  df_retornos$Date <- NULL
  df_retornos
  
}

plot.DD <- function(df,color="blue"){
  PerformanceAnalytics::chart.Drawdown(df,colorset=color)
}

