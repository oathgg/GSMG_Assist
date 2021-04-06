$markets = Get-GSMGMarkets
foreach ($market in $markets) {
    $marketName = $market.market_name.Replace("Binance:", "")
    [float] $24hPriceChange = (Get-24hTicker($marketName)).priceChangePercent
    $bagPct = [float] $market.vol_sells_worth / ([float] $market.managed_value_usd / 100)

    $bemPct = "0"
    $aggressivenessPct = "20"

    if ($24hPriceChange -le -15) {
        $bemPct = "8"
        $aggressivenessPct = "30"
    } 
    elseif ($24hPriceChange -le -12) {
        $bemPct = "6"
        $aggressivenessPct = "25"
    } 
    elseif ($24hPriceChange -le -8) {
        $bemPct = "4"
    } 
    elseif ($bagPct -le 30 -and $24hPriceChange -le -4) {
        $bemPct = "2"
    }

    Set-GSMGSetting -Market $marketName -BemPct $bemPct -AggressivenessPct $aggressivenessPct
}
