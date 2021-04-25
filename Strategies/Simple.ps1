$markets = Get-GSMGMarkets
foreach ($market in $markets) {
    $marketName = $market.market_name.Replace("Binance:", "")
    [float] $pctChangeFromATH = Get-AthChangePct -Market $marketName -Interval "1d" -CandleLimit 1000
    $bagPct = [float] $market.vol_sells_worth / ([float] $market.managed_value_usd / 100)

    $bemPct = "-15"
    $aggressivenessPct = "10"

    if ($pctChangeFromATH -le -40) {
        if ($bagPct -lt 60) {
            $bemPct = "2"
        } else {
            $bemPct = "0"
        }
        $aggressivenessPct = "30"
    } 
    elseif ($pctChangeFromATH -le -25) {
        $bemPct = "0"
        $aggressivenessPct = "20"
    } 

    #Write-Host "[$Marketname] $pctChangeFromAth, $bemPct, $aggressivenessPct"
    Set-GSMGSetting -Market $marketName -BemPct $bemPct -AggressivenessPct $aggressivenessPct
}
