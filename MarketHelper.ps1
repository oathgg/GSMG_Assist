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
    $lockedAllocations = Get-GSMGMarketAllocations | Where-Object { $_.set_alloc_perc -eq 0 -and $_.open_sells_alloc_perc -gt 0 }

    foreach ($setting in $Settings) {
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
            $marketCountToAllocate = @($Settings | Where-Object { $_.basecurrency -eq $baseCurrency -and $_.ShouldAllocate }).Count

            # Enable the markets we want to enable and set the predefined settings for that particular market.
            $totalAllocation = 100
            $lockedAllocation = ($lockedAllocations | Where-Object { $_.base_currency -eq $baseCurrency } | Measure-Object -Sum open_sells_alloc_perc).Sum
            $freeAlloc = $totalAllocation - $lockedAllocation

            $allocPct = [Math]::Floor($freeAlloc / $marketCountToAllocate)
        } else {
            $allocPct = 0
        }

        if ($null -ne $global:MaxAllocationPct[$baseCurrency] -and $allocPct -gt $global:MaxAllocationPct[$baseCurrency]) {
            $allocPct = $global:MaxAllocationPct[$baseCurrency]
        }

        Set-GMSGMarketAllocation -Market $marketName -AllocationPct $allocPct
        Set-GSMGSetting -Market $marketName -BemPct $newBem -AggressivenessPct $newAgg -MinTradeProfitPct $minProfitPct -TrailingBuy $trailingBuy
    }
}