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

$global:MaxAllocationPct = @{
    "BUSD"=20;
    "BTC"=100
}
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
    "TRXBUSD",

    #BTC
    "ETHBTC",
    "TROYBTC",
    "IOTXBTC"
)
```