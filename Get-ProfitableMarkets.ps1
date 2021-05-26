$curPath = $PSScriptRoot
if (-not $curPath) {
    $curPath = $psise.CurrentFile.FullPath
}

. "$curPath\Functions\gsmg_api.ps1"
. "$curPath\parameters.ps1"

Clear-Host
$markets = Get-GSMGMarkets
$profitableMarkets = $markets | Where-Object {$_.exchange_comments -ne "BREAK" -and $_.base_currency -match "BUSD" -and $_.market_knowledge_b.mtp_pct -gt 5 } | Sort-Object {$_.market_knowledge_b.mtp_pct} -Descending 
$profitableMarkets | Select-Object -First 10 -Property Market_name, market_knowledge_b