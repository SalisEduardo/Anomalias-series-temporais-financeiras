
# pacotes

import pandas as pd
import numpy as np
from datetime import datetime
import matplotlib.pyplot as plt
import investpy as inv


inicio = "01/01/2015"
fim = "17/01/2022"


crypto = inv.get_crypto_historical_data(crypto = "Bitcoin"
                                     , from_date = inicio
                                     , to_date = fim)
crypto.to_csv("BTC_prices.csv")