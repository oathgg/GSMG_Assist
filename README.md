# GSMG_Assist
Assist for the GSMG tool.

Parameter file should look like

```
# GSMG API
$global:GSMGEmail = "xxxxxxxxxxx@xxxxx.com"
$global:GSMGPassword = 'xxxxxxxxxxx'
$global:GSMGStrategy = "Simple" # Name of the strategy file which is located in '\strategies'

# Market settings
$global:MaxAllocationPct = @{
    "BUSD"=20;
    "BTC"=100
}
$global:DoGetLatest = $false # if you support github you can enable this 

# These markets will not be touched so you can still control these manually
$global:MarketsToIgnore = @(
    "BTCBUSD"
    "ADABUSD"
)

```