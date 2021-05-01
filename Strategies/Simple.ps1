$GSMGmarkets = Get-GSMGMarkets
$Settings = @{}

foreach ($market in $global:MarketsToScan) {
    $marketName = $market
    [float] $pctChangeFromATH = Get-AthChangePct -Market $marketName -Interval "1d" -CandleLimit 50 -IncludeCurrentCandle
    [float] $pctChange24h = (Get-24hTicker($marketName)).priceChangePercent
    $market = $GSMGmarkets | Where-Object { $_.market_name -eq $marketName }
    $bagPct = [float] $market.vol_sells_worth / ([float] $market.managed_value_usd / 100)

    if ([Double]::IsNaN($bagPct)) {
        $bagPct = 0
    }

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
        # This works in a bull market, if we're not in a bull market then we should disable this elseif statement
        <#
        elseif ($pctChangeFromATH -le -10) {
            $bemPct = "0"
            $shouldAllocate = $true
        } 
        #>
    }

    $Settings += @{$marketName = @($bemPct, $aggressivenessPct, $shouldAllocate, $market.base_currency, $marketName)}
}

# { BUSD = 8,
#   BTC = 1
# }
$allocationCount = @{}
foreach ($setting in $settings.GetEnumerator()) {
    $shouldAllocate = $Setting.Value[2];
    $baseCurrency = $Setting.Value[3];

    if (-not $allocationCount.ContainsKey($baseCurrency)) {
        $allocationCount.Add($baseCurrency, 0);
    }

    if ($shouldAllocate) {
        $allocationCount[$baseCurrency]++;
    }
}

$marketsToDisable = $settings.Values | Where-Object { -not $_[2] }
foreach ($setting in $marketsToDisable) {
    $marketName = $setting[4]
    $curMarket = $GSMGmarkets | Where-Object {$_.market_name -eq $marketName}

    if ($curMarket.quantity_reserved -lt 1) {
        Set-GMSGMarketStatus -Market $marketName -Enabled $False
    }

    if ($curMarket.allocation -ne 0) {
        Set-GMSGMarketAllocation -Market $marketName -AllocationPct 0
    }
}

$marketsToEnable = $settings.Values | Where-Object { $_[2] } | Select-Object -First $global:MaxMarketCount
foreach ($setting in $marketsToEnable) {
    $marketName = $setting[4]
    $curMarket = $GSMGmarkets | Where-Object { $_.market_name -eq $marketName }
    $newBem = $Setting[0]
    $newAgg = $Setting[1]
    $shouldAlloc = $Setting[2]
    $baseCurrency = $curMarket.base_currency
   
    if ($shouldAlloc) {
        $allocPct = [Math]::Floor(100 / $allocationCount[$baseCurrency])
    } else {
        $allocPct = 0
    }

    <#
    if ($allocPct -gt $global:MaxAllocationPct -and $baseCurrency -eq "BUSD") {
        $allocPct = $global:MaxAllocationPct
    }
    #>

    # Reduce spam by checking if we're actually changing anything to what the server has
    if ($curMarket.allocation -ne $allocPct) {
        Set-GMSGMarketAllocation -Market $marketName -AllocationPct $allocPct
    }

    if ($curMarket.bem_pct -ne $newBem -or $curMarket.aggressiveness_pct -ne $newAgg) {
        Set-GSMGSetting -Market $marketName -BemPct $newBem -AggressivenessPct $newAgg
    }

    if ($shouldAlloc) {
        Set-GMSGMarketStatus -Market $marketName -Enable $True
    } 
}
