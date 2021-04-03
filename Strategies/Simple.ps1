$markets = Get-GSMGMarkets
foreach ($market in $markets) {
    $marketName = $market.market_name.Replace("Binance:", "")
    $market24hInformation = Query-24hTicker($marketName)
    $24hPriceChange = [float] $market24hInformation.priceChangePercent
    $bagPct = [float] $market.vol_sells_worth / ([float] $market.managed_value_usd / 100)

    $bemPct = "0"
    $aggressivenessPct = "15"
    
    if ($24hPriceChange -le -12) {
        $bemPct = "6"
        $aggressivenessPct = "50"
    } 
    elseif ($24hPriceChange -le -8) {
        $bemPct = "4"
        $aggressivenessPct = "25"
    } 
    elseif ($bagPct -le 40 -and $24hPriceChange -le -2) {
        $bemPct = "2"
    }
    Set-GSMGSetting -Market $marketName -BemPct $bemPct -AggressivenessPct $aggressivenessPct
}
