# GSMG_Assist
Assist for the GSMG tool.

Parameter file should look like

```powershell
# GSMG API
$global:GSMGEmail = "xxxxxxxxxxx@xxxxx.com"
$global:GSMGPassword = 'xxxxxxxxxxx'
$global:GSMGStrategy = "Simple" # Name of the strategy file which is located in '\strategies'

# Market settings
$global:MaxAllocationPct = @{}

# if you support github you can enable this 
$global:DoGetLatest = $false 

# These markets will not be touched so you can still control these manually
$global:MarketsToIgnore = @()
```

A sample would look like
```powershell
# GSMG API
$global:GSMGEmail = "sander@gmail.com"
$global:GSMGPassword = 'VerySecurePassword123'
$global:GSMGStrategy = "Simple" # Name of the strategy file which is located in '\strategies'

# Market settings
$global:MaxAllocationPct = @{
    "BUSD"=20,
    "BTC"=50
}

# if you support github you can enable this 
$global:DoGetLatest = $true 

# These markets will not be touched so you can still control these manually
$global:MarketsToIgnore = @(
    "BTCBUSD"
    "ADABUSD"
)
```