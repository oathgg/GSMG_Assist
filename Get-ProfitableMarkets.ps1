. "$curPath\Functions\binance_api.ps1"
. "$curPath\Functions\gsmg_api.ps1"
. "$curPath\Functions\Converters.ps1"
. "$curPath\Functions\Tools.ps1"
. "$curPath\parameters.ps1"

Clear-Host
$markets = Get-GSMGMarkets
$profitableMarkets = $markets | Where-Object {$_.exchange_comments -ne "BREAK" -and $_.base_currency -match "BUSD" -and $_.market_knowledge_b.mtp_pct -gt 5 } | Sort-Object {$_.market_knowledge_b.mtp_pct} -Descending 
$count = 0

foreach ($pm in $profitableMarkets) {
    $marketName = $pm.market_name
    [float] $pctChange24h = (Get-24hTicker($marketName)).priceChangePercent

    if ($pctChange24h -gt -10 -and $pctChange24h -lt 15) {
        [float] $pctChangeFromATH = Get-AthChangePct -Market $marketName -Interval "1d" -CandleLimit 30 -IncludeCurrentCandle
        if ($pctChangeFromATH -le -15) {
            $count++
            $pm | Select-Object Market_name, market_knowledge_b
        }
    }

    if ($count -eq 10) {
        break;
    }
}

#$profitableMarkets | Select-Object -First 10 | Select-Object Market_name, market_knowledge_b
