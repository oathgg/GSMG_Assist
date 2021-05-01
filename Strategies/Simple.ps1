$markets = Get-GSMGMarkets
$Settings = @{}

foreach ($market in $markets) {
    $marketName = $market.name.Replace("Binance:", "")
    [float] $pctChangeFromATH = Get-AthChangePct -Market $marketName -Interval "1d" -CandleLimit 1000 -IncludeCurrentCandle
    [float] $pctChange24h = (Get-24hTicker($marketName)).priceChangePercent
    $bagPct = [float] $market.vol_sells_worth / ([float] $market.managed_value_usd / 100)

    $bemPct = "-15"
    $aggressivenessPct = "10"
    $shouldAllocate = $false

    # Market is reversing after a downtrend??
    if ($pctChange24h -gt -10)
    {
        if ($pctChangeFromATH -le -40 -and $bagPct -lt 60) {
            $bemPct = "2"
            $shouldAllocate = $true
        }
        elseif ($pctChangeFromATH -le -20) {
            $bemPct = "0"
            $shouldAllocate = $true
        } 
        elseif ($pctChangeFromATH -le -10) {
            $bemPct = "-2"
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
    $curMarket = $markets | Where-Object {$_.market_name -eq $setting.key}
    $newBem = $Setting.Value[0]
    $newAgg = $Setting.Value[1]
    $shouldAlloc = $Setting.Value[2]
   
    if ($shouldAlloc) {
        $allocPct = [Math]::Floor(100 / $allocationCount)
    } else {
        $allocPct = 0
    }

    if ($allocPct -gt $global:MaxAllocationPct) {
        $allocPct = $global:MaxAllocationPct
    }

    # Reduce spam by checking if we're actually changing anything to what the server has
    if ($curMarket.allocation -ne $allocPct) {
        Set-GMSGMarketAllocation -Market $Setting.Key -AllocationPct $allocPct
    }

    if ($curMarket.bem_pct -ne $newBem -or $curMarket.aggressiveness_pct -ne $newAgg) {
        Set-GSMGSetting -Market $Setting.Key -BemPct $Setting.Value[0] -AggressivenessPct $Setting.Value[1]
    }
}
