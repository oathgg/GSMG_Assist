$GSMGmarkets = Get-GSMGMarkets
$GSMGAllocations = Get-GSMGMarketAllocations
$Settings = @{}

foreach ($market in $global:MarketsToScan) {
    $marketName = $market
    [float] $pctChangeFromATH = Get-AthChangePct -Market $marketName -Interval "1h" -CandleLimit 960 -IncludeCurrentCandle
    [float] $pctChange24h = (Get-24hTicker($marketName)).priceChangePercent
    $market = $GSMGmarkets | Where-Object { $_.market_name -eq $marketName }
    $allocation = $GSMGAllocations | Where-Object { $_.market_name -match $marketName }
    $bagPct = [float] $allocation.vol_sells_worth / ([float] $allocation.managed_value_usd / 100)

    if ([Double]::IsNaN($bagPct)) {
        $bagPct = 0
    }

    $bemPct = "-15"
    $aggressivenessPct = "10"
    $shouldAllocate = $false

    # Market is reversing after a downtrend??
    if ($pctChange24h -gt -5)
    {
        if ($pctChangeFromATH -le -40 -and $bagPct -lt 60) {
            $bemPct = "2"
            $shouldAllocate = $true
        }
        # 20 is defensive, 15 is normal, 10 is quite aggressive and you might be buying with a sell price above the ATH
        elseif ($pctChangeFromATH -le -20) {
            # This might be too aggressive, we should verify if this setting is good or not.
            # Default behaviour would have been bempct = 0, however, We noticed that we run out of bags quite early...
            # We either increase the minprofit or we increase the BEM so we buy more often
            
            #if ($bagPct -lt 20) {
                #$bemPct = "2"
            #}
            #else {
                $bemPct = "0"
            #}

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

    if ($shouldAllocate) {
        Write-Host "[$marketName] -> BEM: $bemPct, AGGR: $aggressivenessPct, MPROFIT: $global:MinProfitPct"
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

$forcedActiveMarketsCount = @{}
$marketsToDisable = $settings.Values | Where-Object { -not $_[2] }
foreach ($setting in $marketsToDisable) {
    $marketName = $setting[4]
    $baseCurrency = $setting[3]
    $curMarket = $GSMGmarkets | Where-Object { $_.market_name -eq $marketName }
    $allocationActive = $GSMGAllocations | ? { $_.market_name -match $marketName }

    if (-not $forcedActiveMarketsCount.ContainsKey($baseCurrency)) {
        $forcedActiveMarketsCount.Add($baseCurrency, 0);
    }

    # The amount of money we still have open in the coin
    if (-not $allocationActive -or ($allocationActive -and $allocationActive.managed_value_usd -lt 1)) {
        Set-GMSGMarketStatus -Market $marketName -Enabled $False
    } else {
        $forcedActiveMarketsCount[$baseCurrency]++
    }

    # Make sure we dont have any allocation left when we disable the market
    # We set it to 0 in case we do have some of our bag left, this way we "leave" the market but sell orders remain open.
    if ($curMarket.allocation -ne $null -and $curMarket.allocation -ne 0) {
        Set-GMSGMarketAllocation -Market $marketName -AllocationPct 0
    }
}

$marketsToEnable = $null
$availableMarketSlots = $global:MaxMarketCount
foreach ($baseCurrency in $forcedActiveMarketsCount.Keys) {
    $availableMarketSlots -= $forcedActiveMarketsCount[$baseCurrency]

    $marketsToAdd = $settings.Values | Where-Object { $_[2] -and $_[3] -eq $baseCurrency } | Select-Object -First $availableMarketSlots
    $marketsToEnable += $marketsToAdd

    $availableMarketSlots -= $marketsToAdd.Count
}

foreach ($setting in $marketsToEnable) {
    $marketName = $setting[4]
    $curMarket = $GSMGmarkets | Where-Object { $_.market_name -eq $marketName }
    $newBem = $Setting[0]
    $newAgg = $Setting[1]
    $shouldAlloc = $Setting[2]
    $baseCurrency = $curMarket.base_currency
    $allocationActive = $GSMGAllocations | ? { $_.market_name -match $marketName }
   
    if ($shouldAlloc) {
        $allocPct = [Math]::Floor(100 / $allocationCount[$baseCurrency])
    } else {
        $allocPct = 0
    }

    if ($allocPct -gt $global:MaxAllocationPct[$baseCurrency]) {
        $allocPct = $global:MaxAllocationPct[$baseCurrency]
    }

    if ($shouldAlloc -and -not $allocationActive) {
        Set-GMSGMarketStatus -Market $marketName -Enable $True
    }

    # Reduce spam by checking if we're actually changing anything to what the server has
    if ($curMarket.allocation -ne $allocPct) {
        Set-GMSGMarketAllocation -Market $marketName -AllocationPct $allocPct
    }

    if ($curMarket.bem_pct -ne $newBem -or $curMarket.aggressiveness_pct -ne $newAgg -or $curMarket.min_trade_profit_pct -ne $global:MinProfitPct) {
        Set-GSMGSetting -Market $marketName -BemPct $newBem -AggressivenessPct $newAgg -MinTradeProfitPct $global:MinProfitPct
    }
}
