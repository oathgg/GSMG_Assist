﻿function Run-ConfigureGSMG($Settings) {
    # Defines how many allocations we need for the specified market
    # { 
    #     BUSD = 8,
    #     BTC = 1
    # }
    $allocationCount = @{}
    foreach ($setting in $settings) {
        $shouldAllocate = $Setting.ShouldAllocate
        $baseCurrency = $Setting.BaseCurrency;

        if (-not $allocationCount.ContainsKey($baseCurrency)) {
            $allocationCount.Add($baseCurrency, 0);
        }

        if ($shouldAllocate) {
            $allocationCount[$baseCurrency]++;
        }
    }

    # Enables and disables markets which are no longer applicable.
    # We keep track of the amount of markets which we want to disable but we cant,
    # A reason why we can't would be because we still have open sell orders.
    $forcedActiveMarketsCount = @{}
    $marketsToDisable = $settings | Where-Object { -not $_.ShouldAllocate }
    foreach ($setting in $marketsToDisable) {
        $marketName = $setting.MarketName
        $baseCurrency = $setting.BaseCurrency

        $curMarket = $GSMGmarkets | Where-Object { $_.market_name -eq $marketName }
        $allocationActive = $GSMGAllocations | ? { $_.market_name -match $marketName }

        if (-not $forcedActiveMarketsCount.ContainsKey($baseCurrency)) {
            $forcedActiveMarketsCount.Add($baseCurrency, 0);
        }

        # The amount of money we still have open in the coin
        if (-not $allocationActive -or ($allocationActive -and $allocationActive.managed_value_usd -lt 1)) {
            Set-GMSGMarketStatus -Market $marketName -Enabled $False
        } else {
            $newBem = $Setting.BemPCT
            $newAgg = $Setting.AggressivenessPct
            $minProfitPct = $setting.MinProfitPct
            Set-GSMGSetting -Market $marketName -BemPct $newBem -AggressivenessPct $newAgg -MinTradeProfitPct $minProfitPct
            $forcedActiveMarketsCount[$baseCurrency]++
        }

        # Make sure we dont have any allocation left when we disable the market
        # We set it to 0 in case we do have some of our bag left, this way we "leave" the market but sell orders remain open.
        if ($curMarket.allocation -ne $null -and $curMarket.allocation -ne 0) {
            Set-GMSGMarketAllocation -Market $marketName -AllocationPct 0
        }
    }

    # Calculates the amount of markets we want to enable so we don't cross the max market count
    $marketsToEnable = $null
    $availableMarketSlots = (Get-GSMGSubscription).max_markets_across_exchanges
    foreach ($baseCurrency in $forcedActiveMarketsCount.Keys) {
        $availableMarketSlots -= $forcedActiveMarketsCount[$baseCurrency]

        $marketsToAdd = $settings | Where-Object { $_.ShouldAllocate -and $_.BaseCurrency -eq $baseCurrency } | Select-Object -First $availableMarketSlots
        $marketsToEnable += $marketsToAdd

        $availableMarketSlots -= $marketsToAdd.Count
    }

    # Enable the markets we want to enable and set the predefined settings for that particular market.
    foreach ($setting in $marketsToEnable) {
        $marketName = $setting.MarketName
        $curMarket = $GSMGmarkets | Where-Object { $_.market_name -eq $marketName }
        $newBem = $Setting.BemPCT
        $newAgg = $Setting.AggressivenessPct
        $shouldAlloc = $Setting.ShouldAllocate
        $minProfitPct = $setting.MinProfitPct
        $baseCurrency = $setting.BaseCurrency
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

        if ($curMarket.bem_pct -ne $newBem -or $curMarket.aggressiveness_pct -ne $newAgg -or $curMarket.min_trade_profit_pct -ne $minProfitPct) {
            Set-GSMGSetting -Market $marketName -BemPct $newBem -AggressivenessPct $newAgg -MinTradeProfitPct $minProfitPct
        }
    }
}