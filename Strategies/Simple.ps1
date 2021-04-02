$markets = Get-GSMGMarkets
foreach ($market in $markets) {
    $marketName = $market.market_name.Replace("Binance:", "")
    $market24hInformation = Query-24hTicker($marketName)
    $24hPriceChange = [float] $market24hInformation.priceChangePercent
    $bagPct = [float] $market.vol_sells_worth / ([float] $market.managed_value_usd / 100)

    $bemPct = "0"
    if ($bagPct -le 60 -and $24hPriceChange -le -2) {
        $bemPct = "2"
    } elseif ($24hPriceChange -le -8) {
        $bemPct = "5"
    } elseif ($24hPriceChange -le -12) {
        $bemPct = "8"
    }
    Set-GSMGSetting -Market $marketName -BemPct $bemPct
}
