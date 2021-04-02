$markets = Get-GSMGMarkets
foreach ($market in $markets) {
    $marketName = $market.market_name.Replace("Binance:", "")
    $market24hInformation = Query-24hTicker($marketName)
    $24hPriceChange = [float] $market24hInformation.priceChangePercent
    $bagPct = [float] $market.vol_sells_worth / ([float] $market.managed_value_usd / 100)

    if ($bagPct -le 60 -and $24hPriceChange -le 2) {
        Set-GSMGSetting -Market $marketName -BemPct "2"
    } elseif ($bagPct -gt 60 -and $24hPriceChange -le -12) {
        Set-GSMGSetting -Market $marketName -BemPct "-4"
    } else {
        Set-GSMGSetting -Market $marketName -BemPct "0"
    }
}
