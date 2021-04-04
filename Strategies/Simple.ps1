$markets = Get-GSMGMarkets
foreach ($market in $markets) {
    $marketName = $market.market_name.Replace("Binance:", "")
    [float] $24hPriceChange = (Query-24hTicker($marketName)).priceChangePercent
    $bagPct = [float] $market.vol_sells_worth / ([float] $market.managed_value_usd / 100)

    $bemPct = "-2"
    $aggressivenessPct = "20"

    if ($24hPriceChange -le -15) {
        $bemPct = "6"
        $aggressivenessPct = "30"
    } 
    elseif ($24hPriceChange -le -12) {
        $bemPct = "4"
        $aggressivenessPct = "25"
    } 
    elseif ($24hPriceChange -le -8) {
        $bemPct = "2"
    } 
    elseif ($24hPriceChange -le -4) {
        $bemPct = "0"
    }

    Set-GSMGSetting -Market $marketName -BemPct $bemPct -AggressivenessPct $aggressivenessPct
}
