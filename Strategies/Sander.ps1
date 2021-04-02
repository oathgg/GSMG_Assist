while ($true) {
    cls

    $markets = Get-GSMGMarkets
    foreach ($market in $markets) {
        $marketName = $market.market_name.Replace("Binance:", "")
        $market24hInformation = Query-24hTicker($marketName)
        $24hPriceChange = [float] $market24hInformation.priceChange
        $bagPct = [float] $market.vol_sells_worth / ([float] $market.managed_value_usd / 100)

        if ($bagPct -le 40 -and $24hPriceChange -le 0) {
            Set-GSMGSetting -Market $marketName -BemPct 2
        } else {
            Set-GSMGSetting -Market $marketName -BemPct 0
        }
    }

    Write-Host "Sleeping for 60 seconds before updating information again..."
    Sleep -Seconds 60
}