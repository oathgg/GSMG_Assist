# GSMG_Assist
Assist for the GSMG tool.

Parameter file should look like

```
#Binance API
$global:binanceKey = "xxxxxxxxxxxxxxxxxxx"
$global:binanceSecret = "xxxxxxxxxxxxxxxxxxxx"

$global:GSMGEmail = "xxxx@gmail.com"
$global:GSMGPassword = "xxxxx"
$global:GSMGStrategy = "xxxxx" #File should be located in the "Strategies" folder. The name of the file is enough, u dont have to add the extension.

$global:MaxAllocationPct = 20
$global:MarketsToScan = @(
    #BUSD
    "BNBBUSD", 
    "XLMBUSD", 
    "ADABUSD",
    "SYSBUSD",
    "HBARBUSD",
    "ROSEBUSD",
    "XRPBUSD",
    "VETBUSD",
    "CAKEBUSD",
    "UNIBUSD",

    #BTC
    "ETHBTC",
    "TROYBTC",
    "IOTXBTC"
)
$global:MaxMarketCount = 10
```