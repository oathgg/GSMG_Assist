$curPath = $PSScriptRoot
if (-not $curPath) {
    $curPath = $psise.CurrentFile.FullPath
}

. "$curPath\Functions\binance_api.ps1"
. "$curPath\Functions\gsmg_api.ps1"
. "$curPath\parameters.ps1"

Clear-Host
$markets = Get-GSMGMarkets
$profitableMarkets = $markets | Where-Object {$_.exchange_comments -ne "BREAK" -and $_.base_currency -match "BUSD" -and $_.market_knowledge_b.mtp_pct -gt 5 } | Sort-Object {$_.market_knowledge_b.mtp_pct} -Descending 
$count = 0

foreach ($pm in $profitableMarkets) {
    $marketName = $pm.market_name
    $pm | Select-Object Market_name, market_knowledge_b

    if ($count++ -eq 10) {
        break;
    }
}