$markets = Get-GSMGMarkets
$Settings = @{}

foreach ($market in $markets) {
    $marketName = $market.name.Replace("Binance:", "")
    [float] $pctChangeFromATH = Get-AthChangePct -Market $marketName -Interval "1d" -CandleLimit 1000
    [float] $pctChange24h = (Get-24hTicker($marketName)).priceChangePercent
    $bagPct = [float] $market.vol_sells_worth / ([float] $market.managed_value_usd / 100)

    $bemPct = "-15"
    $aggressivenessPct = "10"
    $shouldAllocate = $false

    # Market is reversing after a downtrend??
    if ($pctChange24h -gt -10)
    {
        if ($pctChangeFromATH -le -30) {
            $bemPct = "4"
            $shouldAllocate = $true
        }
        elseif ($pctChangeFromATH -le -20) {
            $bemPct = "2"
            $shouldAllocate = $true
        } 
    }

    $Settings += @{$marketName = @($bemPct, $aggressivenessPct, $shouldAllocate)}
}

$allocationCount = 0
foreach ($setting in $settings.GetEnumerator()) {
    if ($Setting.Value[2]) {
        $allocationCount++
    }
}

foreach ($setting in $settings.GetEnumerator()) {
    if ($Setting.Value[2]) {
        # Set allocation = 100 / $allocationCount
        $allocPct = [Math]::Floor(100 / $allocationCount)
    } else {
        # Set allocation = 0
        $allocPct = 0
    }

    Set-GMSGMarketAllocation -Market $Setting.Key -AllocationPct $allocPct
    Set-GSMGSetting -Market $Setting.Key -BemPct $Setting.Value[0] -AggressivenessPct $Setting.Value[1]
}
