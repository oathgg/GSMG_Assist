function New-ConfigurationObject($BemPct, $AggressivenessPct, $ShouldAllocate, $BaseCurrency, $MarketName, $MinProfitPct, $TrailingBuy) {
    $Settings = New-Object PSObject -Property @{ 
        MarketName=$MarketName
        BemPCT=$BemPct
        AggressivenessPct=$AggressivenessPct
        ShouldAllocate=$ShouldAllocate
        BaseCurrency=$BaseCurrency 
        MinProfitPct=$MinProfitPct
        TrailingBuy=$TrailingBuy
    }
    return $Settings
}

function Run-ConfigureGSMG($Settings) {
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
    $marketsToDisable = @()
    foreach ($activeAllocation in $Global:GSMGAllocations) {
        $activeMarketName = $activeAllocation.Market_Name.Replace("Binance:", "")
        $settingsMarket = $settings | Where-Object { $_.MarketName -eq $activeMarketName }
        if (-not $settingsMarket.ShouldAllocate) {
            $marketsToDisable += $activeMarketName
        }
    }

    $forcedActiveMarketsCount = @{}
    foreach ($marketName in $marketsToDisable) {
        $curMarket = $Global:GSMGmarkets | Where-Object { $_.market_name -eq $marketName }
        $allocationActive = $Global:GSMGAllocations | Where-Object { $_.market_name -match $marketName }
        $baseCurrency = $curMarket.base_currency

        if (-not $forcedActiveMarketsCount.ContainsKey($baseCurrency)) {
            $forcedActiveMarketsCount.Add($baseCurrency, 0);
        }

        # The amount of money we still have open in the coin
        if (-not $allocationActive -or ($allocationActive -and $allocationActive.managed_value_usd -lt 1)) {
            Set-GMSGMarketStatus -Market $marketName -Enabled $False
        } 
        # We cannot disable this market because there is still too much money in it
        else {
            $defaultSettings = $Settings | Where-Object { $_.MarketName -eq "DEFAULT" }
            $newBem = $defaultSettings.BemPCT
            $newAgg = $defaultSettings.AggressivenessPct
            $minProfitPct = $defaultSettings.MinProfitPct
            $trailingBuy = $defaultSettings.TrailingBuy
            Set-GSMGSetting -Market $marketName -BemPct $newBem -AggressivenessPct $newAgg -MinTradeProfitPct $minProfitPct -TrailingBuy $trailingBuy
            $forcedActiveMarketsCount[$baseCurrency]++

            Write-Warning "[$marketname] Cannot disable market, managed value : $($allocationActive.managed_value_usd)"
        }

        # Make sure we dont have any allocation left when we disable the market
        # We set it to 0 in case we do have some of our bag left, this way we "leave" the market but sell orders remain open.
        if ($null -ne $curMarket.allocation -and $curMarket.allocation -ne 0) {
            Set-GMSGMarketAllocation -Market $marketName -AllocationPct 0
        }
    }

    # Calculates the amount of markets we want to enable so we don't cross the max market count
    $marketsToEnable = @()
    $availableMarketSlots = (Get-GSMGSubscription).max_markets_across_exchanges
    foreach ($baseCurrency in $global:MaxAllocationPct.Keys) {
        $availableMarketSlots -= $forcedActiveMarketsCount[$baseCurrency]

        $marketsToAdd = $settings | Where-Object { $_.ShouldAllocate -and $_.BaseCurrency -eq $baseCurrency } | Select-Object -First $availableMarketSlots
        $marketsToEnable += $marketsToAdd

        $availableMarketSlots -= $marketsToAdd.Count
    }

    # Enable the markets we want to enable and set the predefined settings for that particular market.
    foreach ($setting in $marketsToEnable) {
        $marketName = $setting.MarketName
        $curMarket = $Global:GSMGmarkets | Where-Object { $_.market_name -eq $marketName }
        $allocationActive = $Global:GSMGAllocations | Where-Object { $_.market_name -match $marketName }
        
        $newBem = $Setting.BemPCT
        $newAgg = $Setting.AggressivenessPct
        $shouldAlloc = $Setting.ShouldAllocate
        $minProfitPct = $setting.MinProfitPct
        $baseCurrency = $setting.BaseCurrency
        $trailingBuy = $setting.TrailingBuy
   
        if ($shouldAlloc) {
            $allocPct = [Math]::Floor(100 / $allocationCount[$baseCurrency])
        } else {
            $allocPct = 0
        }

        if ($allocPct -gt $global:MaxAllocationPct[$baseCurrency]) {
            $allocPct = $global:MaxAllocationPct[$baseCurrency]
        }

        if ($shouldAlloc -and (-not $allocationActive -or $allocationActive.current_alloc -ne $allocPct)) {
            Set-GMSGMarketStatus -Market $marketName -Enable $True
        }

        # Reduce spam by checking if we're actually changing anything to what the server has
        if ($curMarket.allocation -ne $allocPct) {
            Set-GMSGMarketAllocation -Market $marketName -AllocationPct $allocPct
        }

        #if ($curMarket.bem_pct -ne $newBem -or $curMarket.aggressiveness_pct -ne $newAgg -or $curMarket.min_trade_profit_pct -ne $minProfitPct) {
            Set-GSMGSetting -Market $marketName -BemPct $newBem -AggressivenessPct $newAgg -MinTradeProfitPct $minProfitPct -TrailingBuy $trailingBuy
        #}
    }
}